//
//  NiftyPushNotification.m
//  Copyright 2017 FUJITSU CLOUD TECHNOLOGIES LIMITED All Rights Reserved.
//

#import "NiftyPushNotification.h"
#import "NCMB/NCMB.h"

@implementation NiftyPushNotification
static NSString *const kNiftyPushReceiptKey     = @"kNiftyPushReceiptStatus";
static NSString* const kNiftyPushAppKey         = @"APP_KEY";
static NSString* const kNiftyPushClientKey      = @"CLIENT_KEY";
static NSString* const kNiftyPushDeviceTokenKey = @"DEVICE_TOKEN";

static NSString* const kNiftyPushErrorMessageFailedToRegisterAPNS = @"Failed to register APNS.";
static NSString* const kNiftyPushErrorMessageInvalidParams = @"Parameters are invalid.";
static NSString* const kNiftyPushErrorMessageNoDeviceToken = @"Device Token does not exist.";
static NSString* const kNiftyPushErrorMessageFailedToSave  = @"installation save error.";
static NSString* const kNiftyPushErrorMessageRecoveryError = @"installation recovery error.";

static NSString* const kNiftyPushErrorCodeFailedToRegisterAPNS = @"EP000001";
static NSString* const kNiftyPushErrorCodeInvalidParams        = @"EP000002";

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
    return [[NSUserDefaults standardUserDefaults] objectForKey:kNiftyPushDeviceTokenKey];
}

/**
 * Is receipt status ok or not.
 */
+ (BOOL) isReceiptStatusOk {
    return [[NSUserDefaults standardUserDefaults] boolForKey:kNiftyPushReceiptKey];
}

/**
 * Get application key from storage.
 */
+ (NSString*) getAppKey {
    return [[NSUserDefaults standardUserDefaults]objectForKey:kNiftyPushAppKey];
}

/**
 * Get client key from storage.
 */
+ (NSString*) getClientKey {
    return [[NSUserDefaults standardUserDefaults]objectForKey:kNiftyPushClientKey];
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

    if ([NiftyPushNotification isReceiptStatusOk]) {
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

    if ([NiftyPushNotification isReceiptStatusOk]) {
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
    _queue = [[NiftyQueue alloc] init];
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
        [self callSetDeviceTokenErrorOnUiThread:kNiftyPushErrorCodeInvalidParams message: kNiftyPushErrorMessageInvalidParams];
        return;
    }

    NSString* appKey    = [command.arguments objectAtIndex:0];
    NSString* clientKey = [command.arguments objectAtIndex:1];
    [[NSUserDefaults standardUserDefaults] setObject:appKey forKey:kNiftyPushAppKey];
    [[NSUserDefaults standardUserDefaults] setObject:clientKey forKey:kNiftyPushClientKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [self installWithAppKey:appKey clientKey:clientKey deviceToken:[[self class] getDeviceTokenAPNS]];

    if (_isFailedToRegisterAPNS) {
        _isFailedToRegisterAPNS = NO;
        [self callSetDeviceTokenErrorOnUiThread:kNiftyPushErrorCodeFailedToRegisterAPNS message: kNiftyPushErrorMessageFailedToRegisterAPNS];
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
 * Set APNS device token into Nifty mBaas.
 *
 * Execute in
 *   self::setDeviceToken
 *   AppDelegate::didRegisterForRemoteNotificationsWithDeviceToken
 */
- (void) setDeviceTokenAPNS: (NSData*)deviceToken {
    [[NSUserDefaults standardUserDefaults] setObject:deviceToken forKey:kNiftyPushDeviceTokenKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [self installWithAppKey:[[self class] getAppKey] clientKey:[[self class] getClientKey] deviceToken:deviceToken];
}

/**
 * Failed to register APNS.
 * Execute in AppDelegate::didFailToRegisterForRemoteNotificationsWithError
 */
- (void) failedToRegisterAPNS {
    if (_setDeviceTokenCallbackId != nil) {
        [self callSetDeviceTokenErrorOnUiThread:kNiftyPushErrorCodeFailedToRegisterAPNS message:kNiftyPushErrorMessageFailedToRegisterAPNS];
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
    }
}

- (void)saveInBackgroundWithBlockFirst:(NSData*)deviceToken {
    [self saveInBackgroundWithBlock:deviceToken withInstallation:nil];
}

/**
 * Save device token in nifty mBaas.
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
            } else if (error.code == 404001 && inst == nil) {
                installation.objectId = nil;
                [self saveInBackgroundWithBlock:deviceToken withInstallation:installation];
            } else {
                [self callSetDeviceTokenErrorOnUiThreadWith: error.code message:kNiftyPushErrorMessageFailedToSave];
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
                    [self callSetDeviceTokenErrorOnUiThreadWith:error.code message:kNiftyPushErrorMessageFailedToSave];
                }
            }];
        } else {
            [self callSetDeviceTokenErrorOnUiThreadWith:searchErr.code message:kNiftyPushErrorMessageNoDeviceToken];
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
    [[NSUserDefaults standardUserDefaults] setObject:status forKey:kNiftyPushReceiptKey];
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
