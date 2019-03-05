//  SDLEndAudioPassThruResponse.m
//


#import "SDLEndAudioPassThruResponse.h"

#import "NSMutableDictionary+Store.h"
#import "SDLNames.h"
#import "SDLRPCFunctionNames.h"

NS_ASSUME_NONNULL_BEGIN

@implementation SDLEndAudioPassThruResponse

- (instancetype)init {
    if (self = [super initWithName:SDLRPCFunctionNameEndAudioPassThru]) {
    }
    return self;
}

@end

NS_ASSUME_NONNULL_END
