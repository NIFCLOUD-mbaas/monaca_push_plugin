//
//  AppDelegate+NiftyCloud.m
//  Copyright 2017 FUJITSU CLOUD TECHNOLOGIES LIMITED All Rights Reserved.
//
//

#import "AppDelegate+NiftyCloud.h"
#import "NiftyPushNotification.h"
#import <objc/runtime.h>

@implementation AppDelegate (NiftyCloud)

/**
 * Load.
 */
+ (void)load {
    Method original = class_getInstanceMethod(self, @selector(init));
    Method swizzled = class_getInstanceMethod(self, @selector(swizzledInit));
    method_exchangeImplementations(original, swizzled);
}

/**
 * Custome initializer.
 */
- (AppDelegate *)swizzledInit {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(setupNotification:) name:@"UIApplicationDidFinishLaunchingNotification" object:nil];
    return [self swizzledInit];
}

/**
 * Set up notification.
 * Execute after didFinishLaunchingWithOptions.
 */
- (void)setupNotification:(NSNotification *)notification {
    [NiftyPushNotification setupNCMB];
    UIApplication const *application = [UIApplication sharedApplication];
    
#ifdef __IPHONE_8_0
    if(NSFoundationVersionNumber > NSFoundationVersionNumber_iOS_7_1) {
        UIUserNotificationType types = UIUserNotificationTypeAlert | UIUserNotificationTypeBadge | UIUserNotificationTypeSound;
        UIUserNotificationSettings *setting = [UIUserNotificationSettings settingsForTypes:types categories:nil];
        [application registerUserNotificationSettings:setting];
        [application registerForRemoteNotifications];
    } else {
        [application registerForRemoteNotificationTypes: (UIRemoteNotificationTypeAlert | UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound)];
    }
#else
    [application registerForRemoteNotificationTypes: (UIRemoteNotificationTypeAlert | UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound)];
#endif
    
    // check if received push notification
    NSDictionary *launchOptions = [notification userInfo];
    
    if (launchOptions != nil) {
        NSDictionary *userInfo = [launchOptions objectForKey: @"UIApplicationLaunchOptionsRemoteNotificationKey"];
        
        if (userInfo != nil){
            NiftyPushNotification *nifty = [self getNiftyPushNotification];
            
            if (nifty != nil) {
                [nifty addJson:[userInfo mutableCopy] withAppIsActive:NO];
            }
            
            [NiftyPushNotification trackAppOpenedWithLaunchOptions:launchOptions];
            [NiftyPushNotification handleRichPush:userInfo];
        }
    }
}

#ifdef __IPHONE_8_0
/**
 * Did register user notifiation settings.
 */
- (void)application:(UIApplication *)application didRegisterUserNotificationSettings:(UIUserNotificationSettings *)notificationSettings {
    
}
#endif

/**
 * Success to regiter remote notification.
 */
- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    NiftyPushNotification *nifty = [self getNiftyPushNotification];
    
    if (nifty != nil) {
        [nifty setDeviceTokenAPNS:deviceToken];
    }
}

/**
 * Fail to register remote notification.
 */
- (void)application:(UIApplication*)application didFailToRegisterForRemoteNotificationsWithError:(NSError*)err{
    NiftyPushNotification *nifty = [self getNiftyPushNotification];
    
    if (nifty != nil) {
        [nifty failedToRegisterAPNS];
    }
}

/**
 * Did receive remote notification.
 */
- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
    NiftyPushNotification *nifty = [self getNiftyPushNotification];
    NSMutableDictionary* receivedPushInfo = [userInfo mutableCopy];
    
    if (nifty != nil) {
        [nifty addJson:receivedPushInfo withAppIsActive:(application.applicationState == UIApplicationStateActive)];
    }
    
    [NiftyPushNotification trackAppOpenedWithRemoteNotificationPayload:userInfo];
    [NiftyPushNotification handleRichPush:userInfo];
}

/**
 * Did become active.
 */
- (void)applicationDidBecomeActive:(UIApplication *)application {
    application.applicationIconBadgeNumber = 0;
    NiftyPushNotification* nifty = [self getNiftyPushNotification];
    
    if (nifty != nil) {
        [nifty sendAllJsons];
    }
}

/**
 * Get nifty push notification instance.
 */
- (NiftyPushNotification*)getNiftyPushNotification {
    id instance = [self.viewController.pluginObjects objectForKey:@"NiftyPushNotification"];
    
    if ([instance isKindOfClass:[NiftyPushNotification class]]) {
        return (NiftyPushNotification*)instance;
    }

    return nil;
}
@end
