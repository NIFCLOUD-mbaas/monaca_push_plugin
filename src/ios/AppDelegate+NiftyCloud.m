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

- (void) registerForRemoteNotifications
{
    [NiftyPushNotification setupNCMB];

    UIApplication const *application = [UIApplication sharedApplication];

    if ([[NSProcessInfo processInfo] isOperatingSystemAtLeastVersion:(NSOperatingSystemVersion){10, 0, 0}]){
        //iOS10以上での、DeviceToken要求方法
        UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
        center.delegate = self;
        [center requestAuthorizationWithOptions:(UNAuthorizationOptionAlert |
                                                 UNAuthorizationOptionBadge |
                                                 UNAuthorizationOptionSound)
                              completionHandler:^(BOOL granted, NSError * _Nullable error) {
                                  if (error) {
                                      return;
                                  }
                                  if (granted) {
                                      //通知を許可にした場合DeviceTokenを要求
                                      dispatch_async(dispatch_get_main_queue(), ^{
                                          [application registerForRemoteNotifications];
                                      });
                                  } else {
                                      NiftyPushNotification *nifty = [self getNiftyPushNotification];
                                      if (nifty != nil) {
                                          [nifty failedToRegisterAPNS];
                                      }
                                  }
                              }];
    } else if ([[NSProcessInfo processInfo] isOperatingSystemAtLeastVersion:(NSOperatingSystemVersion){8, 0, 0}]){
        //iOS10未満での、DeviceToken要求方法
        //通知のタイプを設定したsettingを用意
        UIUserNotificationType type = UIUserNotificationTypeAlert | UIUserNotificationTypeBadge | UIUserNotificationTypeSound;
        UIUserNotificationSettings *setting=  [UIUserNotificationSettings settingsForTypes:type categories:nil];
        //通知のタイプを設定
        [application registerUserNotificationSettings:setting];
        //DeviceTokenを要求
        [application registerForRemoteNotifications];
    } else {
        //iOS8未満での、DeviceToken要求方法
        [application registerForRemoteNotificationTypes:
         (UIRemoteNotificationTypeAlert |
          UIRemoteNotificationTypeBadge |
          UIRemoteNotificationTypeSound)];
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
 * Did receive remote notification on ios 10
 */
- (void)userNotificationCenter:(UNUserNotificationCenter* )center willPresentNotification:(UNNotification* )notification withCompletionHandler:(void (^)(UNNotificationPresentationOptions options))completionHandler {
    
    completionHandler(UNNotificationPresentationOptionAlert | UNNotificationPresentationOptionBadge | UNNotificationPresentationOptionSound);
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
