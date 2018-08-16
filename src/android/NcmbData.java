package plugin.push.nifcloud;

import android.content.Intent;
import android.os.Bundle;

/**
 * Ncmb push notification data holder.
 */
public class NcmbData {
    public static final String PUSH_ID_KEY = "com.nifcloud.mbaas.PushId";
    public static final String JSON_KEY = "com.nifcloud.mbaas.Data";

    /**
     * Data holder.
     */
    private Bundle mBundle;

    /**
     * Constructor.
     *
     * @param bundle
     */
    public NcmbData(final Bundle bundle) {
        mBundle = new Bundle();

        if (null != bundle) {
            mBundle.putAll(bundle);
        }
    }

    /**
     * Create dummy intent for Ncmb SDK.
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
     * Is from ncmb or not.
     *
     * @return true=from ncmb, false=otherwise
     */
    public boolean isFromNcmb() {
        return mBundle.containsKey(PUSH_ID_KEY);
    }

    /**
     * Get ncmb push ID.
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
    public static void removeNcmbData(final Intent intent) {
        if (intent.hasExtra(PUSH_ID_KEY)) {
            intent.removeExtra(PUSH_ID_KEY);
        }

        if (intent.hasExtra(JSON_KEY)) {
            intent.removeExtra(JSON_KEY);
        }
    }
}
