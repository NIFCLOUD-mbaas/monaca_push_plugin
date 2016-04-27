
#Nifty Cloud for Push Notfication Plugin

---

## Spec

 - PhoneGap/Cordova 5.2 ~
 - iOS/Andorid

---

## Methods

###window.NCMB.monaca.setDeviceToken(applicationKey,clientKey,senderId, successCallback, errorCallback)

Register devicetoken to Nifty server.

 - (String)applicationKey
 - (String)clientKey
 - (String)senderId
 - (Function)successCallback() (OPTIONAL)
 - (Function)errorCallback(error) (OPTIONAL)
 
###window.NCMB.monaca.setHandler(callback)

Set the callback when app receive a push notification.

- (function)callback(jsonData)

###window.NCMB.monaca.getInstallationId(callback)

Get the Installation ID from device.

- (function)callback(installationId)

###window.NCMB.monaca.setReceiptStatus(flag, callback);

Set the notification open receipt status.

- (Boolean) flag 
	-  true : Send recipt to server
	- false : No send
- (Function) callback() (OPTIONAL)


###window.NCMB.monaca.getReceiptStatus(callback);

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