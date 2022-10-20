# NIFCLOUD Mobile Backend Push Notification Plugin for Monaca

---
## 対応環境

 - PhoneGap/Cordova 9.0, Cordova 10.0, Cordova 11.0
 - iOS/Android Support OS version:
    - iOS: see [iOS SDK](https://github.com/NIFCLOUD-mbaas/ncmb_ios) Specifications.
    - Android: see [Android SDK](https://github.com/NIFCLOUD-mbaas/ncmb_android) Specifications.

## テクニカルサポート窓口対応バージョン

テクニカルサポート窓口では、1年半以内にリリースされたSDKに対してのみサポート対応させていただきます。
定期的なバージョンのアップデートにご協力ください。  
※なお、mobile backend にて大規模な改修が行われた際は、1年半以内のSDKであっても対応出来ない場合がございます。  
その際は[informationブログ](https://mbaas.nifcloud.com/info/)にてお知らせいたします。予めご了承ください。  

- v3.0.10 ～ (※as of June,2022)

[開発ガイドライン](https://mbaas.nifcloud.com/doc/current/common/dev_guide.html#SDK%E3%81%AB%E3%81%A4%E3%81%84%E3%81%A6)をご覧ください。


## セットアップ

* 詳細については[ドキュメント](https://mbaas.nifcloud.com/doc/current/push/basic_usage_javascript.html#%E3%83%97%E3%83%83%E3%82%B7%E3%83%A5%E9%80%9A%E7%9F%A5%E3%81%AE%E5%8F%97%E4%BF%A1(Monaca))を併せてご確認ください.
* Android端末での利用には、ご自身のFirebase設定ファイルgoogle-services.jsonをダウンロードして、Cordovaプロジェクトのルートディレクトリに置く必要があります。設定ファイルのダウンロードについては[こちらのFirebaseサポートページ](https://support.google.com/firebase/answer/7015592)にて詳細をご覧ください。

```
- Your_monaca_project/
    platforms/
    plugins/
    www/
    config.xml
    google-services.json       <--
    ...
```


## 使い方

### window.NCMB.monaca.setDeviceToken(applicationKey,clientKey, successCallback, errorCallback)

ニフクラ mobile backendのデータストア(Installationクラス)にデバイストークンを登録します。

 - (String)applicationKey
 - (String)clientKey
 - (Function)successCallback() (OPTIONAL)
 - (Function)errorCallback(error) (OPTIONAL)

### window.NCMB.monaca.setHandler(callback)

アプリがプッシュ通知を受け取った際のコールバックを設定します。

- (function)callback(jsonData)

### window.NCMB.monaca.getInstallationId(callback)

デバイスのinstallation objectIdを取得します。

- (function)callback(installationId)

### window.NCMB.monaca.setReceiptStatus(flag, callback);

プッシュ通知の開封状況をサーバーに登録します。
これはプッシュ通知の開封状況についての統計グラフに利用されます。

- (Boolean) flag
    - true : Send receipt to server
    - false : No send
- (Function) callback() (OPTIONAL)

### window.NCMB.monaca.getReceiptStatus(callback);

プッシュ通知の開封状況を取得します。

- (function)callback(flag)

### window.NCMB.monaca.getDeviceToken(callback)

デバイスのInstallation deviceTokenを取得します。

- (function)callback(deviceToken)



## 使用例

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

                // Get device token.
                NCMB.monaca.getDeviceToken(function(deviceToken){
                    // something
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

## ライセンス

LICENSEファイルをご覧ください。

このプロジェクトに含まれるモジュール:
- Cordova plugin for Google Firebase (after_prepare.js):
    - license: MIT
    - Copyright (c) 2016 Robert Arnesson AB
    - homepage: https://github.com/arnesson/cordova-plugin-firebase
    - version: v1.0.5


---

## Specifications

 - PhoneGap/Cordova 9.0, Cordova 10.0, Cordova 11.0
 - iOS/Android Support OS version:
    - iOS: see [iOS SDK](https://github.com/NIFCLOUD-mbaas/ncmb_ios) Specifications.
    - Android: see [Android SDK](https://github.com/NIFCLOUD-mbaas/ncmb_android) Specifications.

## Support desk coverage version

Please read [Developer guidelines](https://mbaas.nifcloud.com/doc/current/common/dev_guide.html#SDK%E3%81%AB%E3%81%A4%E3%81%84%E3%81%A6).

- v3.0.10 ～ (※as of June,2022)


## Setup

* Check the following [Japanese official document](https://mbaas.nifcloud.com/doc/current/push/basic_usage_javascript.html#%E3%83%97%E3%83%83%E3%82%B7%E3%83%A5%E9%80%9A%E7%9F%A5%E3%81%AE%E5%8F%97%E4%BF%A1(Monaca)) for details on setup.
* To use with Android devices, download your Firebase configuration file - google-services.json, and place them in the root folder of your Cordova project.  Check out this [Firebase article](https://support.google.com/firebase/answer/7015592) for details on how to download the files.

```
- Your_monaca_project/
    platforms/
    plugins/
    www/
    config.xml
    google-services.json       <--
    ...
```

## Methods

### window.NCMB.monaca.setDeviceToken(applicationKey,clientKey, successCallback, errorCallback)

Register device-token to NIFCLOUD mobile backend datastore (Installation class).

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

### window.NCMB.monaca.getDeviceToken(callback)

Get the Installation deviceToken for device.

- (function)callback(deviceToken)



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

                // Get device token.
                NCMB.monaca.getDeviceToken(function(deviceToken){
                    // something
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
