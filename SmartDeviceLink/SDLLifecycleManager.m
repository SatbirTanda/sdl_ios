//
//  SDLLifecycleManager.m
//  SmartDeviceLink-iOS
//
//  Created by Joel Fischer on 7/19/16.
//  Copyright © 2016 smartdevicelink. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "SDLLifecycleManager.h"

#import "NSMapTable+Subscripting.h"
#import "SDLConfiguration.h"
#import "SDLConnectionManagerType.h"
#import "SDLDebugTool.h"
#import "SDLError.h"
#import "SDLFile.h"
#import "SDLFileManager.h"
#import "SDLLifecycleConfiguration.h"
#import "SDLLockScreenConfiguration.h"
#import "SDLLockScreenManager.h"
#import "SDLLockScreenPresenter.h"
#import "SDLManagerDelegate.h"
#import "SDLNotificationDispatcher.h"
#import "SDLOnAppInterfaceUnregistered.h"
#import "SDLOnHMIStatus.h"
#import "SDLOnHashChange.h"
#import "SDLPermissionManager.h"
#import "SDLProxy.h"
#import "SDLProxyFactory.h"
#import "SDLRPCRequestFactory.h"
#import "SDLRegisterAppInterface.h"
#import "SDLRegisterAppInterfaceResponse.h"
#import "SDLResponseDispatcher.h"
#import "SDLResult.h"
#import "SDLSetAppIcon.h"
#import "SDLStateMachine.h"
#import "SDLUnregisterAppInterface.h"


NS_ASSUME_NONNULL_BEGIN

#pragma mark - Private Typedefs and Constants

typedef NSString SDLLifecycleState;
SDLLifecycleState *const SDLLifecycleStateDisconnected = @"TransportDisconnected";
SDLLifecycleState *const SDLLifecycleStateTransportConnected = @"TransportConnected";
SDLLifecycleState *const SDLLifecycleStateRegistered = @"Registered";
SDLLifecycleState *const SDLLifecycleStateSettingUpManagers = @"SettingUpManagers";
SDLLifecycleState *const SDLLifecycleStatePostManagerProcessing = @"PostManagerProcessing";
SDLLifecycleState *const SDLLifecycleStateUnregistering = @"Unregistering";
SDLLifecycleState *const SDLLifecycleStateReady = @"Ready";


#pragma mark - SDLManager Private Interface

@interface SDLLifecycleManager () <SDLConnectionManagerType>

// Readonly public properties
@property (copy, nonatomic, readwrite, nullable) SDLHMILevel *hmiLevel;
@property (copy, nonatomic, readwrite) SDLConfiguration *configuration;
@property (assign, nonatomic, readwrite) UInt16 lastCorrelationId;
@property (strong, nonatomic, readwrite, nullable) SDLRegisterAppInterfaceResponse *registerAppInterfaceResponse;
@property (strong, nonatomic, readwrite) SDLNotificationDispatcher *notificationDispatcher;
@property (strong, nonatomic, readwrite) SDLResponseDispatcher *responseDispatcher;
@property (strong, nonatomic, readwrite) SDLStateMachine *lifecycleStateMachine;

// Deprecated internal proxy object
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
@property (strong, nonatomic, readwrite, nullable) SDLProxy *proxy;
#pragma clang diagnostic pop

// Private properties
@property (copy, nonatomic) SDLManagerReadyBlock readyBlock;

@end


@implementation SDLLifecycleManager

#pragma mark Lifecycle

- (instancetype)init {
    return [self initWithConfiguration:[SDLConfiguration configurationWithLifecycle:[SDLLifecycleConfiguration defaultConfigurationWithAppName:@"SDL APP" appId:@"001"] lockScreen:[SDLLockScreenConfiguration disabledConfiguration]] delegate:nil];
}

- (instancetype)initWithConfiguration:(SDLConfiguration *)configuration delegate:(nullable id<SDLManagerDelegate>)delegate {
    self = [super init];
    if (!self) {
        return nil;
    }

    // Dependencies
    _configuration = configuration;
    _delegate = delegate;

    // Private properties
    _lifecycleStateMachine = [[SDLStateMachine alloc] initWithTarget:self initialState:SDLLifecycleStateDisconnected states:[self.class sdl_stateTransitionDictionary]];
    _lastCorrelationId = 0;
    _notificationDispatcher = [[SDLNotificationDispatcher alloc] init];
    _responseDispatcher = [[SDLResponseDispatcher alloc] initWithNotificationDispatcher:_notificationDispatcher];
    _registerAppInterfaceResponse = nil;

    // Managers
    _fileManager = [[SDLFileManager alloc] initWithConnectionManager:self];
    _permissionManager = [[SDLPermissionManager alloc] init];
    _lockScreenManager = [[SDLLockScreenManager alloc] initWithConfiguration:_configuration.lockScreenConfig notificationDispatcher:_notificationDispatcher presenter:[[SDLLockScreenPresenter alloc] init]];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(transportDidConnect) name:SDLTransportDidConnect object:_notificationDispatcher];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(transportDidDisconnect) name:SDLTransportDidDisconnect object:_notificationDispatcher];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(hmiStatusDidChange:) name:SDLDidChangeHMIStatusNotification object:_notificationDispatcher];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(remoteHardwareDidUnregister:) name:SDLDidReceiveAppUnregisteredNotification object:_notificationDispatcher];

    return self;
}

- (void)startWithHandler:(SDLManagerReadyBlock)readyBlock {
    self.readyBlock = [readyBlock copy];
    
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    [SDLProxy enableSiphonDebug];

    if (self.configuration.lifecycleConfig.tcpDebugMode) {
        self.proxy = [SDLProxyFactory buildSDLProxyWithListener:self.notificationDispatcher tcpIPAddress:self.configuration.lifecycleConfig.tcpDebugIPAddress tcpPort:self.configuration.lifecycleConfig.tcpDebugPort];
    } else {
        self.proxy = [SDLProxyFactory buildSDLProxyWithListener:self.notificationDispatcher];
    }
#pragma clang diagnostic pop
}

- (void)stop {
    if ([self.lifecycleStateMachine isCurrentState:SDLLifecycleStateReady]) {
        [self.lifecycleStateMachine transitionToState:SDLLifecycleStateUnregistering];
    } else {
        [self.lifecycleStateMachine transitionToState:SDLLifecycleStateDisconnected];
    }
}

- (void)applicationWillTerminate {
    [self.lifecycleStateMachine transitionToState:SDLLifecycleStateUnregistering];
}


#pragma mark Getters

- (nullable SDLStreamingMediaManager *)streamManager {
    return self.proxy.streamingMediaManager;
}

- (SDLState *)lifecycleState {
    return self.lifecycleStateMachine.currentState;
}

- (NSString *)stateTransitionNotificationName {
    return self.lifecycleStateMachine.transitionNotificationName;
}


#pragma mark State Machine

+ (NSDictionary<SDLState *, SDLAllowableStateTransitions *> *)sdl_stateTransitionDictionary {
    return @{
        SDLLifecycleStateDisconnected : @[ SDLLifecycleStateTransportConnected ],
        SDLLifecycleStateTransportConnected : @[ SDLLifecycleStateDisconnected, SDLLifecycleStateRegistered ],
        SDLLifecycleStateRegistered : @[ SDLLifecycleStateDisconnected, SDLLifecycleStateSettingUpManagers ],
        SDLLifecycleStateSettingUpManagers : @[ SDLLifecycleStateDisconnected, SDLLifecycleStatePostManagerProcessing ],
        SDLLifecycleStatePostManagerProcessing : @[ SDLLifecycleStateDisconnected, SDLLifecycleStateReady ],
        SDLLifecycleStateUnregistering : @[ SDLLifecycleStateDisconnected ],
        SDLLifecycleStateReady : @[ SDLLifecycleStateUnregistering, SDLLifecycleStateDisconnected ]
    };
}

- (void)didEnterStateTransportDisconnected {
    [self.fileManager stop];
    [self.permissionManager stop];
    [self.lockScreenManager stop];
    [self.responseDispatcher clear];

    self.registerAppInterfaceResponse = nil;
    self.lastCorrelationId = 0;
    self.hmiLevel = nil;

    [self sdl_disposeProxy]; // call this method instead of stopProxy to avoid double-dispatching
    [self.delegate managerDidDisconnect];

    [self startWithHandler:self.readyBlock]; // Start up again to start watching for new connections
}

- (void)didEnterStateTransportConnected {
    // Build a register app interface request with the configuration data
    SDLRegisterAppInterface *regRequest = [SDLRPCRequestFactory buildRegisterAppInterfaceWithAppName:self.configuration.lifecycleConfig.appName languageDesired:self.configuration.lifecycleConfig.language appID:self.configuration.lifecycleConfig.appId];
    regRequest.isMediaApplication = @(self.configuration.lifecycleConfig.isMedia);
    regRequest.ngnMediaScreenAppName = self.configuration.lifecycleConfig.shortAppName;

    if (self.configuration.lifecycleConfig.voiceRecognitionCommandNames != nil) {
        regRequest.vrSynonyms = [NSMutableArray arrayWithArray:self.configuration.lifecycleConfig.voiceRecognitionCommandNames];
    }

    // Send the request and depending on the response, post the notification
    __weak typeof(self) weakSelf = self;
    [self sdl_sendRequest:regRequest
        withCompletionHandler:^(__kindof SDLRPCRequest *_Nullable request, __kindof SDLRPCResponse *_Nullable response, NSError *_Nullable error) {
            if (error != nil || ![response.success boolValue]) {
                [SDLDebugTool logFormat:@"Failed to register the app. Error: %@, Response: %@", error, response];
                [weakSelf.lifecycleStateMachine transitionToState:SDLLifecycleStateDisconnected];
            }

            weakSelf.registerAppInterfaceResponse = (SDLRegisterAppInterfaceResponse *)response;
            [weakSelf.lifecycleStateMachine transitionToState:SDLLifecycleStateRegistered];
        }];
}

- (void)didEnterStateRegistered {
    [self.lifecycleStateMachine transitionToState:SDLLifecycleStateSettingUpManagers];
}

- (void)didEnterStateSettingUpManagers {
    __block BOOL setupSuccess = YES;
    dispatch_group_t managerGroup = dispatch_group_create();

    // Make sure there's at least one group_enter until we have synchronously run through all the startup calls
    dispatch_group_enter(managerGroup);

    [self.lockScreenManager start];

    dispatch_group_enter(managerGroup);
    [self.fileManager startWithCompletionHandler:^(BOOL success, NSError *_Nullable error) {
        if (!success) {
            setupSuccess = NO;
            [SDLDebugTool logFormat:@"File manager was unable to start; error: %@", error];
        }

        dispatch_group_leave(managerGroup);
    }];

    dispatch_group_enter(managerGroup);
    [self.permissionManager startWithCompletionHandler:^(BOOL success, NSError *_Nullable error) {
        if (!success) {
            setupSuccess = NO;
            [SDLDebugTool logFormat:@"Permission manager was unable to start; error: %@", error];
        }

        dispatch_group_leave(managerGroup);
    }];

    // We're done synchronously calling all startup methods, so we can now wait.
    dispatch_group_leave(managerGroup);

    // When done, we want to transition
    dispatch_group_notify(managerGroup, dispatch_get_main_queue(), ^{
        if (setupSuccess) {
            [self.lifecycleStateMachine transitionToState:SDLLifecycleStatePostManagerProcessing];
        } else {
            self.readyBlock(NO, [NSError sdl_lifecycle_managersFailedToStart]);
            [self.lifecycleStateMachine transitionToState:SDLLifecycleStateUnregistering];
        }
    });
}

- (void)didEnterStatePostManagerProcessing {
    // We only want to send the app icon when the file manager is complete, and when that's done, set the state to ready
    [self sdl_sendAppIcon:self.configuration.lifecycleConfig.appIcon
           withCompletion:^{
               [self.lifecycleStateMachine transitionToState:SDLLifecycleStateReady];
           }];
}

- (void)didEnterStateReady {
    [self.notificationDispatcher postNotificationName:SDLDidBecomeReady infoObject:nil];
    
    SDLResult *registerResult = self.registerAppInterfaceResponse.resultCode;
    
    BOOL success = NO;
    NSError *startError = nil;
    
    if (![registerResult isEqualToEnum:[SDLResult SUCCESS]]) {
        // We did not succeed in registering
        startError = [NSError sdl_lifecycle_failedWithBadResult:registerResult];
    } else {
        // We succeeded in registering
        success = YES;
    }
    
    // Notify the block and delegate if it exists
    self.readyBlock(success, startError);
    if (self.delegate != nil && [self.delegate respondsToSelector:@selector(managerDidBecomeReady)]) {
        [self.delegate managerDidBecomeReady];
    }
}

- (void)didEnterStateUnregistering {
    SDLUnregisterAppInterface *unregisterRequest = [SDLRPCRequestFactory buildUnregisterAppInterfaceWithCorrelationID:[self sdl_getNextCorrelationId]];

    __weak typeof(self) weakSelf = self;
    [self sdl_sendRequest:unregisterRequest
        withCompletionHandler:^(__kindof SDLRPCRequest *_Nullable request, __kindof SDLRPCResponse *_Nullable response, NSError *_Nullable error) {
            if (error != nil || ![response.success boolValue]) {
                [SDLDebugTool logFormat:@"SDL Error unregistering, we are going to hard disconnect: %@, response: %@", error, response];
            }

            [weakSelf.lifecycleStateMachine transitionToState:SDLLifecycleStateDisconnected];
        }];
}


#pragma mark Post Manager Setup Processing

- (void)sdl_sendAppIcon:(nullable SDLFile *)appIcon withCompletion:(void (^)(void))completion {
    // If no app icon was set, just move on to ready
    if (appIcon == nil) {
        completion();
        return;
    }

    [self.fileManager uploadFile:appIcon
               completionHandler:^(BOOL success, NSUInteger bytesAvailable, NSError *_Nullable error) {
                   // These errors could be recoverable (particularly "cannot overwrite"), so we'll still attempt to set the app icon
                   if (error != nil) {
                       if (error.code == SDLFileManagerErrorCannotOverwrite) {
                           [SDLDebugTool logInfo:@"Failed to upload app icon: A file with this name already exists on the system"];
                       } else {
                           [SDLDebugTool logFormat:@"Unexpected error uploading app icon: %@", error];
                           return;
                       }
                   }

                   // Once we've tried to put the file on the remote system, try to set the app icon
                   SDLSetAppIcon *setAppIconRequest = [SDLRPCRequestFactory buildSetAppIconWithFileName:appIcon.name correlationID:@0];
                   [self sdl_sendRequest:setAppIconRequest
                       withCompletionHandler:^(__kindof SDLRPCRequest *_Nullable request, __kindof SDLRPCResponse *_Nullable response, NSError *_Nullable error) {
                           if (error != nil) {
                               [SDLDebugTool logFormat:@"Error setting app icon: ", error];
                           }

                           // We've succeeded or failed
                           completion();
                       }];
               }];
}


#pragma mark Sending Requests

- (void)sendRequest:(SDLRPCRequest *)request {
    [self sendRequest:request withCompletionHandler:nil];
}

- (void)sendRequest:(__kindof SDLRPCRequest *)request withCompletionHandler:(nullable SDLRequestCompletionHandler)handler {
    if (![self.lifecycleStateMachine isCurrentState:SDLLifecycleStateReady]) {
        [SDLDebugTool logInfo:@"Manager not ready, will not send RPC until state is Ready"];
        if (handler) {
            handler(request, nil, [NSError sdl_lifecycle_notReadyError]);
        }

        return;
    }

    [self sdl_sendRequest:request withCompletionHandler:handler];
}

// Managers need to avoid state checking. Part of <SDLConnectionManagerType>.
- (void)sendManagerRequest:(__kindof SDLRPCRequest *)request withCompletionHandler:(nullable SDLRequestCompletionHandler)block {
    [self sdl_sendRequest:request withCompletionHandler:block];
}

- (void)sdl_sendRequest:(SDLRPCRequest *)request withCompletionHandler:(nullable SDLRequestCompletionHandler)handler {
    // We will allow things to be sent in a "SDLLifeCycleStateTransportConnected" state in the private method, but block it in the public method sendRequest:withCompletionHandler: so that the lifecycle manager can complete its setup without being bothered by developer error

    // Add a correlation ID to the request
    NSNumber *corrID = [self sdl_getNextCorrelationId];
    request.correlationID = corrID;

    [self.responseDispatcher storeRequest:request handler:handler];
    [self.proxy sendRPC:request];
}


#pragma mark Helper Methods

- (void)sdl_disposeProxy {
    [SDLDebugTool logInfo:@"Stop Proxy"];
    [self.proxy dispose];
    self.proxy = nil;
}

- (NSNumber *)sdl_getNextCorrelationId {
    if (self.lastCorrelationId == UINT16_MAX) {
        self.lastCorrelationId = 0;
    }

    return @(++self.lastCorrelationId);
}


#pragma mark SDL notification observers

- (void)transportDidConnect {
    [self.lifecycleStateMachine transitionToState:SDLLifecycleStateTransportConnected];
}

- (void)transportDidDisconnect {
    [self.lifecycleStateMachine transitionToState:SDLLifecycleStateDisconnected];
}

- (void)hmiStatusDidChange:(NSNotification *)notification {
    NSAssert([notification.userInfo[SDLNotificationUserInfoObject] isKindOfClass:[SDLOnHMIStatus class]], @"A notification was sent with an unanticipated object");
    if (![notification.userInfo[SDLNotificationUserInfoObject] isKindOfClass:[SDLOnHMIStatus class]]) {
        return;
    }

    SDLOnHMIStatus *hmiStatusNotification = notification.userInfo[SDLNotificationUserInfoObject];
    SDLHMILevel *oldHMILevel = self.hmiLevel;
    self.hmiLevel = hmiStatusNotification.hmiLevel;

    if (![self.lifecycleStateMachine isCurrentState:SDLLifecycleStateReady]) {
        return;
    }

    [self.delegate hmiLevel:oldHMILevel didChangeToLevel:self.hmiLevel];
}

- (void)remoteHardwareDidUnregister:(NSNotification *)notification {
    NSAssert([notification.userInfo[SDLNotificationUserInfoObject] isKindOfClass:[SDLOnAppInterfaceUnregistered class]], @"A notification was sent with an unanticipated object");
    if (![notification.userInfo[SDLNotificationUserInfoObject] isKindOfClass:[SDLOnAppInterfaceUnregistered class]]) {
        return;
    }

    SDLOnAppInterfaceUnregistered *appUnregisteredNotification = notification.userInfo[SDLNotificationUserInfoObject];
    [SDLDebugTool logFormat:@"Remote Device forced unregistration for reason: %@", appUnregisteredNotification.reason];

    [self.lifecycleStateMachine transitionToState:SDLLifecycleStateDisconnected];
}

@end

NS_ASSUME_NONNULL_END