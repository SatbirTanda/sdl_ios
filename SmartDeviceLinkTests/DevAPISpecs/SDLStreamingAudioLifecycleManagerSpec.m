#import <Quick/Quick.h>
#import <Nimble/Nimble.h>
#import <OCMock/OCMock.h>


#import "SDLAudioStreamManager.h"
#import "SDLConfiguration.h"
#import "SDLControlFramePayloadAudioStartServiceAck.h"
#import "SDLDisplayCapabilities.h"
#import "SDLGlobals.h"
#import "SDLImageResolution.h"
#import "SDLOnHMIStatus.h"
#import "SDLProtocol.h"
#import "SDLRegisterAppInterfaceResponse.h"
#import "SDLRPCNotificationNotification.h"
#import "SDLRPCResponseNotification.h"
#import "SDLScreenParams.h"
#import "SDLStateMachine.h"
#import "SDLStreamingAudioLifecycleManager.h"
#import "SDLSystemCapabilityManager.h"
#import "SDLEncryptionConfiguration.h"
#import "SDLV2ProtocolHeader.h"
#import "SDLV2ProtocolMessage.h"
#import "SDLVehicleType.h"
#import "TestConnectionManager.h"


@interface SDLStreamingAudioLifecycleManager()

@property (weak, nonatomic) SDLProtocol *protocol;
@property (copy, nonatomic, nullable) NSString *connectedVehicleMake;
@property (nonatomic, strong, readwrite) SDLAudioStreamManager *audioTranscodingManager;

@end

QuickSpecBegin(SDLStreamingAudioLifecycleManagerSpec)

describe(@"the streaming audio manager", ^{
    __block SDLStreamingAudioLifecycleManager *streamingLifecycleManager = nil;
    __block SDLConfiguration *testConfig = nil;
    __block TestConnectionManager *testConnectionManager = nil;
    __block SDLAudioStreamManager *mockAudioStreamManager = nil;
    __block SDLSystemCapabilityManager *testSystemCapabilityManager = nil;

    __block void (^sendNotificationForHMILevel)(SDLHMILevel hmiLevel) = ^(SDLHMILevel hmiLevel) {
        SDLOnHMIStatus *hmiStatus = [[SDLOnHMIStatus alloc] init];
        hmiStatus.hmiLevel = hmiLevel;
        SDLRPCNotificationNotification *notification = [[SDLRPCNotificationNotification alloc] initWithName:SDLDidChangeHMIStatusNotification object:self rpcNotification:hmiStatus];
        [[NSNotificationCenter defaultCenter] postNotification:notification];

        [NSThread sleepForTimeInterval:0.3];
    };

    beforeEach(^{
        testConfig = OCMClassMock([SDLConfiguration class]);
        testConnectionManager = [[TestConnectionManager alloc] init];

        testSystemCapabilityManager = OCMClassMock([SDLSystemCapabilityManager class]);
        streamingLifecycleManager = [[SDLStreamingAudioLifecycleManager alloc] initWithConnectionManager:testConnectionManager configuration:testConfig systemCapabilityManager:testSystemCapabilityManager];
        mockAudioStreamManager = OCMClassMock([SDLAudioStreamManager class]);
        streamingLifecycleManager.audioTranscodingManager = mockAudioStreamManager;
    });

    it(@"should initialize properties", ^{
        expect(streamingLifecycleManager.audioTranscodingManager).toNot(beNil());
        expect(@(streamingLifecycleManager.isStreamingSupported)).to(equal(@NO));
        expect(@(streamingLifecycleManager.isAudioConnected)).to(equal(@NO));
        expect(@(streamingLifecycleManager.isAudioEncrypted)).to(equal(@NO));
        expect(@(streamingLifecycleManager.requestedEncryptionType)).to(equal(@(SDLStreamingEncryptionFlagNone)));
        expect(streamingLifecycleManager.currentAudioStreamState).to(equal(SDLAudioStreamManagerStateStopped));
    });

    describe(@"Getting isStreamingSupported", ^{
        it(@"should get the value from the system capability manager", ^{
            [streamingLifecycleManager isStreamingSupported];
            OCMVerify([testSystemCapabilityManager isCapabilitySupported:SDLSystemCapabilityTypeVideoStreaming]);
        });

        it(@"should return true by default if the system capability manager is nil", ^{
            streamingLifecycleManager = [[SDLStreamingAudioLifecycleManager alloc] initWithConnectionManager:testConnectionManager configuration:testConfig systemCapabilityManager:nil];
            expect(streamingLifecycleManager.isStreamingSupported).to(beTrue());
        });
    });

    describe(@"when started", ^{
        __block BOOL readyHandlerSuccess = NO;
        __block NSError *readyHandlerError = nil;
        __block SDLProtocol *protocolMock = OCMClassMock([SDLProtocol class]);

        beforeEach(^{
            readyHandlerSuccess = NO;
            readyHandlerError = nil;

            [streamingLifecycleManager startWithProtocol:protocolMock];
        });

        it(@"should be ready to stream", ^{
            expect(@(streamingLifecycleManager.isStreamingSupported)).to(equal(@NO));
            expect(@(streamingLifecycleManager.isAudioConnected)).to(equal(@NO));
            expect(@(streamingLifecycleManager.isAudioEncrypted)).to(equal(@NO));
            expect(streamingLifecycleManager.currentAudioStreamState).to(match(SDLAudioStreamManagerStateStopped));
        });

        describe(@"after receiving a register app interface response", ^{
            __block SDLRegisterAppInterfaceResponse *someRegisterAppInterfaceResponse = nil;
            __block SDLVehicleType *testVehicleType = nil;

            beforeEach(^{
                someRegisterAppInterfaceResponse = [[SDLRegisterAppInterfaceResponse alloc] init];
                testVehicleType = [[SDLVehicleType alloc] init];
                testVehicleType.make = @"TestVehicleType";
                someRegisterAppInterfaceResponse.vehicleType = testVehicleType;

                SDLRPCResponseNotification *notification = [[SDLRPCResponseNotification alloc] initWithName:SDLDidReceiveRegisterAppInterfaceResponse object:self rpcResponse:someRegisterAppInterfaceResponse];

                [[NSNotificationCenter defaultCenter] postNotification:notification];
                [NSThread sleepForTimeInterval:0.1];
            });

            it(@"should should save the connected vehicle make", ^{
                expect(streamingLifecycleManager.connectedVehicleMake).to(equal(testVehicleType.make));
            });
        });

        describe(@"if the app state is active", ^{
            __block id streamStub = nil;

            beforeEach(^{
                streamStub = OCMPartialMock(streamingLifecycleManager);

                OCMStub([streamStub isStreamingSupported]).andReturn(YES);

                [streamingLifecycleManager.appStateMachine setToState:SDLAppStateActive fromOldState:nil callEnterTransition:NO];
            });

            describe(@"and the streams are open", ^{
                beforeEach(^{
                    [streamingLifecycleManager.audioStreamStateMachine setToState:SDLAudioStreamManagerStateReady fromOldState:nil callEnterTransition:NO];
                });

                describe(@"and the hmi state is limited", ^{
                    beforeEach(^{
                        streamingLifecycleManager.hmiLevel = SDLHMILevelLimited;
                    });

                    describe(@"and the hmi state changes to", ^{
                        context(@"none", ^{
                            beforeEach(^{
                                sendNotificationForHMILevel(SDLHMILevelNone);
                            });

                            it(@"should close the streams", ^{
                                expect(streamingLifecycleManager.currentAudioStreamState).to(equal(SDLAudioStreamManagerStateShuttingDown));
                            });
                        });

                        context(@"background", ^{
                            beforeEach(^{
                                sendNotificationForHMILevel(SDLHMILevelBackground);
                            });

                            it(@"should close the stream", ^{
                                expect(streamingLifecycleManager.currentAudioStreamState).to(equal(SDLAudioStreamManagerStateShuttingDown));
                            });
                        });

                        context(@"limited", ^{
                            beforeEach(^{
                                sendNotificationForHMILevel(SDLHMILevelLimited);
                            });

                            it(@"should not close the stream", ^{
                                expect(streamingLifecycleManager.currentAudioStreamState).to(equal(SDLAudioStreamManagerStateReady));
                            });
                        });

                        context(@"full", ^{
                            beforeEach(^{
                                sendNotificationForHMILevel(SDLHMILevelFull);
                            });

                            it(@"should not close the stream", ^{
                                expect(streamingLifecycleManager.currentAudioStreamState).to(equal(SDLAudioStreamManagerStateReady));
                            });
                        });
                    });

                    describe(@"and the app state changes to", ^{
                        context(@"inactive", ^{
                            beforeEach(^{
                                [streamingLifecycleManager.appStateMachine setToState:SDLAppStateInactive fromOldState:nil callEnterTransition:YES];
                            });

                            it(@"should not close the stream", ^{
                                expect(streamingLifecycleManager.currentAudioStreamState).to(equal(SDLAudioStreamManagerStateReady));
                            });
                        });
                    });
                });

                describe(@"and the hmi state is full", ^{
                    beforeEach(^{
                        streamingLifecycleManager.hmiLevel = SDLHMILevelFull;
                    });

                    context(@"and hmi state changes to none", ^{
                        beforeEach(^{
                            sendNotificationForHMILevel(SDLHMILevelNone);
                        });

                        it(@"should close the streams", ^{
                            expect(streamingLifecycleManager.currentAudioStreamState).to(equal(SDLAudioStreamManagerStateShuttingDown));
                        });
                    });

                    context(@"and hmi state changes to background", ^{
                        beforeEach(^{
                            sendNotificationForHMILevel(SDLHMILevelBackground);
                        });

                        it(@"should close the stream", ^{
                            expect(streamingLifecycleManager.currentAudioStreamState).to(equal(SDLAudioStreamManagerStateShuttingDown));
                        });
                    });

                    context(@"and hmi state changes to limited", ^{
                        beforeEach(^{
                            sendNotificationForHMILevel(SDLHMILevelLimited);
                        });

                        it(@"should not close the stream", ^{
                            expect(streamingLifecycleManager.currentAudioStreamState).to(equal(SDLAudioStreamManagerStateReady));
                        });
                    });

                    context(@"and hmi state changes to full", ^{
                        beforeEach(^{
                            sendNotificationForHMILevel(SDLHMILevelFull);
                        });

                        it(@"should not close the stream", ^{
                            expect(streamingLifecycleManager.currentAudioStreamState).to(equal(SDLAudioStreamManagerStateReady));
                        });
                    });
                });
            });

            describe(@"and the streams are closed", ^{
                beforeEach(^{
                    [streamingLifecycleManager.audioStreamStateMachine setToState:SDLAudioStreamManagerStateStopped fromOldState:nil callEnterTransition:NO];
                });

                describe(@"and the hmi state is none", ^{
                    beforeEach(^{
                        streamingLifecycleManager.hmiLevel = SDLHMILevelNone;
                    });

                    context(@"and hmi state changes to none", ^{
                        beforeEach(^{
                            sendNotificationForHMILevel(SDLHMILevelNone);
                        });

                        it(@"should not start the stream", ^{
                            expect(streamingLifecycleManager.currentAudioStreamState).to(equal(SDLAudioStreamManagerStateStopped));
                        });
                    });

                    context(@"and hmi state changes to background", ^{
                        beforeEach(^{
                            sendNotificationForHMILevel(SDLHMILevelBackground);
                        });

                        it(@"should not start the stream", ^{
                            expect(streamingLifecycleManager.currentAudioStreamState).to(equal(SDLAudioStreamManagerStateStopped));
                        });
                    });

                    context(@"and hmi state changes to limited", ^{
                        beforeEach(^{
                            sendNotificationForHMILevel(SDLHMILevelLimited);
                        });

                        it(@"should start the streams", ^{
                            expect(streamingLifecycleManager.currentAudioStreamState).to(equal(SDLAudioStreamManagerStateStarting));
                        });
                    });

                    context(@"and hmi state changes to full", ^{
                        beforeEach(^{
                            sendNotificationForHMILevel(SDLHMILevelFull);
                        });

                        it(@"should start the streams", ^{
                            expect(streamingLifecycleManager.currentAudioStreamState).to(equal(SDLAudioStreamManagerStateStarting));
                        });
                    });
                });
            });
        });

        describe(@"after receiving an Audio Start ACK", ^{
            __block SDLProtocolHeader *testAudioHeader = nil;
            __block SDLProtocolMessage *testAudioMessage = nil;
            __block SDLControlFramePayloadAudioStartServiceAck *testAudioStartServicePayload = nil;
            __block int64_t testMTU = 786579;

            beforeEach(^{
                [streamingLifecycleManager.audioStreamStateMachine setToState:SDLAudioStreamManagerStateStarting fromOldState:nil callEnterTransition:NO];

                testAudioHeader = [[SDLV2ProtocolHeader alloc] initWithVersion:5];
                testAudioHeader.frameType = SDLFrameTypeSingle;
                testAudioHeader.frameData = SDLFrameInfoStartServiceACK;
                testAudioHeader.encrypted = YES;
                testAudioHeader.serviceType = SDLServiceTypeAudio;

                testAudioStartServicePayload = [[SDLControlFramePayloadAudioStartServiceAck alloc] initWithMTU:testMTU];
                testAudioMessage = [[SDLV2ProtocolMessage alloc] initWithHeader:testAudioHeader andPayload:testAudioStartServicePayload.data];
                [streamingLifecycleManager handleProtocolStartServiceACKMessage:testAudioMessage];
            });

            it(@"should have set all the right properties", ^{
                expect([[SDLGlobals sharedGlobals] mtuSizeForServiceType:SDLServiceTypeAudio]).to(equal(testMTU));
                expect(streamingLifecycleManager.audioEncrypted).to(equal(YES));
                expect(streamingLifecycleManager.currentAudioStreamState).to(equal(SDLAudioStreamManagerStateReady));
            });
        });

        describe(@"after receiving an Audio Start NAK", ^{
            __block SDLProtocolHeader *testAudioHeader = nil;
            __block SDLProtocolMessage *testAudioMessage = nil;

            beforeEach(^{
                [streamingLifecycleManager.audioStreamStateMachine setToState:SDLAudioStreamManagerStateStarting fromOldState:nil callEnterTransition:NO];

                testAudioHeader = [[SDLV2ProtocolHeader alloc] initWithVersion:5];
                testAudioHeader.frameType = SDLFrameTypeSingle;
                testAudioHeader.frameData = SDLFrameInfoStartServiceNACK;
                testAudioHeader.encrypted = NO;
                testAudioHeader.serviceType = SDLServiceTypeAudio;

                testAudioMessage = [[SDLV2ProtocolMessage alloc] initWithHeader:testAudioHeader andPayload:nil];
                [streamingLifecycleManager handleProtocolEndServiceACKMessage:testAudioMessage];
            });

            it(@"should have set all the right properties", ^{
                expect(streamingLifecycleManager.currentAudioStreamState).to(equal(SDLAudioStreamManagerStateStopped));
            });
        });

        describe(@"after receiving a audio end ACK", ^{
            __block SDLProtocolHeader *testAudioHeader = nil;
            __block SDLProtocolMessage *testAudioMessage = nil;

            beforeEach(^{
                [streamingLifecycleManager.audioStreamStateMachine setToState:SDLAudioStreamManagerStateStarting fromOldState:nil callEnterTransition:NO];

                testAudioHeader = [[SDLV2ProtocolHeader alloc] initWithVersion:5];
                testAudioHeader.frameType = SDLFrameTypeSingle;
                testAudioHeader.frameData = SDLFrameInfoEndServiceACK;
                testAudioHeader.encrypted = NO;
                testAudioHeader.serviceType = SDLServiceTypeAudio;

                testAudioMessage = [[SDLV2ProtocolMessage alloc] initWithHeader:testAudioHeader andPayload:nil];
                [streamingLifecycleManager handleProtocolEndServiceACKMessage:testAudioMessage];
            });

            it(@"should have set all the right properties", ^{
                expect(streamingLifecycleManager.currentAudioStreamState).to(equal(SDLAudioStreamManagerStateStopped));
            });
        });

        describe(@"after receiving a audio end NAK", ^{
            __block SDLProtocolHeader *testAudioHeader = nil;
            __block SDLProtocolMessage *testAudioMessage = nil;

            beforeEach(^{
                [streamingLifecycleManager.audioStreamStateMachine setToState:SDLAudioStreamManagerStateStarting fromOldState:nil callEnterTransition:NO];

                testAudioHeader = [[SDLV2ProtocolHeader alloc] initWithVersion:5];
                testAudioHeader.frameType = SDLFrameTypeSingle;
                testAudioHeader.frameData = SDLFrameInfoEndServiceNACK;
                testAudioHeader.encrypted = NO;
                testAudioHeader.serviceType = SDLServiceTypeAudio;

                testAudioMessage = [[SDLV2ProtocolMessage alloc] initWithHeader:testAudioHeader andPayload:nil];
                [streamingLifecycleManager handleProtocolEndServiceNAKMessage:testAudioMessage];
            });

            it(@"should have set all the right properties", ^{
                expect(streamingLifecycleManager.currentAudioStreamState).to(equal(SDLAudioStreamManagerStateStopped));
            });
        });
    });

    describe(@"attempting to stop the manager", ^{
        context(@"when the manager is READY", ^{
            beforeEach(^{
                [streamingLifecycleManager.audioStreamStateMachine setToState:SDLAudioStreamManagerStateReady fromOldState:nil callEnterTransition:NO];
                [streamingLifecycleManager stop];
            });

            it(@"should transition to the stopped state and reset the saved properties", ^{
                expect(streamingLifecycleManager.currentAudioStreamState).to(equal(SDLAudioStreamManagerStateStopped));

                expect(streamingLifecycleManager.protocol).to(beNil());
                expect(streamingLifecycleManager.hmiLevel).to(equal(SDLHMILevelNone));
                expect(streamingLifecycleManager.connectedVehicleMake).to(beNil());
                OCMVerify([mockAudioStreamManager stop]);

            });
        });

        context(@"when the manager is STOPPED", ^{
            beforeEach(^{
                [streamingLifecycleManager.audioStreamStateMachine setToState:SDLAudioStreamManagerStateStopped fromOldState:nil callEnterTransition:NO];
                [streamingLifecycleManager stop];
            });

            it(@"should stay in the stopped state and reset the saved properties", ^{
                expect(streamingLifecycleManager.currentAudioStreamState).to(equal(SDLAudioStreamManagerStateStopped));

                expect(streamingLifecycleManager.protocol).to(beNil());
                expect(streamingLifecycleManager.hmiLevel).to(equal(SDLHMILevelNone));
                expect(streamingLifecycleManager.connectedVehicleMake).to(beNil());
                OCMVerify([mockAudioStreamManager stop]);
            });
        });
    });

    describe(@"starting the manager when it's STOPPED", ^{
        __block SDLProtocol *protocolMock = OCMClassMock([SDLProtocol class]);
        __block BOOL handlerCalled = nil;

        beforeEach(^{
            handlerCalled = NO;
            [streamingLifecycleManager startWithProtocol:protocolMock];
        });

        context(@"when stopping the audio service due to a secondary transport shutdown", ^{
            beforeEach(^{
                [streamingLifecycleManager.audioStreamStateMachine setToState:SDLAudioStreamManagerStateReady fromOldState:nil callEnterTransition:NO];
                [streamingLifecycleManager endAudioServiceWithCompletionHandler:^ {
                    handlerCalled = YES;
                }];
            });

            it(@"should reset the audio stream manger and send an end audio service control frame", ^{
                OCMVerify([mockAudioStreamManager stop]);
                OCMVerify([protocolMock endServiceWithType:SDLServiceTypeAudio]);

            });

            context(@"when the end audio service ACKs", ^{
                __block SDLProtocolHeader *testAudioHeader = nil;
                __block SDLProtocolMessage *testAudioMessage = nil;

                beforeEach(^{
                    testAudioHeader = [[SDLV2ProtocolHeader alloc] initWithVersion:5];
                    testAudioHeader.frameType = SDLFrameTypeSingle;
                    testAudioHeader.frameData = SDLFrameInfoEndServiceACK;
                    testAudioHeader.encrypted = NO;
                    testAudioHeader.serviceType = SDLServiceTypeAudio;
                    testAudioMessage = [[SDLV2ProtocolMessage alloc] initWithHeader:testAudioHeader andPayload:nil];

                    [streamingLifecycleManager handleProtocolEndServiceACKMessage:testAudioMessage];
                });

                it(@"should call the handler", ^{
                    expect(handlerCalled).to(beTrue());
                });
            });

            context(@"when the end audio service NAKs", ^{
                __block SDLProtocolHeader *testAudioHeader = nil;
                __block SDLProtocolMessage *testAudioMessage = nil;

                beforeEach(^{
                    testAudioHeader = [[SDLV2ProtocolHeader alloc] initWithVersion:5];
                    testAudioHeader.frameType = SDLFrameTypeSingle;
                    testAudioHeader.frameData = SDLFrameInfoEndServiceNACK;
                    testAudioHeader.encrypted = NO;
                    testAudioHeader.serviceType = SDLServiceTypeAudio;
                    testAudioMessage = [[SDLV2ProtocolMessage alloc] initWithHeader:testAudioHeader andPayload:nil];

                    [streamingLifecycleManager handleProtocolEndServiceNAKMessage:testAudioMessage];
                });

                it(@"should call the handler", ^{
                    expect(handlerCalled).to(beTrue());
                });
            });
        });
    });
});

QuickSpecEnd
