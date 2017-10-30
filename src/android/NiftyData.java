package plugin.push.nifty;

import android.content.Intent;
import android.os.Bundle;

/**
 * Nifty push notification data holder.
 */
public class NiftyData {
    public static final String PUSH_ID_KEY = "com.nifty.PushId";
    public static final String JSON_KEY = "com.nifty.Data";

    /**
     * Data holder.
     */
    private Bundle mBundle;

    /**
     * Constructor.
     *
     * @param bundle
     */
    public NiftyData(final Bundle bundle) {
        mBundle = new Bundle();

        if (null != bundle) {
            mBundle.putAll(bundle);
        }
    }

    /**
     * Create dummy intent for Nifty SDK.
     *
     * @return dummy intent which has push notification data
     */
    public Intent createIntent() {
        Intent intent = new Intent();

        for (String key : mBundle.keySet()) {
            intent.putExtra(key, mBundle.getString(key));
        }

        return intent;
    }

    /**
     * Is from nifty or not.
     *
     * @return true=from nifty, false=otherwise
     */
    public boolean isFromNifty() {
        return mBundle.containsKey(PUSH_ID_KEY);
    }

    /**
     * Get nifty push ID.
     *
     * @return
     */
    public String getPushId() {
        return mBundle.getString(PUSH_ID_KEY, "");
    }

    /**
     * Has json data or not.
     *
     * @return true=has, false=not have
     */
    public boolean hasJson() {
        return mBundle.containsKey(JSON_KEY);
    }

    /**
     * Get json string.
     *
     * @return JSON data
     */
    public String getJson() {
        return mBundle.getString(JSON_KEY);
    }

    /**
     * Remove json string from external intent.
     *
     * @param intent
     */
    public static void removeNiftyData(final Intent intent) {
        if (intent.hasExtra(PUSH_ID_KEY)) {
            intent.removeExtra(PUSH_ID_KEY);
        }

        if (intent.hasExtra(JSON_KEY)) {
            intent.removeExtra(JSON_KEY);
        }
    }
}
