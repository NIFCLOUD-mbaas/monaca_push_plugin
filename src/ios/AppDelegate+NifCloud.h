//
//  AppDelegate+NifCloud.h
//  Copyright 2017-2023 FUJITSU CLOUD TECHNOLOGIES LIMITED All Rights Reserved.
//


#import "AppDelegate.h"
#import <UserNotifications/UserNotifications.h>

@interface AppDelegate (NifCloud) <UNUserNotificationCenterDelegate>
- (void) registerForRemoteNotifications;
@end
