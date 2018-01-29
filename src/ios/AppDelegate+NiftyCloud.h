//
//  AppDelegate+NiftyCloud.h
//  Copyright 2017 FUJITSU CLOUD TECHNOLOGIES LIMITED All Rights Reserved.
//


#import "AppDelegate.h"
#import <UserNotifications/UserNotifications.h>

@interface AppDelegate (NiftyCloud) <UNUserNotificationCenterDelegate>
- (void) registerForRemoteNotifications;
@end
