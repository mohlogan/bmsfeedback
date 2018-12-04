//
//  WLFeedback.h
//  WorklightStaticLibProject
//
//  Created by Mohanraj Loganathan on 27/06/18.
//  Copyright © 2018 IBM. All rights reserved.
//

//#ifndef WLFeedback_h
//#define WLFeedback_h
#import <Foundation/Foundation.h>

@interface WLFeedback : NSObject

+ (WLFeedback *) sharedInstance;

/**
 Trigger Feedback mode
 */
- (int)triggerFeedbackMode:(NSString*)userId withSessionId:(NSString*)sessionId withDeviceId:(NSString*)deviceId withUrl: (NSString*) url withApiKey: (NSString*)apiKey withAppName: (NSString*) appName withMethodName: (NSString*) methodName;

- (void)send:(NSString *)value;

@end
//#endif /* WLFeedback_h */
