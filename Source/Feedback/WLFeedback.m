//
//  WLFeedback.m
//  IBMMobileFirstPlatformFoundationVnext
//
//  Created by Mohanraj Loganathan on 26/06/18.
//  Copyright © 2018 IBM. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WLFeedback.h"
#import <BMSFeedback/BMSFeedback-Swift.h>

@implementation WLFeedback

+ (WLFeedback *)sharedInstance {
    static WLFeedback *sharedSingleton;
    
    @synchronized(self) {
        if (!sharedSingleton) {
            sharedSingleton = [[WLFeedback alloc] init];
        }
        
        return sharedSingleton;
    }
}

- (instancetype)init {
    self = [super init];
    
    return self;
}

- (int)triggerFeedbackMode:(NSString*)userId withSessionId:(NSString*)sessionId withDeviceId:(NSString*)deviceId withUrl: (NSString*) url withApiKey: (NSString*)apiKey withAppName: (NSString*) appName withMethodName: (NSString*) methodName{
    return [[[Feedback alloc] init] invokeFeedback: userId withSessionId: sessionId withDeviceId: deviceId withUrl: url withApiKey: apiKey withAppName: appName withMethodName: methodName];
}

- (void)send:(NSString *)value {
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    @try {
        Class wlaClass = NSClassFromString(@"WLAnalytics");
        if (wlaClass) {
            SEL sel = NSSelectorFromString(@"sendFeedbackFile:");
            [[[wlaClass alloc] init]performSelector:sel withObject:value];
        } else {
            NSLog(@"[DEBUG] [FEEDBACK]", @"WLFeedback: IBMMobileFirstPlatformFoundation.WLAnalytics Class not found" );
        }
    }
    @catch (NSException * e) { }
}

@end

