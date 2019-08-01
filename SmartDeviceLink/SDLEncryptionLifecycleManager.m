//
//  SDLEncryptionLifecycleManager.m
//  SmartDeviceLink
//
//  Created by standa1 on 6/27/19.
//  Copyright © 2019 smartdevicelink. All rights reserved.
//

#import "SDLEncryptionLifecycleManager.h"
#import "SDLEncryptionManagerConstants.h"
#import "SDLAsynchronousRPCRequestOperation.h"
#import "SDLLogMacros.h"
#import "SDLStateMachine.h"
#import "SDLProtocolMessage.h"
#import "SDLRPCNotificationNotification.h"
#import "SDLOnHMIStatus.h"

@interface SDLEncryptionLifecycleManager() <SDLProtocolListener>

@property (strong, nonatomic, readonly) NSOperationQueue *rpcOperationQueue;
@property (strong, nonatomic, readonly) SDLPermissionManager *permissionManager;
@property (weak, nonatomic) id<SDLConnectionManagerType> connectionManager;
@property (weak, nonatomic) SDLProtocol *protocol;

@property (strong, nonatomic, readwrite) SDLStateMachine *encryptionStateMachine;
@property (copy, nonatomic, nullable) SDLHMILevel hmiLevel;

@end

@implementation SDLEncryptionLifecycleManager

- (instancetype)initWithConnectionManager:(id<SDLConnectionManagerType>)connectionManager configuration:(SDLEncryptionConfiguration *)configuration permissionManager:(SDLPermissionManager *)permissionManager rpcOperationQueue:(NSOperationQueue *)rpcOperationQueue {
    self = [super init];
    if (!self) {
        return nil;
    }
    
    SDLLogV(@"Creating EncryptionLifecycleManager");
    _hmiLevel = SDLHMILevelNone;
    _connectionManager = connectionManager;
    _permissionManager = permissionManager;
    _rpcOperationQueue = rpcOperationQueue;
    _encryptionStateMachine = [[SDLStateMachine alloc] initWithTarget:self initialState:SDLEncryptionLifecycleManagerStateStopped states:[self.class sdl_encryptionStateTransitionDictionary]];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sdl_hmiStatusDidChange:) name:SDLDidChangeHMIStatusNotification object:nil];

    return self;
}

- (void)startWithProtocol:(SDLProtocol *)protocol {
    _protocol = protocol;
    
    @synchronized(self.protocol.protocolDelegateTable) {
        if (![self.protocol.protocolDelegateTable containsObject:self]) {
            [self.protocol.protocolDelegateTable addObject:self];
        }
    }
    
    [self sdl_startEncryptionService];
}

- (void)stop {
    _hmiLevel = SDLHMILevelNone;
    _protocol = nil;
    
    SDLLogD(@"Stopping encryption manager");
    [self sdl_stopEncryptionService];
}

- (void)sendEncryptedRequest:(SDLRPCRequest *)request withResponseHandler:(SDLResponseHandler)handler {
    if (!self.protocol || !self.isEncryptionReady) {
        SDLLogV(@"Encryption manager is not yet ready, wait until after proxy is opened");
        return;
    }
    
    SDLAsynchronousRPCRequestOperation *op = [[SDLAsynchronousRPCRequestOperation alloc] initWithConnectionManager:self.connectionManager request:request withEncryption:YES responseHandler:handler];
    
    [self.rpcOperationQueue addOperation:op];
}

- (BOOL)isEncryptionReady {
    return [self.encryptionStateMachine isCurrentState:SDLEncryptionLifecycleManagerStateReady];
}

- (void)sdl_startEncryptionService {
    SDLLogV(@"Attempting to start Encryption Service");
    if (!self.protocol) {
        SDLLogV(@"Encryption manager is not yet started");
        return;
    }

    if (!self.permissionManager || !self.hmiLevel || !self.permissionManager.permissions) {
        SDLLogV(@"Permission Manager is not ready to encrypt.");
        return;
    }
    
    if (![self.hmiLevel isEqualToEnum:SDLHMILevelNone]) {
        [self.encryptionStateMachine transitionToState:SDLEncryptionLifecycleManagerStateStarting];
    } else {
        SDLLogE(@"Unable to send encryption start service request\n"
                "permissionManager: %@\n"
                "HMI state must be LIMITED, FULL, BACKGROUND: %@\n",
                self.permissionManager.permissions, self.hmiLevel);
    }
}

- (void)sdl_sendEncryptionStartService {
    SDLLogD(@"Sending secure rpc start service");
    [self.protocol startSecureServiceWithType:SDLServiceTypeRPC payload:nil completionHandler:^(BOOL success, NSError *error) {
        if (error) {
            SDLLogE(@"TLS setup error: %@", error);
            [self.encryptionStateMachine transitionToState:SDLEncryptionLifecycleManagerStateStopped];
        }
    }];
}

- (void)sdl_stopEncryptionService {
    _protocol = nil;
    
    [self.encryptionStateMachine transitionToState:SDLEncryptionLifecycleManagerStateStopped];
}

#pragma mark Encryption
+ (NSDictionary<SDLState *, SDLAllowableStateTransitions *> *)sdl_encryptionStateTransitionDictionary {
    return @{
             SDLEncryptionLifecycleManagerStateStopped : @[SDLEncryptionLifecycleManagerStateStarting],
             SDLEncryptionLifecycleManagerStateStarting : @[SDLEncryptionLifecycleManagerStateStopped, SDLEncryptionLifecycleManagerStateReady],
             SDLEncryptionLifecycleManagerStateReady : @[SDLEncryptionLifecycleManagerStateShuttingDown, SDLEncryptionLifecycleManagerStateStopped],
             SDLEncryptionLifecycleManagerStateShuttingDown : @[SDLEncryptionLifecycleManagerStateStopped]
             };
}

#pragma mark - State Machine
- (void)didEnterStateEncryptionStarting {
    SDLLogD(@"Encryption manager is starting");
    
    [self sdl_sendEncryptionStartService];
}

- (void)didEnterStateEncryptionReady {
    SDLLogD(@"Encryption manager is ready");
}

- (void)didEnterStateEncryptionStopped {
    SDLLogD(@"Encryption manager stopped");    
}

#pragma mark - SDLProtocolListener
#pragma mark Encryption Start Service ACK

- (void)handleProtocolStartServiceACKMessage:(SDLProtocolMessage *)startServiceACK {
    switch (startServiceACK.header.serviceType) {
        case SDLServiceTypeRPC: {
            [self sdl_handleEncryptionStartServiceAck:startServiceACK];
        } break;
        default: break;
    }
}

- (void)sdl_handleEncryptionStartServiceAck:(SDLProtocolMessage *)encryptionStartServiceAck {
    if (encryptionStartServiceAck.header.encrypted) {
        SDLLogD(@"Encryption service started");
        [self.encryptionStateMachine transitionToState:SDLEncryptionLifecycleManagerStateReady];
    } else {
        SDLLogD(@"Encryption service ACK received encryption = OFF");
        [self.encryptionStateMachine transitionToState:SDLEncryptionLifecycleManagerStateStopped];
    }
}

#pragma mark Encryption Start Service NAK

- (void)handleProtocolStartServiceNAKMessage:(SDLProtocolMessage *)startServiceNAK {
    switch (startServiceNAK.header.serviceType) {
        case SDLServiceTypeRPC: {
            [self sdl_handleEncryptionStartServiceNAK:startServiceNAK];
        } break;
        default: break;
    }
}

- (void)sdl_handleEncryptionStartServiceNAK:(SDLProtocolMessage *)audioStartServiceNak {
    SDLLogW(@"Encryption service failed to start due to NACK");
    [self.encryptionStateMachine transitionToState:SDLEncryptionLifecycleManagerStateStopped];
}

#pragma mark Encryption End Service

- (void)handleProtocolEndServiceACKMessage:(SDLProtocolMessage *)endServiceACK {
    switch (endServiceACK.header.serviceType) {
        case SDLServiceTypeRPC: {
            SDLLogW(@"Encryption RPC service ended with end service ACK");
            [self.encryptionStateMachine transitionToState:SDLEncryptionLifecycleManagerStateStopped];
        } break;
        default: break;
    }
}

- (void)handleProtocolEndServiceNAKMessage:(SDLProtocolMessage *)endServiceNAK {
    switch (endServiceNAK.header.serviceType) {
        case SDLServiceTypeRPC: {
            SDLLogW(@"Encryption RPC service ended with end service NACK");
            [self.encryptionStateMachine transitionToState:SDLEncryptionLifecycleManagerStateStopped];
        } break;
        default: break;
    }
}

#pragma mark - SDL RPC Notification callbacks
- (void)sdl_hmiStatusDidChange:(SDLRPCNotificationNotification *)notification {
    NSAssert([notification.notification isKindOfClass:[SDLOnHMIStatus class]], @"A notification was sent with an unanticipated object");
    if (![notification.notification isKindOfClass:[SDLOnHMIStatus class]]) {
        return;
    }
    
    SDLOnHMIStatus *hmiStatus = (SDLOnHMIStatus*)notification.notification;
    self.hmiLevel = hmiStatus.hmiLevel;
    
    // if startWithProtocol has not been called yet, abort here
    if (!self.protocol) { return; }
    
    if (!self.isEncryptionReady) {
        [self sdl_startEncryptionService];
    }
}

@end