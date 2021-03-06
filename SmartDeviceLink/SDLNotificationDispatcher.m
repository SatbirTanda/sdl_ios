//
//  SDLnotificationDispatcher.m
//  SmartDeviceLink-iOS
//
//  Created by Joel Fischer on 7/7/16.
//  Copyright © 2016 smartdevicelink. All rights reserved.
//

#import "SDLNotificationDispatcher.h"

#import "SDLError.h"
#import "SDLNotificationConstants.h"
#import "SDLRPCNotification.h"
#import "SDLRPCNotificationNotification.h"
#import "SDLRPCRequestNotification.h"
#import "SDLRPCResponseNotification.h"

NS_ASSUME_NONNULL_BEGIN

@implementation SDLNotificationDispatcher

- (instancetype)init {
    self = [super init];
    if (!self) { return nil; }

    return self;
}

- (void)postNotificationName:(NSString *)name infoObject:(nullable id)infoObject {
    NSDictionary<NSString *, id> *userInfo = nil;
    if (infoObject != nil) {
        userInfo = @{SDLNotificationUserInfoObject: infoObject};
    }

    [[NSNotificationCenter defaultCenter] postNotificationName:name object:self userInfo:userInfo];
}

- (void)postRPCRequestNotification:(NSString *)name request:(__kindof SDLRPCRequest *)request {
    SDLRPCRequestNotification *notification = [[SDLRPCRequestNotification alloc] initWithName:name object:self rpcRequest:request];

    [[NSNotificationCenter defaultCenter] postNotification:notification];
}

- (void)postRPCResponseNotification:(NSString *)name response:(__kindof SDLRPCResponse *)response {
    SDLRPCResponseNotification *notification = [[SDLRPCResponseNotification alloc] initWithName:name object:self rpcResponse:response];

    [[NSNotificationCenter defaultCenter] postNotification:notification];
}

- (void)postRPCNotificationNotification:(NSString *)name notification:(__kindof SDLRPCNotification *)rpcNotification {
    SDLRPCNotificationNotification *notification = [[SDLRPCNotificationNotification alloc] initWithName:name object:self rpcNotification:rpcNotification];

    [[NSNotificationCenter defaultCenter] postNotification:notification];
}

#pragma mark - SDLProxyListener Delegate Methods

- (void)onProxyOpened {
    [self postNotificationName:SDLTransportDidConnect infoObject:nil];
}

- (void)onProxyClosed {
    [self postNotificationName:SDLTransportDidDisconnect infoObject:nil];
}

- (void)onTransportError:(NSError *)error {
    [self postNotificationName:SDLTransportConnectError infoObject:error];
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wincompatible-pointer-types"

- (void)onOnHMIStatus:(SDLOnHMIStatus *)notification {
    [self postRPCNotificationNotification:SDLDidChangeHMIStatusNotification notification:notification];
}

- (void)onOnDriverDistraction:(SDLOnDriverDistraction *)notification {
    [self postRPCNotificationNotification:SDLDidChangeDriverDistractionStateNotification notification:notification];
}

#pragma mark Optional Methods

- (void)onError:(NSException *)e {
    NSError *error = [NSError sdl_lifecycle_unknownRemoteErrorWithDescription:e.name andReason:e.reason];
    [self postNotificationName:SDLDidReceiveError infoObject:error];
}

# pragma mark - Responses

- (void)onReceivedLockScreenIcon:(UIImage *)icon {
    [self postNotificationName:SDLDidReceiveLockScreenIcon infoObject:icon];
}

- (void)onAddCommandResponse:(SDLAddCommandResponse *)response {
    [self postRPCResponseNotification:SDLDidReceiveAddCommandResponse response:response];
}

- (void)onAddSubMenuResponse:(SDLAddSubMenuResponse *)response {
    [self postRPCResponseNotification:SDLDidReceiveAddSubMenuResponse response:response];
}

- (void)onAlertManeuverResponse:(SDLAlertManeuverResponse *)response {
    [self postRPCResponseNotification:SDLDidReceiveAlertManeuverResponse response:response];
}

- (void)onAlertResponse:(SDLAlertResponse *)response {
    [self postRPCResponseNotification:SDLDidReceiveAlertResponse response:response];
}

- (void)onButtonPressResponse:(SDLButtonPressResponse *)response {
    [self postRPCResponseNotification:SDLDidReceiveButtonPressResponse response:response];
}

- (void)onCancelInteractionResponse:(SDLCancelInteractionResponse *)response {
    [self postRPCResponseNotification:SDLDidReceiveCancelInteractionResponse response:response];
}

- (void)onChangeRegistrationResponse:(SDLChangeRegistrationResponse *)response {
    [self postRPCResponseNotification:SDLDidReceiveChangeRegistrationResponse response:response];
}

- (void)onCloseApplicationResponse:(SDLCloseApplicationResponse *)response {
    [self postRPCResponseNotification:SDLDidReceiveCloseApplicationResponse response:response];
}

- (void)onCreateInteractionChoiceSetResponse:(SDLCreateInteractionChoiceSetResponse *)response {
    [self postRPCResponseNotification:SDLDidReceiveCreateInteractionChoiceSetResponse response:response];
}

- (void)onCreateWindowResponse:(SDLCreateWindowResponse *)response {
    [self postRPCResponseNotification:SDLDidReceiveCreateWindowResponse response:response];
}

- (void)onDeleteCommandResponse:(SDLDeleteCommandResponse *)response {
    [self postRPCResponseNotification:SDLDidReceiveDeleteCommandResponse response:response];
}

- (void)onDeleteFileResponse:(SDLDeleteFileResponse *)response {
    [self postRPCResponseNotification:SDLDidReceiveDeleteFileResponse response:response];
}

- (void)onDeleteInteractionChoiceSetResponse:(SDLDeleteInteractionChoiceSetResponse *)response {
    [self postRPCResponseNotification:SDLDidReceiveDeleteInteractionChoiceSetResponse response:response];
}

- (void)onDeleteSubMenuResponse:(SDLDeleteSubMenuResponse *)response {
    [self postRPCResponseNotification:SDLDidReceiveDeleteSubmenuResponse response:response];
}

- (void)onDeleteWindowResponse:(SDLDeleteWindowResponse *)response {
    [self postRPCResponseNotification:SDLDidReceiveDeleteWindowResponse response:response];
}

- (void)onDiagnosticMessageResponse:(SDLDiagnosticMessageResponse *)response {
    [self postRPCResponseNotification:SDLDidReceiveDiagnosticMessageResponse response:response];
}

- (void)onDialNumberResponse:(SDLDialNumberResponse *)response {
    [self postRPCResponseNotification:SDLDidReceiveDialNumberResponse response:response];
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-implementations"
- (void)onEncodedSyncPDataResponse:(SDLEncodedSyncPDataResponse *)response {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    [self postRPCResponseNotification:SDLDidReceiveEncodedSyncPDataResponse response:response];
#pragma clang diagnostic pop
}
#pragma clang diagnostic pop

- (void)onEndAudioPassThruResponse:(SDLEndAudioPassThruResponse *)response {
    [self postRPCResponseNotification:SDLDidReceiveEndAudioPassThruResponse response:response];
}

- (void)onGenericResponse:(SDLGenericResponse *)response {
    [self postRPCResponseNotification:SDLDidReceiveGenericResponse response:response];
}

- (void)onGetCloudAppPropertiesResponse:(SDLGetCloudAppPropertiesResponse *)response {
    [self postRPCResponseNotification:SDLDidReceiveGetCloudAppPropertiesResponse response:response];
}

- (void)onGetAppServiceDataResponse:(SDLGetAppServiceDataResponse *)response {
    [self postRPCResponseNotification:SDLDidReceiveGetAppServiceDataResponse response:response];
}

- (void)onGetDTCsResponse:(SDLGetDTCsResponse *)response {
    [self postRPCResponseNotification:SDLDidReceiveGetDTCsResponse response:response];
}

- (void)onGetFileResponse:(SDLGetFileResponse *)response {
    [self postRPCResponseNotification:SDLDidReceiveGetFileResponse response:response];
}

- (void)onGetInteriorVehicleDataResponse:(SDLGetInteriorVehicleDataResponse *)response {
    [self postRPCResponseNotification:SDLDidReceiveGetInteriorVehicleDataResponse response:response];
}

- (void)onGetInteriorVehicleDataConsentResponse:(SDLGetInteriorVehicleDataConsentResponse *)response {
    [self postRPCResponseNotification:SDLDidReceiveGetInteriorVehicleDataConsentResponse response:response];
}

- (void)onGetSystemCapabilityResponse:(SDLGetSystemCapabilityResponse *)response {
    [self postRPCResponseNotification:SDLDidReceiveGetSystemCapabilitiesResponse response:response];
}

- (void)onGetVehicleDataResponse:(SDLGetVehicleDataResponse *)response {
    [self postRPCResponseNotification:SDLDidReceiveGetVehicleDataResponse response:response];
}

- (void)onGetWayPointsResponse:(SDLGetWayPointsResponse *)response {
    [self postRPCResponseNotification:SDLDidReceiveGetWaypointsResponse response:response];
}

- (void)onListFilesResponse:(SDLListFilesResponse *)response {
    [self postRPCResponseNotification:SDLDidReceiveListFilesResponse response:response];
}

- (void)onPerformAppServiceInteractionResponse:(SDLPerformAppServiceInteractionResponse *)response {
    [self postRPCResponseNotification:SDLDidReceivePerformAppServiceInteractionResponse response:response];
}

- (void)onPerformAudioPassThruResponse:(SDLPerformAudioPassThruResponse *)response {
    [self postRPCResponseNotification:SDLDidReceivePerformAudioPassThruResponse response:response];
}

- (void)onPerformInteractionResponse:(SDLPerformInteractionResponse *)response {
    [self postRPCResponseNotification:SDLDidReceivePerformInteractionResponse response:response];
}

- (void)onPublishAppServiceResponse:(SDLPublishAppServiceResponse *)response {
    [self postRPCResponseNotification:SDLDidReceivePublishAppServiceResponse response:response];
}

- (void)onPutFileResponse:(SDLPutFileResponse *)response {
    [self postRPCResponseNotification:SDLDidReceivePutFileResponse response:response];
}

- (void)onReadDIDResponse:(SDLReadDIDResponse *)response {
    [self postRPCResponseNotification:SDLDidReceiveReadDIDResponse response:response];
}

- (void)onRegisterAppInterfaceResponse:(SDLRegisterAppInterfaceResponse *)response {
    [self postRPCResponseNotification:SDLDidReceiveRegisterAppInterfaceResponse response:response];
}

- (void)onReleaseInteriorVehicleDataModuleResponse:(SDLReleaseInteriorVehicleDataModuleResponse *)response {
    [self postRPCResponseNotification:SDLDidReceiveReleaseInteriorVehicleDataModuleResponse response:response];
}

- (void)onResetGlobalPropertiesResponse:(SDLResetGlobalPropertiesResponse *)response {
    [self postRPCResponseNotification:SDLDidReceiveResetGlobalPropertiesResponse response:response];
}

- (void)onScrollableMessageResponse:(SDLScrollableMessageResponse *)response {
    [self postRPCResponseNotification:SDLDidReceiveScrollableMessageResponse response:response];
}

- (void)onSendHapticDataResponse:(SDLSendHapticDataResponse *)response {
    [self postRPCResponseNotification:SDLDidReceiveSendHapticDataResponse response:response];
}

- (void)onSendLocationResponse:(SDLSendLocationResponse *)response {
    [self postRPCResponseNotification:SDLDidReceiveSendLocationResponse response:response];
}

- (void)onSetAppIconResponse:(SDLSetAppIconResponse *)response {
    [self postRPCResponseNotification:SDLDidReceiveSetAppIconResponse response:response];
}

- (void)onSetCloudAppPropertiesResponse:(SDLSetCloudAppPropertiesResponse *)response {
    [self postRPCResponseNotification:SDLDidReceiveSetCloudAppPropertiesResponse response:response];
}

- (void)onSetDisplayLayoutResponse:(SDLSetDisplayLayoutResponse *)response {
    [self postRPCResponseNotification:SDLDidReceiveSetDisplayLayoutResponse response:response];
}

- (void)onSetGlobalPropertiesResponse:(SDLSetGlobalPropertiesResponse *)response {
    [self postRPCResponseNotification:SDLDidReceiveSetGlobalPropertiesResponse response:response];
}

- (void)onSetInteriorVehicleDataResponse:(SDLSetInteriorVehicleDataResponse *)response{
    [self postRPCResponseNotification:SDLDidReceiveSetInteriorVehicleDataResponse response:response];
}

- (void)onSetMediaClockTimerResponse:(SDLSetMediaClockTimerResponse *)response {
    [self postRPCResponseNotification:SDLDidReceiveSetMediaClockTimerResponse response:response];
}

- (void)onShowConstantTBTResponse:(SDLShowConstantTBTResponse *)response {
    [self postRPCResponseNotification:SDLDidReceiveShowConstantTBTResponse response:response];
}

- (void)onShowResponse:(SDLShowResponse *)response {
    [self postRPCResponseNotification:SDLDidReceiveShowResponse response:response];
}

- (void)onShowAppMenuResponse:(SDLShowAppMenuResponse *)response {
    [self postRPCResponseNotification:SDLDidReceiveShowAppMenuResponse response:response];
}

- (void)onSliderResponse:(SDLSliderResponse *)response {
    [self postRPCResponseNotification:SDLDidReceiveSliderResponse response:response];
}

- (void)onSpeakResponse:(SDLSpeakResponse *)response {
    [self postRPCResponseNotification:SDLDidReceiveSpeakResponse response:response];
}

- (void)onSubscribeButtonResponse:(SDLSubscribeButtonResponse *)response {
    [self postRPCResponseNotification:SDLDidReceiveSubscribeButtonResponse response:response];
}

- (void)onSubscribeVehicleDataResponse:(SDLSubscribeVehicleDataResponse *)response {
    [self postRPCResponseNotification:SDLDidReceiveSubscribeVehicleDataResponse response:response];
}

- (void)onSubscribeWayPointsResponse:(SDLSubscribeWayPointsResponse *)response {
    [self postRPCResponseNotification:SDLDidReceiveSubscribeWaypointsResponse response:response];
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-implementations"
- (void)onSyncPDataResponse:(SDLSyncPDataResponse *)response {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    [self postRPCResponseNotification:SDLDidReceiveSyncPDataResponse response:response];
#pragma clang diagnostic pop
}
#pragma clang diagnostic pop

- (void)onUpdateTurnListResponse:(SDLUpdateTurnListResponse *)response {
    [self postRPCResponseNotification:SDLDidReceiveUpdateTurnListResponse response:response];
}

- (void)onUnpublishAppServiceResponse:(SDLUnpublishAppServiceResponse *)response {
    [self postRPCResponseNotification:SDLDidReceiveUnpublishAppServiceResponse response:response];
}

- (void)onUnregisterAppInterfaceResponse:(SDLUnregisterAppInterfaceResponse *)response {
    [self postRPCResponseNotification:SDLDidReceiveUnregisterAppInterfaceResponse response:response];
}

- (void)onUnsubscribeButtonResponse:(SDLUnsubscribeButtonResponse *)response {
    [self postRPCResponseNotification:SDLDidReceiveUnsubscribeButtonResponse response:response];
}

- (void)onUnsubscribeVehicleDataResponse:(SDLUnsubscribeVehicleDataResponse *)response {
    [self postRPCResponseNotification:SDLDidReceiveUnsubscribeVehicleDataResponse response:response];
}

- (void)onUnsubscribeWayPointsResponse:(SDLUnsubscribeWayPointsResponse *)response {
    [self postRPCResponseNotification:SDLDidReceiveUnsubscribeWaypointsResponse response:response];
}

# pragma mark - Requests

- (void)onAddCommand:(SDLAddCommand *)request {
    [self postRPCRequestNotification:SDLDidReceiveAddCommandRequest request:request];
}

- (void)onAddSubMenu:(SDLAddSubMenu *)request {
    [self postRPCRequestNotification:SDLDidReceiveAddSubMenuRequest request:request];
}

- (void)onAlert:(SDLAlert *)request {
    [self postRPCRequestNotification:SDLDidReceiveAlertRequest request:request];
}

- (void)onAlertManeuver:(SDLAlertManeuver *)request {
    [self postRPCRequestNotification:SDLDidReceiveAlertManeuverRequest request:request];
}

- (void)onButtonPress:(SDLButtonPress *)request {
    [self postRPCRequestNotification:SDLDidReceiveButtonPressRequest request:request];
}

- (void)onCancelInteraction:(SDLCancelInteraction *)request {
    [self postRPCRequestNotification:SDLDidReceiveCancelInteractionRequest request:request];
}

- (void)onChangeRegistration:(SDLChangeRegistration *)request {
    [self postRPCRequestNotification:SDLDidReceiveChangeRegistrationRequest request:request];
}

- (void)onCloseApplication:(SDLCloseApplication *)request {
    [self postRPCRequestNotification:SDLDidReceiveCloseApplicationRequest request:request];
}

- (void)onCreateInteractionChoiceSet:(SDLCreateInteractionChoiceSet *)request {
    [self postRPCRequestNotification:SDLDidReceiveCreateInteractionChoiceSetRequest request:request];
}

- (void)onCreateWindow:(SDLCreateWindow *)request {
    [self postRPCRequestNotification:SDLDidReceiveCreateWindowRequest request:request];
}

- (void)onDeleteCommand:(SDLDeleteCommand *)request {
    [self postRPCRequestNotification:SDLDidReceiveDeleteCommandRequest request:request];
}

- (void)onDeleteFile:(SDLDeleteFile *)request {
    [self postRPCRequestNotification:SDLDidReceiveDeleteFileRequest request:request];
}

- (void)onDeleteInteractionChoiceSet:(SDLDeleteInteractionChoiceSet *)request {
    [self postRPCRequestNotification:SDLDidReceiveDeleteInteractionChoiceSetRequest request:request];
}

- (void)onDeleteSubMenu:(SDLDeleteSubMenu *)request {
    [self postRPCRequestNotification:SDLDidReceiveDeleteSubMenuRequest request:request];
}

- (void)onDeleteWindow:(SDLDeleteWindow *)request {
    [self postRPCRequestNotification:SDLDidReceiveDeleteWindowRequest request:request];
}

- (void)onDiagnosticMessage:(SDLDiagnosticMessage *)request {
    [self postRPCRequestNotification:SDLDidReceiveDiagnosticMessageRequest request:request];
}

- (void)onDialNumber:(SDLDialNumber *)request {
    [self postRPCRequestNotification:SDLDidReceiveDialNumberRequest request:request];
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-implementations"
- (void)onEncodedSyncPData:(SDLEncodedSyncPData *)request {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    [self postRPCRequestNotification:SDLDidReceiveEncodedSyncPDataRequest request:request];
#pragma clang diagnostic pop
}
#pragma clang diagnostic pop

- (void)onEndAudioPassThru:(SDLEndAudioPassThru *)request {
    [self postRPCRequestNotification:SDLDidReceiveEndAudioPassThruRequest request:request];
}

- (void)onGetAppServiceData:(SDLGetAppServiceData *)request {
    [self postRPCRequestNotification:SDLDidReceiveGetAppServiceDataRequest request:request];
}

- (void)onGetCloudAppProperties:(SDLGetCloudAppProperties *)request {
    [self postRPCRequestNotification:SDLDidReceiveGetCloudAppPropertiesRequest request:request];
}

- (void)onGetDTCs:(SDLGetDTCs *)request {
    [self postRPCRequestNotification:SDLDidReceiveGetDTCsRequest request:request];
}

- (void)onGetFile:(SDLGetFile *)request {
    [self postRPCRequestNotification:SDLDidReceiveGetFileRequest request:request];
}

- (void)onGetInteriorVehicleData:(SDLGetInteriorVehicleData *)request {
    [self postRPCRequestNotification:SDLDidReceiveGetInteriorVehicleDataRequest request:request];
}

- (void)onGetInteriorVehicleDataConsent:(SDLGetInteriorVehicleDataConsent *)request {
    [self postRPCRequestNotification:SDLDidReceiveGetInteriorVehicleDataConsentRequest request:request];
}

- (void)onGetSystemCapability:(SDLGetSystemCapability *)request {
    [self postRPCRequestNotification:SDLDidReceiveGetSystemCapabilityRequest request:request];
}

- (void)onGetVehicleData:(SDLGetVehicleData *)request {
    [self postRPCRequestNotification:SDLDidReceiveGetVehicleDataRequest request:request];
}

- (void)onGetWayPoints:(SDLGetWayPoints *)request {
    [self postRPCRequestNotification:SDLDidReceiveGetWayPointsRequest request:request];
}

- (void)onListFiles:(SDLListFiles *)request {
    [self postRPCRequestNotification:SDLDidReceiveListFilesRequest request:request];
}

- (void)onPerformAppServiceInteraction:(SDLPerformAppServiceInteraction *)request {
    [self postRPCRequestNotification:SDLDidReceivePerformAppServiceInteractionRequest request:request];
}

- (void)onPerformAudioPassThru:(SDLPerformAudioPassThru *)request {
    [self postRPCRequestNotification:SDLDidReceivePerformAudioPassThruRequest request:request];
}

- (void)onPerformInteraction:(SDLPerformInteraction *)request {
    [self postRPCRequestNotification:SDLDidReceivePerformInteractionRequest request:request];
}

- (void)onPublishAppService:(SDLPublishAppService *)request {
    [self postRPCRequestNotification:SDLDidReceivePublishAppServiceRequest request:request];
}

- (void)onPutFile:(SDLPutFile *)request {
    [self postRPCRequestNotification:SDLDidReceivePutFileRequest request:request];
}

- (void)onReadDID:(SDLReadDID *)request {
    [self postRPCRequestNotification:SDLDidReceiveReadDIDRequest request:request];
}

- (void)onRegisterAppInterface:(SDLRegisterAppInterface *)request {
    [self postRPCRequestNotification:SDLDidReceiveRegisterAppInterfaceRequest request:request];
}

- (void)onReleaseInteriorVehicleDataModule:(SDLReleaseInteriorVehicleDataModule *)request {
    [self postRPCRequestNotification:SDLDidReceiveReleaseInteriorVehicleDataModuleRequest request:request];
}

- (void)onResetGlobalProperties:(SDLResetGlobalProperties *)request {
    [self postRPCRequestNotification:SDLDidReceiveResetGlobalPropertiesRequest request:request];
}

- (void)onScrollableMessage:(SDLScrollableMessage *)request {
    [self postRPCRequestNotification:SDLDidReceiveScrollableMessageRequest request:request];
}

- (void)onSendHapticData:(SDLSendHapticData *)request {
    [self postRPCRequestNotification:SDLDidReceiveSendHapticDataRequest request:request];
}

- (void)onSendLocation:(SDLSendLocation *)request {
    [self postRPCRequestNotification:SDLDidReceiveSendLocationRequest request:request];
}

- (void)onSetAppIcon:(SDLSetAppIcon *)request {
    [self postRPCRequestNotification:SDLDidReceiveSetAppIconRequest request:request];
}

- (void)onSetCloudAppProperties:(SDLSetCloudAppProperties *)request {
    [self postRPCRequestNotification:SDLDidReceiveSetCloudAppPropertiesRequest request:request];
}

- (void)onSetDisplayLayout:(SDLSetDisplayLayout *)request {
    [self postRPCRequestNotification:SDLDidReceiveSetDisplayLayoutRequest request:request];
}

- (void)onSetGlobalProperties:(SDLSetGlobalProperties *)request {
    [self postRPCRequestNotification:SDLDidReceiveSetGlobalPropertiesRequest request:request];
}

- (void)onSetInteriorVehicleData:(SDLSetInteriorVehicleData *)request {
    [self postRPCRequestNotification:SDLDidReceiveSetInteriorVehicleDataRequest request:request];
}

- (void)onSetMediaClockTimer:(SDLSetMediaClockTimer *)request {
    [self postRPCRequestNotification:SDLDidReceiveSetMediaClockTimerRequest request:request];
}

- (void)onShow:(SDLShow *)request {
    [self postRPCRequestNotification:SDLDidReceiveShowRequest request:request];
}

- (void)onShowAppMenu:(SDLShowAppMenu *)request {
    [self postRPCRequestNotification:SDLDidReceiveShowAppMenuRequest request:request];
}

- (void)onShowConstantTBT:(SDLShowConstantTBT *)request {
    [self postRPCRequestNotification:SDLDidReceiveShowConstantTBTRequest request:request];
}

- (void)onSlider:(SDLSlider *)request {
    [self postRPCRequestNotification:SDLDidReceiveSliderRequest request:request];
}

- (void)onSpeak:(SDLSpeak *)request {
    [self postRPCRequestNotification:SDLDidReceiveSpeakRequest request:request];
}

- (void)onSubscribeButton:(SDLSubscribeButton *)request {
    [self postRPCRequestNotification:SDLDidReceiveSubscribeButtonRequest request:request];
}

- (void)onSubscribeVehicleData:(SDLSubscribeVehicleData *)request {
    [self postRPCRequestNotification:SDLDidReceiveSubscribeVehicleDataRequest request:request];
}

- (void)onSubscribeWayPoints:(SDLSubscribeWayPoints *)request {
    [self postRPCRequestNotification:SDLDidReceiveSubscribeWayPointsRequest request:request];
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-implementations"
- (void)onSyncPData:(SDLSyncPData *)request {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    [self postRPCRequestNotification:SDLDidReceiveSyncPDataRequest request:request];
#pragma clang diagnostic pop
}
#pragma clang diagnostic pop

-(void)onSystemRequest:(SDLSystemRequest *)request {
    [self postRPCRequestNotification:SDLDidReceiveSystemRequestRequest request:request];
}

- (void)onUnpublishAppService:(SDLUnpublishAppService *)request {
    [self postRPCRequestNotification:SDLDidReceiveUnpublishAppServiceRequest request:request];
}

- (void)onUnregisterAppInterface:(SDLUnregisterAppInterface *)request {
    [self postRPCRequestNotification:SDLDidReceiveUnregisterAppInterfaceRequest request:request];
}

- (void)onUnsubscribeButton:(SDLUnsubscribeButton *)request {
    [self postRPCRequestNotification:SDLDidReceiveUnsubscribeButtonRequest request:request];
}

- (void)onUnsubscribeVehicleData:(SDLUnsubscribeVehicleData *)request {
    [self postRPCRequestNotification:SDLDidReceiveUnsubscribeVehicleDataRequest request:request];
}

- (void)onUnsubscribeWayPoints:(SDLUnsubscribeWayPoints *)request {
    [self postRPCRequestNotification:SDLDidReceiveUnsubscribeWayPointsRequest request:request];
}

- (void)onUpdateTurnList:(SDLUpdateTurnList *)request {
    [self postRPCRequestNotification:SDLDidReceiveUpdateTurnListRequest request:request];
}

# pragma mark - Notifications

- (void)onOnAppInterfaceUnregistered:(SDLOnAppInterfaceUnregistered *)notification {
    [self postRPCNotificationNotification:SDLDidReceiveAppUnregisteredNotification notification:notification];
}

- (void)onOnAppServiceData:(SDLOnAppServiceData *)notification {
    [self postRPCNotificationNotification:SDLDidReceiveAppServiceDataNotification notification:notification];
}

- (void)onOnAudioPassThru:(SDLOnAudioPassThru *)notification {
    [self postRPCNotificationNotification:SDLDidReceiveAudioPassThruNotification notification:notification];
}

- (void)onOnButtonEvent:(SDLOnButtonEvent *)notification {
    [self postRPCNotificationNotification:SDLDidReceiveButtonEventNotification notification:notification];
}

- (void)onOnButtonPress:(SDLOnButtonPress *)notification {
    [self postRPCNotificationNotification:SDLDidReceiveButtonPressNotification notification:notification];
}

- (void)onOnCommand:(SDLOnCommand *)notification {
    [self postRPCNotificationNotification:SDLDidReceiveCommandNotification notification:notification];
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-implementations"
- (void)onOnEncodedSyncPData:(SDLOnEncodedSyncPData *)notification {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    [self postRPCNotificationNotification:SDLDidReceiveEncodedDataNotification notification:notification];
#pragma clang diagnostic pop
}
#pragma clang diagnostic pop

- (void)onOnHashChange:(SDLOnHashChange *)notification {
    [self postRPCNotificationNotification:SDLDidReceiveNewHashNotification notification:notification];
}

- (void)onOnInteriorVehicleData:(SDLOnInteriorVehicleData *)notification {
    [self postRPCNotificationNotification:SDLDidReceiveInteriorVehicleDataNotification notification:notification];
}

- (void)onOnKeyboardInput:(SDLOnKeyboardInput *)notification {
    [self postRPCNotificationNotification:SDLDidReceiveKeyboardInputNotification notification:notification];
}

- (void)onOnLanguageChange:(SDLOnLanguageChange *)notification {
    [self postRPCNotificationNotification:SDLDidChangeLanguageNotification notification:notification];
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-implementations"
- (void)onOnLockScreenNotification:(SDLOnLockScreenStatus *)notification {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    [self postRPCNotificationNotification:SDLDidChangeLockScreenStatusNotification notification:notification];
#pragma clang diagnostic pop
}
#pragma clang diagnostic pop

- (void)onOnPermissionsChange:(SDLOnPermissionsChange *)notification {
    [self postRPCNotificationNotification:SDLDidChangePermissionsNotification notification:notification];
}

- (void)onOnRCStatus:(SDLOnRCStatus *)notification {
    [self postRPCNotificationNotification:SDLDidReceiveRemoteControlStatusNotification notification:notification];
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-implementations"
- (void)onOnSyncPData:(SDLOnSyncPData *)notification {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    [self postRPCNotificationNotification:SDLDidReceiveSyncPDataNotification notification:notification];
#pragma clang diagnostic pop
}
#pragma clang diagnostic pop

- (void)onOnSystemCapabilityUpdated:(SDLOnSystemCapabilityUpdated *)notification {
    [self postRPCNotificationNotification:SDLDidReceiveSystemCapabilityUpdatedNotification notification:notification];
}

- (void)onOnSystemRequest:(SDLOnSystemRequest *)notification {
    [self postRPCNotificationNotification:SDLDidReceiveSystemRequestNotification notification:notification];
}

- (void)onOnTBTClientState:(SDLOnTBTClientState *)notification {
    [self postRPCNotificationNotification:SDLDidChangeTurnByTurnStateNotification notification:notification];
}

- (void)onOnTouchEvent:(SDLOnTouchEvent *)notification {
    [self postRPCNotificationNotification:SDLDidReceiveTouchEventNotification notification:notification];
}

- (void)onOnVehicleData:(SDLOnVehicleData *)notification {
    [self postRPCNotificationNotification:SDLDidReceiveVehicleDataNotification notification:notification];
}

- (void)onOnWayPointChange:(SDLOnWayPointChange *)notification {
    [self postRPCNotificationNotification:SDLDidReceiveWaypointNotification notification:notification];
}

#pragma clang diagnostic pop

@end

NS_ASSUME_NONNULL_END
