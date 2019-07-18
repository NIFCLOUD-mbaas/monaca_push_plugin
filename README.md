# NIFCloud Mobile Backend Push Notification Plugin for Monaca

---

## Specifications

 - PhoneGap/Cordova 7.1, Cordova 9.0
 - iOS/Android Support OS version:
    - iOS: see [iOS SDK](https://github.com/NIFCloud-mbaas/ncmb_ios) Specifications.
    - Android: see [Android SDK](https://github.com/NIFCloud-mbaas/ncmb_android) Specifications.

## Support desk coverage version

Please read [Developer guidelines](https://mbaas.nifcloud.com/doc/current/common/dev_guide.html#SDK%E3%81%AB%E3%81%A4%E3%81%84%E3%81%A6).

- v2.0.10 ～ (※as of July, 2019)

---

## Setup
Download your Firebase configuration file - google-services.json, and place them in the root folder of your cordova project.  Check out this [firebase article](https://support.google.com/firebase/answer/7015592) for details on how to download the files.

```
- Your_monaca_project/
    platforms/
    plugins/
    www/
    config.xml
    google-services.json       <--
    ...
```
---

## Methods

### window.NCMB.monaca.setDeviceToken(applicationKey,clientKey, successCallback, errorCallback)

Register device-token to NIFCloud mobile backend datastore (Installation class).

 - (String)applicationKey
 - (String)clientKey
 - (Function)successCallback() (OPTIONAL)
 - (Function)errorCallback(error) (OPTIONAL)

### window.NCMB.monaca.setHandler(callback)

Set the callback when app receive a push notification.

- (function)callback(jsonData)

### window.NCMB.monaca.getInstallationId(callback)

Get the Installation objectId for device.

- (function)callback(installationId)

### window.NCMB.monaca.setReceiptStatus(flag, callback);

Set the notification open receipt status to be store or not.
This status will be used to create Push notification open status statistic graph.

- (Boolean) flag
    - true : Send receipt to server
    - false : No send
- (Function) callback() (OPTIONAL)

### window.NCMB.monaca.getReceiptStatus(callback);

Get the notification open receipt status.

- (function)callback(flag)

---

## Sample

```
    <!DOCTYPE HTML>
    <html>
    <head>
        <meta charset="utf-8">
        <script src="cordova.js"></script>
        <script>
            document.addEventListener("deviceready", function() {
                NCMB.monaca.setDeviceToken(
                    "#####application_key#####",
                    "#####client_key#####"
                );

                // Set callback for push notification data.
                NCMB.monaca.setHandler(function(jsonData){
                    alert("callback :::" + JSON.stringify(jsonData));
                });

                // Get installation ID.
                NCMB.monaca.getInstallationId(function(installationId){
                    // something
                });

                // Get receipt status
                NCMB.monaca.getReceiptStatus(function(status){
                    // status = true or false
                });

                // Set receipt status
                NCMB.monaca.setReceiptStatus(true);

            },false);                
        </script>
    </head>
    <body>

    <h1>PushNotification Sample</h1>

    </body>
    </html>
```

## License

Please read LICENSE file.

Modules in this project:
- Cordova plugin for Google Firebase (after_prepare.js):
    - license: MIT
    - Copyright (c) 2016 Robert Arnesson AB
    - homepage: https://github.com/arnesson/cordova-plugin-firebase
    - version: v1.0.5
