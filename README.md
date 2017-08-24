# Nifty Cloud Mobile Backend Push Notification Plugin for Monaca

---

## Specifications

 - PhoneGap/Cordova 6.5 ~
 - iOS/Android Support OS version:
    - iOS: 9.x ~
    - Android: see [Android SDK](https://github.com/NIFTYCloud-mbaas/ncmb_android) Specifications.
---

## Methods

### window.NCMB.monaca.setDeviceToken(applicationKey,clientKey,senderId, successCallback, errorCallback)

Register device-token to Nifty cloud mobile backend datastore (Installation class).

 - (String)applicationKey
 - (String)clientKey
 - (String)senderId
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
                    "#####client_key#####",
                    "#####sender_id#####"
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
