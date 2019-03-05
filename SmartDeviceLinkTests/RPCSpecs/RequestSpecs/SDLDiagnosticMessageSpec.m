//
//  SDLDiagnosticMessageSpec.m
//  SmartDeviceLink


#import <Foundation/Foundation.h>

#import <Quick/Quick.h>
#import <Nimble/Nimble.h>

#import "SDLDiagnosticMessage.h"
#import "SDLNames.h"
#import "SDLRPCFunctionNames.h"

QuickSpecBegin(SDLDiagnosticMessageSpec)

describe(@"Getter/Setter Tests", ^ {
    it(@"Should set and get correctly", ^ {
        SDLDiagnosticMessage* testRequest = [[SDLDiagnosticMessage alloc] init];
        
		testRequest.targetID = @3562;
		testRequest.messageLength = @55555;
		testRequest.messageData = [@[@1, @4, @16, @64] mutableCopy];

		expect(testRequest.targetID).to(equal(@3562));
		expect(testRequest.messageLength).to(equal(@55555));
		expect(testRequest.messageData).to(equal([@[@1, @4, @16, @64] mutableCopy]));
    });
    
    it(@"Should get correctly when initialized", ^ {
        NSMutableDictionary<NSString *, id> *dict = [@{SDLNameRequest:
                                                           @{SDLNameParameters:
                                                                 @{SDLNameTargetId:@3562,
                                                                   SDLNameMessageLength:@55555,
                                                                   SDLNameMessageData:[@[@1, @4, @16, @64] mutableCopy]},
                                                             SDLNameOperationName:SDLRPCFunctionNameDiagnosticMessage}} mutableCopy];
        SDLDiagnosticMessage* testRequest = [[SDLDiagnosticMessage alloc] initWithDictionary:dict];
        
        expect(testRequest.targetID).to(equal(@3562));
        expect(testRequest.messageLength).to(equal(@55555));
        expect(testRequest.messageData).to(equal([@[@1, @4, @16, @64] mutableCopy]));
    });

    it(@"Should return nil if not set", ^ {
        SDLDiagnosticMessage* testRequest = [[SDLDiagnosticMessage alloc] init];
        
		expect(testRequest.targetID).to(beNil());
		expect(testRequest.messageLength).to(beNil());
		expect(testRequest.messageData).to(beNil());
	});
});

QuickSpecEnd
