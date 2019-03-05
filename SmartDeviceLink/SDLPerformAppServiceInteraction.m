//
//  SDLPerformAppServiceInteraction.m
//  SmartDeviceLink
//
//  Created by Nicole on 2/6/19.
//  Copyright © 2019 smartdevicelink. All rights reserved.
//

#import "SDLPerformAppServiceInteraction.h"

#import "NSMutableDictionary+Store.h"
#import "SDLNames.h"
#import "SDLRPCFunctionNames.h"


NS_ASSUME_NONNULL_BEGIN

@implementation SDLPerformAppServiceInteraction

- (instancetype)init {
    if (self = [super initWithName:SDLRPCFunctionNamePerformAppServiceInteraction]) {
    }
    return self;
}

- (instancetype)initWithServiceUri:(NSString *)serviceUri serviceID:(NSString *)serviceID originApp:(NSString *)originApp {
    self = [self init];
    if (!self) {
        return nil;
    }

    self.serviceUri = serviceUri;
    self.serviceID = serviceID;
    self.originApp = originApp;

    return self;
}

- (instancetype)initWithServiceUri:(NSString *)serviceUri serviceID:(NSString *)serviceID originApp:(NSString *)originApp requestServiceActive:(BOOL)requestServiceActive {
    self = [self initWithServiceUri:serviceUri serviceID:serviceID originApp:originApp];
    if (!self) {
        return nil;
    }

    self.requestServiceActive = @(requestServiceActive);

    return self;
}

- (void)setServiceUri:(NSString *)serviceUri {
    [parameters sdl_setObject:serviceUri forName:SDLNameServiceUri];
}

- (NSString *)serviceUri {
    return [parameters sdl_objectForName:SDLNameServiceUri];
}

- (void)setServiceID:(NSString *)serviceID {
    [parameters sdl_setObject:serviceID forName:SDLNameServiceID];
}

- (NSString *)serviceID {
    return [parameters sdl_objectForName:SDLNameServiceID];
}

- (void)setOriginApp:(NSString *)originApp {
    [parameters sdl_setObject:originApp forName:SDLNameOriginApp];
}

- (NSString *)originApp {
    return [parameters sdl_objectForName:SDLNameOriginApp];
}

- (void)setRequestServiceActive:(nullable NSNumber<SDLBool> *)requestServiceActive {
    [parameters sdl_setObject:requestServiceActive forName:SDLNameRequestServiceActive];
}

- (nullable NSNumber<SDLBool> *)requestServiceActive {
    return [parameters sdl_objectForName:SDLNameRequestServiceActive];
}
@end

NS_ASSUME_NONNULL_END
