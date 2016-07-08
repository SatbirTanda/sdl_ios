//
//  SDLResponseDispatcher.m
//  SmartDeviceLink-iOS
//
//  Created by Joel Fischer on 7/8/16.
//  Copyright © 2016 smartdevicelink. All rights reserved.
//

#import "SDLResponseDispatcher.h"

#import "SmartDeviceLink.h"

NS_ASSUME_NONNULL_BEGIN

@implementation SDLResponseDispatcher

- (instancetype)initWithDispatcher:(id)dispatcher {
    self = [super init];
    if (!self) {
        return nil;
    }
    
    _rpcResponseHandlerMap = [NSMapTable mapTableWithKeyOptions:NSMapTableCopyIn valueOptions:NSMapTableCopyIn];
    _rpcRequestDictionary = [NSMutableDictionary dictionary];
    _commandHandlerMap = [NSMapTable mapTableWithKeyOptions:NSMapTableCopyIn valueOptions:NSMapTableCopyIn];
    _buttonHandlerMap = [NSMapTable mapTableWithKeyOptions:NSMapTableCopyIn valueOptions:NSMapTableCopyIn];
    _customButtonHandlerMap = [NSMapTable mapTableWithKeyOptions:NSMapTableCopyIn valueOptions:NSMapTableCopyIn];
    
    // Responses
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sdl_runHandlersForResponse:) name:SDLDidReceiveAddCommandResponse object:dispatcher];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sdl_runHandlersForResponse:) name:SDLDidReceiveAddSubMenuResponse object:dispatcher];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sdl_runHandlersForResponse:) name:SDLDidReceiveAlertResponse object:dispatcher];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sdl_runHandlersForResponse:) name:SDLDidReceiveAlertManeuverResponse object:dispatcher];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sdl_runHandlersForResponse:) name:SDLDidReceiveChangeRegistrationResponse object:dispatcher];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sdl_runHandlersForResponse:) name:SDLDidReceiveCreateInteractionChoiceSetResponse object:dispatcher];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sdl_runHandlersForResponse:) name:SDLDidReceiveDeleteCommandResponse object:dispatcher];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sdl_runHandlersForResponse:) name:SDLDidReceiveDeleteFileResponse object:dispatcher];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sdl_runHandlersForResponse:) name:SDLDidReceiveDeleteInteractionChoiceSetResponse object:dispatcher];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sdl_runHandlersForResponse:) name:SDLDidReceiveDeleteSubmenuResponse object:dispatcher];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sdl_runHandlersForResponse:) name:SDLDidReceiveDiagnosticMessageResponse object:dispatcher];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sdl_runHandlersForResponse:) name:SDLDidReceiveDialNumberResponse object:dispatcher];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sdl_runHandlersForResponse:) name:SDLDidReceiveEncodedSyncPDataResponse object:dispatcher];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sdl_runHandlersForResponse:) name:SDLDidReceiveEndAudioPassThruResponse object:dispatcher];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sdl_runHandlersForResponse:) name:SDLDidReceiveGenericResponse object:dispatcher];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sdl_runHandlersForResponse:) name:SDLDidReceiveGetDTCsResponse object:dispatcher];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sdl_runHandlersForResponse:) name:SDLDidReceiveGetVehicleDataResponse object:dispatcher];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sdl_runHandlersForResponse:) name:SDLDidReceiveListFilesResponse object:dispatcher];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sdl_runHandlersForResponse:) name:SDLDidReceivePerformAudioPassThruResponse object:dispatcher];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sdl_runHandlersForResponse:) name:SDLDidReceivePerformInteractionResponse object:dispatcher];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sdl_runHandlersForResponse:) name:SDLDidReceivePutFileResponse object:dispatcher];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sdl_runHandlersForResponse:) name:SDLDidReceiveReadDIDResponse object:dispatcher];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sdl_runHandlersForResponse:) name:SDLDidReceiveRegisterAppInterfaceResponse object:dispatcher];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sdl_runHandlersForResponse:) name:SDLDidReceiveResetGlobalPropertiesResponse object:dispatcher];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sdl_runHandlersForResponse:) name:SDLDidReceiveScrollableMessageResponse object:dispatcher];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sdl_runHandlersForResponse:) name:SDLDidReceiveSendLocationResponse object:dispatcher];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sdl_runHandlersForResponse:) name:SDLDidReceiveSetAppIconResponse object:dispatcher];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sdl_runHandlersForResponse:) name:SDLDidReceiveSetDisplayLayoutResponse object:dispatcher];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sdl_runHandlersForResponse:) name:SDLDidReceiveSetGlobalPropertiesResponse object:dispatcher];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sdl_runHandlersForResponse:) name:SDLDidReceiveSetMediaClockTimerResponse object:dispatcher];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sdl_runHandlersForResponse:) name:SDLDidReceiveShowConstantTBTResponse object:dispatcher];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sdl_runHandlersForResponse:) name:SDLDidReceiveShowResponse object:dispatcher];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sdl_runHandlersForResponse:) name:SDLDidReceiveSliderResponse object:dispatcher];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sdl_runHandlersForResponse:) name:SDLDidReceiveSpeakResponse object:dispatcher];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sdl_runHandlersForResponse:) name:SDLDidReceiveSubscribeButtonResponse object:dispatcher];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sdl_runHandlersForResponse:) name:SDLDidReceiveSubscribeVehicleDataResponse object:dispatcher];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sdl_runHandlersForResponse:) name:SDLDidReceiveSyncPDataResponse object:dispatcher];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sdl_runHandlersForResponse:) name:SDLDidReceiveUpdateTurnListResponse object:dispatcher];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sdl_runHandlersForResponse:) name:SDLDidReceiveUnregisterAppInterfaceResponse object:dispatcher];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sdl_runHandlersForResponse:) name:SDLDidReceiveUnsubscribeButtonResponse object:dispatcher];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sdl_runHandlersForResponse:) name:SDLDidReceiveUnsubscribeVehicleDataResponse object:dispatcher];
    
    // Some notifications
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sdl_runHandlerForButton:) name:SDLDidReceiveButtonEventNotification object:dispatcher];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sdl_runHandlerForButton:) name:SDLDidReceiveButtonPressNotification object:dispatcher];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sdl_runHandlerForCommand:) name:SDLDidReceiveCommandNotification object:dispatcher];
    
    return self;
}


#pragma mark - Storage

- (void)storeRequest:(SDLRPCRequest *)request handler:(nullable SDLRequestCompletionHandler)handler {
    NSNumber *correlationId = request.correlationID;
    
    // Check for RPCs that require an extra handler
    if ([request isKindOfClass:[SDLShow class]]) {
        // TODO: Can we create soft button ids ourselves?
        SDLShow *show = (SDLShow *)request;
        if (show.softButtons.count > 0) {
            [self sdl_addToHandlerMapWithSoftButtons:show.softButtons];
        }
    } else if ([request isKindOfClass:[SDLAddCommand class]]) {
        // TODO: Can we create CmdIDs ourselves?
        SDLAddCommand *addCommand = (SDLAddCommand *)request;
        if (!addCommand.cmdID) {
            @throw [NSException sdl_missingIdException];
        }
        if (addCommand.handler) {
            self.commandHandlerMap[addCommand.cmdID] = addCommand.handler;
        }
    } else if ([request isKindOfClass:[SDLSubscribeButton class]]) {
        // Convert SDLButtonName to NSString, since it doesn't conform to <NSCopying>
        SDLSubscribeButton *subscribeButton = (SDLSubscribeButton *)request;
        NSString *buttonName = subscribeButton.buttonName.value;
        if (!buttonName) {
            @throw [NSException sdl_missingIdException];
        }
        if (subscribeButton.handler) {
            self.buttonHandlerMap[buttonName] = subscribeButton.handler;
        }
    } else if ([request isKindOfClass:[SDLAlert class]]) {
        SDLAlert *alert = (SDLAlert *)request;
        [self sdl_addToHandlerMapWithSoftButtons:alert.softButtons];
    } else if ([request isKindOfClass:[SDLScrollableMessage class]]) {
        SDLScrollableMessage *scrollableMessage = (SDLScrollableMessage *)request;
        [self sdl_addToHandlerMapWithSoftButtons:scrollableMessage.softButtons];
    }
    
    if (handler) {
        self.rpcRequestDictionary[correlationId] = request;
        self.rpcResponseHandlerMap[correlationId] = handler;
    }
}

- (void)sdl_addToHandlerMapWithSoftButtons:(NSMutableArray<SDLSoftButton *> *)softButtons {
    for (SDLSoftButton *sb in softButtons) {
        if (!sb.softButtonID) {
            @throw [NSException sdl_missingIdException];
        }
        if (sb.handler) {
            self.customButtonHandlerMap[sb.softButtonID] = sb.handler;
        }
    }
}


#pragma mark - Handlers
#pragma mark Response

- (void)sdl_runHandlersForResponse:(__kindof SDLRPCResponse *)response {
    NSError *error = nil;
    BOOL success = [response.success boolValue];
    if (success == NO) {
        error = [NSError sdl_lifecycle_rpcErrorWithDescription:response.resultCode.value andReason:response.info];
    }
    
    // Find the appropriate request completion handler, remove the request and response handler
    SDLRequestCompletionHandler handler = self.rpcResponseHandlerMap[response.correlationID];
    SDLRPCRequest *request = self.rpcRequestDictionary[response.correlationID];
    [self.rpcRequestDictionary removeObjectForKey:response.correlationID];
    [self.rpcResponseHandlerMap removeObjectForKey:response.correlationID];
    
    // Run the response handler
    if (handler) {
        handler(request, response, error);
    }
    
    // If it's a DeleteCommand or UnsubscribeButton, we need to remove handlers for the corresponding commands / buttons
    if ([response isKindOfClass:[SDLDeleteCommandResponse class]]) {
        SDLDeleteCommand *deleteCommandRequest = (SDLDeleteCommand *)request;
        NSNumber *deleteCommandId = deleteCommandRequest.cmdID;
        [self.commandHandlerMap removeObjectForKey:deleteCommandId];
    } else if ([response isKindOfClass:[SDLUnsubscribeButtonResponse class]]) {
        SDLUnsubscribeButton *unsubscribeButtonRequest = (SDLUnsubscribeButton *)request;
        NSString *unsubscribeButtonName = unsubscribeButtonRequest.buttonName.value;
        [self.buttonHandlerMap removeObjectForKey:unsubscribeButtonName];
    }
}

#pragma mark Command

- (void)sdl_runHandlerForCommand:(SDLOnCommand *)command {
    SDLRPCNotificationHandler handler = nil;
    handler = self.commandHandlerMap[command.cmdID];
    
    if (handler) {
        handler(command);
    }
}

#pragma mark Button

- (void)sdl_runHandlerForButton:(__kindof SDLRPCNotification *)notification {
    SDLRPCNotificationHandler handler = nil;
    SDLButtonName *name = nil;
    NSNumber *customID = nil;
    
    if ([notification isKindOfClass:[SDLOnButtonEvent class]]) {
        name = ((SDLOnButtonEvent *)notification).buttonName;
        customID = ((SDLOnButtonEvent *)notification).customButtonID;
    } else if ([notification isKindOfClass:[SDLOnButtonPress class]]) {
        name = ((SDLOnButtonPress *)notification).buttonName;
        customID = ((SDLOnButtonPress *)notification).customButtonID;
    }
    
    if ([name isEqual:[SDLButtonName CUSTOM_BUTTON]]) {
        handler = self.customButtonHandlerMap[customID];
    } else {
        handler = self.buttonHandlerMap[name.value];
    }
    
    if (handler) {
        handler(notification);
    }
}

@end

NS_ASSUME_NONNULL_END
