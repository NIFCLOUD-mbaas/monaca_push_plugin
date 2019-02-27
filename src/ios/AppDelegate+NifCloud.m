//
//  AppDelegate+NifCloud.m
//  Copyright 2017-2018 FUJITSU CLOUD TECHNOLOGIES LIMITED All Rights Reserved.
//
//

#import "AppDelegate+NifCloud.h"
#import "NcmbPushNotification.h"
#import <objc/runtime.h>

@implementation AppDelegate (NifCloud)

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
    [NcmbPushNotification setupNCMB];

    // check if received push notification
    NSDictionary *launchOptions = [notification userInfo];

    if (launchOptions != nil) {
        NSDictionary *userInfo = [launchOptions objectForKey: @"UIApplicationLaunchOptionsRemoteNotificationKey"];

        if (userInfo != nil){
            NcmbPushNotification *ncmb = [self getNcmbPushNotification];

            if (ncmb != nil) {
                [ncmb addJson:[userInfo mutableCopy] withAppIsActive:NO];
            }

            [NcmbPushNotification trackAppOpenedWithLaunchOptions:launchOptions];
            [NcmbPushNotification handleRichPush:userInfo];
        }
    }
    if ([[NSProcessInfo processInfo] isOperatingSystemAtLeastVersion:(NSOperatingSystemVersion){10, 0, 0}]){
        UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
        center.delegate = self;
    }
}

- (void) registerForRemoteNotifications
{
    [NcmbPushNotification setupNCMB];

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
                                      NcmbPushNotification *ncmb = [self getNcmbPushNotification];
                                      if (ncmb != nil) {
                                          [ncmb failedToRegisterAPNS];
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
    NcmbPushNotification *ncmb = [self getNcmbPushNotification];
    
    if (ncmb != nil) {
        [ncmb setDeviceTokenAPNS:deviceToken];
    }
}

/**
 * Fail to register remote notification.
 */
- (void)application:(UIApplication*)application didFailToRegisterForRemoteNotificationsWithError:(NSError*)err{
    NcmbPushNotification *ncmb = [self getNcmbPushNotification];
    
    if (ncmb != nil) {
        [ncmb failedToRegisterAPNS];
    }
}

/**
 * Did receive remote notification.
 */
- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
    NcmbPushNotification *ncmb = [self getNcmbPushNotification];
    NSMutableDictionary* receivedPushInfo = [userInfo mutableCopy];
    
    if (ncmb != nil) {
        [ncmb addJson:receivedPushInfo withAppIsActive:(application.applicationState == UIApplicationStateActive)];
    }
    
    [NcmbPushNotification trackAppOpenedWithRemoteNotificationPayload:userInfo];
    [NcmbPushNotification handleRichPush:userInfo];
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
    NcmbPushNotification* ncmb = [self getNcmbPushNotification];
    
    if (ncmb != nil) {
        [ncmb sendAllJsons];
    }
}

/**
 * Get ncmb push notification instance.
 */
- (NcmbPushNotification*)getNcmbPushNotification {
    id instance = [self.viewController.pluginObjects objectForKey:@"NcmbPushNotification"];
    
    if ([instance isKindOfClass:[NcmbPushNotification class]]) {
        return (NcmbPushNotification*)instance;
    }

    return nil;
}
@end
