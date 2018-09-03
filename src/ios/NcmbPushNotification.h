//
//  NcmbPushNotification.h
//  Copyright 2017-2018 FUJITSU CLOUD TECHNOLOGIES LIMITED All Rights Reserved.
//

#import <Cordova/CDVPlugin.h>
#import "NcmbQueue.h"

@interface NcmbPushNotification : CDVPlugin {
    NSString* _setDeviceTokenCallbackId;
    NSString* _pushReceivedCallbackId;
    NcmbQueue* _queue;
    BOOL _isFailedToRegisterAPNS;
    BOOL _webViewLoadFinished;
}

// call from AppDelegate
+ (BOOL) hasDeviceTokenAPNS;
+ (void) setupNCMB;
+ (void) trackAppOpenedWithLaunchOptions:(NSDictionary*)launchOptions;
+ (void) trackAppOpenedWithRemoteNotificationPayload:(NSDictionary*)userInfo;
+ (void) handleRichPush:(NSDictionary *)userInfo;

// call from AppDelegate
- (void) setDeviceTokenAPNS: (NSData*)deviceToken;
- (void) failedToRegisterAPNS;
- (void) addJson: (NSDictionary*)json withAppIsActive:(BOOL)isActive;
- (void) sendAllJsons;

// call from JS
- (void) setDeviceToken: (CDVInvokedUrlCommand*)command;
- (void) getInstallationId: (CDVInvokedUrlCommand*)command;
- (void) setReceiptStatus: (CDVInvokedUrlCommand*)command;
- (void) getReceiptStatus: (CDVInvokedUrlCommand*)command;
- (void) pushReceived: (CDVInvokedUrlCommand*)command;
@end
