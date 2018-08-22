package plugin.push.nifcloud;

import android.content.Context;
import android.content.Intent;
import android.content.SharedPreferences;
import android.os.Bundle;

import com.nifcloud.mbaas.core.DoneCallback;
import com.nifcloud.mbaas.core.TokenCallback;
import com.nifcloud.mbaas.core.FindCallback;
import com.nifcloud.mbaas.core.NCMB;
import com.nifcloud.mbaas.core.NCMBException;
import com.nifcloud.mbaas.core.NCMBInstallation;
import com.nifcloud.mbaas.core.NCMBPush;
import com.nifcloud.mbaas.core.NCMBQuery;

import org.apache.cordova.CallbackContext;
import org.apache.cordova.CordovaPlugin;
import org.apache.cordova.PluginResult;
import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.util.List;
import java.util.Queue;
import java.util.concurrent.LinkedBlockingQueue;

/**
 * Ncmb push notification plugin.
 */
public class NcmbPushPlugin extends CordovaPlugin
{
    private static final String PREFS_NAME = "kNcmbPushPrefs";
    private static final String APP_KEY = "app_key";
    private static final String CLIENT_KEY = "client_key";
    private static final String RECEIPT_STATUS = "receipt_status";

    /**
     * Push received callback context.
     */
    private CallbackContext mPushReceivedCallbackContext;

    /**
     * Ncmb push notification data queue to send into webview.
     */
    private Queue<NcmbData> mPushQueue;

    /**
     * Initialize plugin.
     */
    @Override
    protected void pluginInitialize() {
        mPushQueue = new LinkedBlockingQueue<NcmbData>();
        SharedPreferences prefs = getSharedPrefs();
        final String appKey = prefs.getString(APP_KEY, "");
        final String clientKey = prefs.getString(CLIENT_KEY, "");

        if (!appKey.equals("") && !clientKey.equals("")) {
            NCMB.initialize(cordova.getActivity(), appKey, clientKey);
        }
    }

    /**
     * Get new intent from FCM etc.
     *
     * @param intent
     */
    @Override
    public void onNewIntent(Intent intent) {
        checkNotification(intent);
    }

    /**
     * On resume.
     *
     * @param multitasking Flag indicating if multitasking is turned on for app
     */
    @Override
    public void onResume(boolean multitasking) {
        checkNotification(cordova.getActivity().getIntent());
    }

    /**
     * Check ncmb notification in intent.
     *
     * @param intent
     * @return true=handle notification, false=otherwise
     */
    private synchronized boolean checkNotification(Intent intent) {
        if (0 != (intent.getFlags() & Intent.FLAG_ACTIVITY_LAUNCHED_FROM_HISTORY)) {
            return false;
        }

        if (!checkNotification(intent.getExtras())) {
            return false;
        }

        NcmbData.removeNcmbData(intent);

        return true;
    }

    /**
     * Check ncmb notification in bundle.
     *
     * @param bundle
     * @return true=send into webview or push into queue, false=otherwise
     */
    private boolean checkNotification(Bundle bundle) {
        NcmbData data = new NcmbData(bundle);

        if (!data.isFromNcmb()) {
            return false;
        }

        if (null != mPushReceivedCallbackContext) {
            try {
                sendNotificationJson(data);
            } catch (JSONException e) {
                e.printStackTrace();
            }
        } else {
            mPushQueue.add(data);
        }

        return true;
    }

    /**
     * Send notification json data into webview.
     *
     * @param data
     */
    private synchronized void sendNotificationJson(final NcmbData data) throws JSONException {
        if (null == mPushReceivedCallbackContext) {
            return;
        } else if (!data.isFromNcmb()) {
            return;
        }

        JSONObject json = null;
        if (data.hasJson()) {
            json = new JSONObject(data.getJson());
        } else {
            json = new JSONObject();
        }
        PluginResult result = new PluginResult(PluginResult.Status.OK, json);
        result.setKeepCallback(true);
        mPushReceivedCallbackContext.sendPluginResult(result);

        // Use dummy intent to call trackAppOpened and richPushHandler.
        Intent dummyIntent = data.createIntent();

        if (isReceiptStatusOk()) {
            NCMBPush.trackAppOpened(dummyIntent);
        }

        NCMBPush.richPushHandler(cordova.getActivity(), dummyIntent);
    }

    /**
     * Get shared preferences for plugin.
     *
     * @return shared preferences
     */
    private SharedPreferences getSharedPrefs() {
        return cordova.getActivity().getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE);
    }

    /**
     * Is receipt status ok or not.
     *
     * @return true=OK, false=NG
     */
    private boolean isReceiptStatusOk() {
        SharedPreferences prefs = getSharedPrefs();
        return prefs.getBoolean(RECEIPT_STATUS, false);
    }

    /**
     * Execute plugin methods.
     *
     * @param action          The action to execute.
     * @param args            The exec() arguments.
     * @param callbackContext The callback context used when calling back into JavaScript.
     * @return
     * @throws JSONException
     */
    @Override
    public boolean execute(String action, JSONArray args, CallbackContext callbackContext) throws JSONException {
        if (action.equals("setDeviceToken")) {
            return setDeviceToken(args, callbackContext);
        } else if (action.equals("getInstallationId")) {
            return getInstallationId(callbackContext);
        } else if (action.equals("setReceiptStatus")) {
            boolean flag = args.getBoolean(0);
            SharedPreferences prefs = getSharedPrefs();
            SharedPreferences.Editor editor = prefs.edit();
            editor.putBoolean(RECEIPT_STATUS, flag);
            editor.apply();
            callbackContext.success();
        } else if (action.equals("getReceiptStatus")) {
            PluginResult result = new PluginResult(PluginResult.Status.OK, isReceiptStatusOk());
            callbackContext.sendPluginResult(result);
        } else if (action.equals("pushReceived")) {
            mPushReceivedCallbackContext = callbackContext;
            cordova.getActivity().runOnUiThread(new Runnable() {
                @Override
                public void run() {
                    while (!mPushQueue.isEmpty()) {
                        try {
                            sendNotificationJson(mPushQueue.poll());
                        } catch (JSONException e) {
                            e.printStackTrace();
                        }
                    }
                }
            });
        } else {
            return false;
        }

        return true;
    }

    /**
     * Set device token to ncmb and save in storage.
     *
     * @param args
     * @param callbackContext
     * @return
     */
    private boolean setDeviceToken(final JSONArray args, final CallbackContext callbackContext)
    {
        if (args.length() < 2) {
            callbackContext.error("Parameters are invalid");
            return true;
        }

        final String appKey = args.optString(0);
        final String clientKey = args.optString(1);
        if ("".equals(appKey) || "".equals(clientKey)) {
            callbackContext.error("Parameters are invalid");
            return true;
        }
        SharedPreferences prefs = getSharedPrefs();
        SharedPreferences.Editor editor = prefs.edit();
        editor.putString(APP_KEY, appKey);
        editor.putString(CLIENT_KEY, clientKey);
        editor.apply();
        NCMB.initialize(cordova.getActivity(), appKey, clientKey);

        final NCMBInstallation installation = NCMBInstallation.getCurrentInstallation();
        installation.getDeviceTokenInBackground(new TokenCallback() {
            @Override
            public void done(String token, NCMBException e) {
                if (null != e) {
                    e.printStackTrace();
                    callbackContext.error(getErrorJson(e.getCode(), "Failed to get device token."));
                    return;
                }

                // Register device information into data store.
                installation.saveInBackground(new DoneCallback() {
                    @Override
                    public void done(NCMBException saveErr) {
                        if (null == saveErr) {
                            callbackContext.success("Success to save device token.");
                        } else {
                            // Check duplicated registration ID.
                            if (NCMBException.DUPLICATE_VALUE.equals(saveErr.getCode())) {
                                updateInstallation(installation, callbackContext);
                            } else if (NCMBException.DATA_NOT_FOUND.equals(saveErr.getCode())) {
                                // Retry
                                setDeviceToken(args, callbackContext);
                            } else {
                                saveErr.printStackTrace();
                                callbackContext.error(getErrorJson(saveErr.getCode(), "Failed to get device token."));
                            }
                        }
                    }
                });
            }
        });
        return true;
    }

    /**
     * Update installation.
     *
     * @param installation
     */
    private static void updateInstallation(final NCMBInstallation installation, final CallbackContext callbackContext) {
        // Search device information which has the same registration ID in device token field.
        installation.getDeviceTokenInBackground(new TokenCallback() {
            @Override
            public void done(String token, NCMBException error) {
                if (error == null) {
                    NCMBQuery<NCMBInstallation> query = NCMBInstallation.getQuery();
                    query.whereEqualTo("deviceToken", installation.getDeviceToken());
                    query.findInBackground(new FindCallback<NCMBInstallation>() {
                        @Override
                        public void done(List<NCMBInstallation> results, NCMBException e) {
                            if (null != e) {
                                callbackContext.error(getErrorJson(e.getCode(), "Failed to get device token."));
                                return;
                            }
                            // Update object ID.
                            try{
                                installation.setObjectId(results.get(0).getObjectId());
                            }catch(Exception e1){}
                            
                            installation.saveInBackground(new DoneCallback() {
                                @Override
                                public void done(NCMBException saveErr) {
                                    if (saveErr == null) {
                                        callbackContext.success("Success to update device token.");
                                    } else {
                                        saveErr.printStackTrace();
                                        callbackContext.error(getErrorJson(saveErr.getCode(), "Failed to get device token."));
                                    }
                                }
                            });
                        }
                    });
                }
            }
        });
        
    }

    /**
     * Get error json for "setDeviceToken".
     *
     * @param code
     * @param message
     * @return
     */
    private static JSONObject getErrorJson(final String code, final String message) {
        JSONObject json = new JSONObject();

        try {
            json.put("code", code);
            json.put("message", message);
        } catch (JSONException e) {
            e.printStackTrace();
        }

        return json;
    }

    /**
     * Get installation ID.
     *
     * @param callbackContext
     * @return installation ID
     */
    private boolean getInstallationId(final CallbackContext callbackContext) {
        try {
            String installationID = NCMBInstallation.getCurrentInstallation().getObjectId();
            callbackContext.success(installationID);
            return true;
        } catch(Exception e) {
            callbackContext.error("Failed to get installation Id.");
            return false;
        }
    }
}
