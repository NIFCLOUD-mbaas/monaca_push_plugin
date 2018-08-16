//
//  NcmbPushNotification.m
//  Copyright 2017-2018 FUJITSU CLOUD TECHNOLOGIES LIMITED All Rights Reserved.
//

#import "AppDelegate+NifCloud.h"
#import "NcmbPushNotification.h"
#import "NCMB/NCMB.h"

@implementation NcmbPushNotification
static NSString *const kNcmbPushReceiptKey     = @"kNcmbPushReceiptStatus";
static NSString* const kNcmbPushAppKey         = @"APP_KEY";
static NSString* const kNcmbPushClientKey      = @"CLIENT_KEY";
static NSString* const kNcmbPushDeviceTokenKey = @"DEVICE_TOKEN";

static NSString* const kNcmbPushErrorMessageFailedToRegisterAPNS = @"Failed to register APNS.";
static NSString* const kNcmbPushErrorMessageInvalidParams = @"Parameters are invalid.";
static NSString* const kNcmbPushErrorMessageNoDeviceToken = @"Device Token does not exist.";
static NSString* const kNcmbPushErrorMessageFailedToSave  = @"installation save error.";
static NSString* const kNcmbPushErrorMessageRecoveryError = @"installation recovery error.";

static NSString* const kNcmbPushErrorCodeFailedToRegisterAPNS = @"EP000001";
static NSString* const kNcmbPushErrorCodeInvalidParams        = @"EP000002";

static BOOL hasSetup = NO;

/**
 * Has device token (APNS) in storage or not.
 */
+ (BOOL) hasDeviceTokenAPNS {
    return [[self class] getDeviceTokenAPNS] != nil;
}

/**
 * Get device token (APNS) from storage.
 */
+ (NSData*) getDeviceTokenAPNS {
    return [[NSUserDefaults standardUserDefaults] objectForKey:kNcmbPushDeviceTokenKey];
}

/**
 * Is receipt status ok or not.
 */
+ (BOOL) isReceiptStatusOk {
    return [[NSUserDefaults standardUserDefaults] boolForKey:kNcmbPushReceiptKey];
}

/**
 * Get application key from storage.
 */
+ (NSString*) getAppKey {
    return [[NSUserDefaults standardUserDefaults]objectForKey:kNcmbPushAppKey];
}

/**
 * Get client key from storage.
 */
+ (NSString*) getClientKey {
    return [[NSUserDefaults standardUserDefaults]objectForKey:kNcmbPushClientKey];
}

/**
 * Setup NCMB with application key and client key.
 */
+ (void) setupNCMB {
    NSString *appKey = [[self class] getAppKey];
    NSString *clientKey = [[self class] getClientKey];

    if (appKey == nil || clientKey == nil) {
        return;
    }

    [NCMB setApplicationKey:appKey clientKey:clientKey];
    hasSetup = YES;
}

/**
 * Track app opened (used in didFinishLaunchingNotification).
 */
+ (void) trackAppOpenedWithLaunchOptions:(NSDictionary*)launchOptions {
    if (!hasSetup) {
        return;
    }

    if ([NcmbPushNotification isReceiptStatusOk]) {
        [NCMBAnalytics trackAppOpenedWithLaunchOptions:launchOptions];
    }
}

/**
 * Track app opend (used in didReceiveRemoteNotification).
 */
+ (void) trackAppOpenedWithRemoteNotificationPayload:(NSDictionary*)userInfo {
    if (!hasSetup) {
        return;
    }

    if ([NcmbPushNotification isReceiptStatusOk]) {
        [NCMBAnalytics trackAppOpenedWithRemoteNotificationPayload:userInfo];
    }
}

/**
 * Handle rich push (wrapper method of MCMBPush.handleRichPush).
 */
+ (void) handleRichPush:(NSDictionary *)userInfo {
    if (!hasSetup) {
        return;
    }

    [NCMBPush handleRichPush:userInfo];
}

#pragma mark - Custom Plugin Loading

/**
 * Initialize thie plugin.
 */
- (void) pluginInitialize {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(watchPageLoadStart) name:CDVPluginResetNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(watchPageLoadFinish) name:CDVPageDidLoadNotification object:nil];
    _queue = [[NcmbQueue alloc] init];
    _isFailedToRegisterAPNS = NO;
}

/**
 * Watch page load start callback.
 */
- (void) watchPageLoadStart {
    _webViewLoadFinished = NO;
}

/**
 * Watch page load finish callback.
 */
- (void) watchPageLoadFinish {
    _webViewLoadFinished = YES;
    [self sendAllJsons];
}

#pragma mark - Set DeviceToken

/**
 * Set application key and client key (cordova API).
 */
- (void) setDeviceToken:(CDVInvokedUrlCommand*)command {
    _setDeviceTokenCallbackId = command.callbackId;

    if (![self validateInputParameters:command.arguments]) {
        [self callSetDeviceTokenErrorOnUiThread:kNcmbPushErrorCodeInvalidParams message: kNcmbPushErrorMessageInvalidParams];
        return;
    }

    NSString* appKey    = [command.arguments objectAtIndex:0];
    NSString* clientKey = [command.arguments objectAtIndex:1];
    [[NSUserDefaults standardUserDefaults] setObject:appKey forKey:kNcmbPushAppKey];
    [[NSUserDefaults standardUserDefaults] setObject:clientKey forKey:kNcmbPushClientKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [self installWithAppKey:appKey clientKey:clientKey deviceToken:[[self class] getDeviceTokenAPNS]];

    if (_isFailedToRegisterAPNS) {
        _isFailedToRegisterAPNS = NO;
        [self callSetDeviceTokenErrorOnUiThread:kNcmbPushErrorCodeFailedToRegisterAPNS message: kNcmbPushErrorMessageFailedToRegisterAPNS];
    }
}

- (BOOL)validateInputParameters:(NSArray*)params {
    if ([params count] < 2) {
        return false;
    } else if (![params objectAtIndex:0] || ![[params objectAtIndex:0] isKindOfClass:[NSString class]]) {
        return false;
    } else if (![params objectAtIndex:1] || ![[params objectAtIndex:1] isKindOfClass:[NSString class]]) {
        return false;
    } else {
        return true;
    }
}

- (void)callSetDeviceTokenSuccess {
    if (_setDeviceTokenCallbackId != nil) {
        CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
        [self.commandDelegate sendPluginResult:result callbackId:_setDeviceTokenCallbackId];
        _setDeviceTokenCallbackId = nil;
    }
}

- (void)callSetDeviceTokenSuccessOnUiThread {
    [self performSelectorOnMainThread:@selector(callSetDeviceTokenSuccess) withObject:nil waitUntilDone:NO];
}

- (void)callSetDeviceTokenError:(NSDictionary*)json {
    if (_setDeviceTokenCallbackId != nil) {
        CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsDictionary:json];
        [self.commandDelegate sendPluginResult:result callbackId:_setDeviceTokenCallbackId];
        _setDeviceTokenCallbackId = nil;
    }
}

- (void)callSetDeviceTokenErrorOnUiThread:(NSString*)code message:(NSString*)message {
    NSDictionary *json = [NSDictionary dictionaryWithObjectsAndKeys:
                          code, @"code",
                          message, @"message",
                          nil];
    [self performSelectorOnMainThread:@selector(callSetDeviceTokenError:) withObject:json waitUntilDone:NO];
}

- (void)callSetDeviceTokenErrorOnUiThreadWith:(NSInteger)code message:(NSString*)message {
    [self callSetDeviceTokenErrorOnUiThread:[NSString stringWithFormat:@"E%ld", (long)code] message:message];
}

/**
 * Set APNS device token into Ncmb mBaas.
 *
 * Execute in
 *   self::setDeviceToken
 *   AppDelegate::didRegisterForRemoteNotificationsWithDeviceToken
 */
- (void) setDeviceTokenAPNS: (NSData*)deviceToken {
    [[NSUserDefaults standardUserDefaults] setObject:deviceToken forKey:kNcmbPushDeviceTokenKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [self installWithAppKey:[[self class] getAppKey] clientKey:[[self class] getClientKey] deviceToken:deviceToken];
}

/**
 * Failed to register APNS.
 * Execute in AppDelegate::didFailToRegisterForRemoteNotificationsWithError
 */
- (void) failedToRegisterAPNS {
    if (_setDeviceTokenCallbackId != nil) {
        [self callSetDeviceTokenErrorOnUiThread:kNcmbPushErrorCodeFailedToRegisterAPNS message:kNcmbPushErrorMessageFailedToRegisterAPNS];
    } else {
        _isFailedToRegisterAPNS = YES;
    }
}

/**
 * Install NCMB.
 */
- (void)installWithAppKey:(NSString*)appKey clientKey:(NSString*)clientKey deviceToken:(NSData*)deviceToken {
    if (appKey == nil || clientKey == nil) {
        return;
    }

    [NCMB setApplicationKey:appKey clientKey:clientKey];
    hasSetup = YES;

    if (deviceToken != nil) {
        [self performSelectorInBackground:@selector(saveInBackgroundWithBlockFirst:) withObject:deviceToken];
    } else {
        AppDelegate *delegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
        [delegate registerForRemoteNotifications];
    }
}

- (void)saveInBackgroundWithBlockFirst:(NSData*)deviceToken {
    [self saveInBackgroundWithBlock:deviceToken withInstallation:nil];
}

/**
 * Save device token in Ncmb mBaas.
 */
- (void)saveInBackgroundWithBlock:(NSData*)deviceToken withInstallation:(NCMBInstallation *) inst {
    NCMBInstallation *installation = inst;
    if (installation == nil) {
        installation = [NCMBInstallation currentInstallation];
    }
    [installation setDeviceTokenFromData:deviceToken];
    [installation saveInBackgroundWithBlock:^(NSError *error) {
        if (!error) {
            [self callSetDeviceTokenSuccessOnUiThread];
        } else {
            if (error.code == 409001) {
                [self updateExistInstallation:installation];
            } else if (error.code == 404001 && inst == nil && _setDeviceTokenCallbackId) {
                installation.objectId = nil;
                [self saveInBackgroundWithBlock:deviceToken withInstallation:installation];
            } else {
                [self callSetDeviceTokenErrorOnUiThreadWith: error.code message:kNcmbPushErrorMessageFailedToSave];
            }
        }
    }];
}

/**
 * Overwrite device token when failed to update it because of duplication.
 */
-(void)updateExistInstallation:(NCMBInstallation*)currentInstallation{
    NCMBQuery *installationQuery = [NCMBInstallation query];
    [installationQuery whereKey:@"deviceToken" equalTo:currentInstallation.deviceToken];
    [installationQuery getFirstObjectInBackgroundWithBlock:^(NCMBObject *searchDevice, NSError *searchErr) {
        if (!searchErr){
            currentInstallation.objectId = searchDevice.objectId;
            [currentInstallation saveInBackgroundWithBlock:^(NSError *error) {
                if (!error) {
                    [self callSetDeviceTokenSuccessOnUiThread];
                } else {
                    [self callSetDeviceTokenErrorOnUiThreadWith:error.code message:kNcmbPushErrorMessageFailedToSave];
                }
            }];
        } else {
            [self callSetDeviceTokenErrorOnUiThreadWith:searchErr.code message:kNcmbPushErrorMessageNoDeviceToken];
        }
    } ];

}

#pragma mark - Get InstalationId

/**
 * Get installation ID (cordova API).
 * Do in background thread because of execution time.
 */
- (void)getInstallationId:(CDVInvokedUrlCommand*)command {
    [self.commandDelegate runInBackground:^{
        NCMBInstallation *currentInstallation = [NCMBInstallation currentInstallation];
        CDVPluginResult* getResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:currentInstallation.objectId];
        [self.commandDelegate sendPluginResult:getResult callbackId:command.callbackId];
    }];
}

#pragma mark - Checking receipt status

/**
 * Set receipt status (cordova API).
 */
- (void)setReceiptStatus:(CDVInvokedUrlCommand*)command {
    NSNumber *status = [command.arguments objectAtIndex:0];
    [[NSUserDefaults standardUserDefaults] setObject:status forKey:kNcmbPushReceiptKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
}

/**
 * Get receipt status (cordova API).
 */
- (void) getReceiptStatus: (CDVInvokedUrlCommand*)command {
    CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsBool:[[self class] isReceiptStatusOk]];
    [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
}

#pragma mark - Push received

/**
 * Set pushReceived callbackId (cordova API).
 */
- (void) pushReceived: (CDVInvokedUrlCommand*)command {
    _pushReceivedCallbackId = command.callbackId;
    [self sendAllJsons];
}

/**
 * Send all jsons in queue into webview.
 */
- (void) sendAllJsons {
    if (_pushReceivedCallbackId != nil && _webViewLoadFinished) {
        while (![_queue isEmpty]) {
            NSDictionary *json = [_queue dequeue];

            if (json != nil) {
                [self sendJson:json callbackId:_pushReceivedCallbackId];
            }
        }
    }
}

/**
 * Send json into webview.
 */
- (void) sendJson: (NSDictionary*)json callbackId:(NSString*)callbackId {
    CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:json];
    [result setKeepCallbackAsBool:YES];
    [self.commandDelegate sendPluginResult:result callbackId:callbackId];
}

/**
 * Add json into queue or webview.
 */
- (void) addJson: (NSDictionary*)json {
    if (!_webViewLoadFinished) {
        [_queue enqueue:json];
    } else if (_pushReceivedCallbackId == nil) {
        [_queue enqueue:json];
    } else {
        [self sendAllJsons];
        [self sendJson:json callbackId:_pushReceivedCallbackId];
    }
}

/**
 * Add json into queue or webview with application state.
 */
- (void) addJson: (NSDictionary*)json withAppIsActive:(BOOL)isActive {
    [json setValue:[NSNumber numberWithBool: isActive] forKey:@"ApplicationStateActive"];
    [self addJson:json];
}
@end
