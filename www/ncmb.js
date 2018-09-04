/**
 * Ncmb PushNotification API.
 */
var argscheck = require('cordova/argscheck'),
    channel = require('cordova/channel'),
    exec = require('cordova/exec'),
    cordova = require('cordova');

/**
 * Data queue.
 */
var DataQueue = (function() {
    /**
     * Constructor.
     */
    var DataQueue = function() {
        this.data = [];
    }

    /**
     * Queue is empty or not.
     *
     * @return {boolean} true=empty, false=not empty
     */
    DataQueue.prototype.isEmpty = function() {
        return 0 === this.data.length;
    };

    /**
     * Enqueue data.
     *
     * @param {*} data
     */
    DataQueue.prototype.add = function(data) {
        this.data.push(data);
    };

    /**
     * Dequeue data.
     *
     * @return {*}
     */
    DataQueue.prototype.get = function() {
        if (this.isEmpty()) {
            return null;
        } else {
            return this.data.shift();
        }
    };

    return DataQueue;
}());

/**
 * Plugin name
 */
var pluginName = 'NcmbPushPlugin';

/**
 * Ncmb PushNotification API
 */
var NCMB = (function() {
    /**
     * Constructor.
     */
    var NCMB = function() {
        this.queue = new DataQueue;
        this.callback = null;
    };

    /**
     * Set some keys.
     *
     * @param {String} applicationKey
     * @param {String} clientKey
     * @param {Function} success (OPTIONAL)
     * @param {Function} error (OPTIONAL)
     */
    NCMB.prototype.setDeviceToken = function (applicationKey, clientKey, success, error) {
        argscheck.checkArgs('ssFF', 'NCMB.monaca.setDeviceToken', arguments);
        success = success || function() {};
        error = error || function() {};
        exec(success, error, pluginName, 'setDeviceToken', [applicationKey, clientKey]);
    };

    /**
     * Set handler.
     *
     * @param {Function} callback
     */
    NCMB.prototype.setHandler = function (callback) {
        argscheck.checkArgs('f', 'NCMB.monaca.setHandler', arguments);
        this.callback = callback;

        while (!this.queue.isEmpty()) {
            this.callback.apply(null, [this.queue.get()]);
        }
    };

    /**
     * Push received data (called by native code).
     *
     * @param {*} data
     */
    NCMB.prototype.pushReceived = function (data) {
        if ('function' === typeof this.callback) {
            this.callback(data);
        } else {
            this.queue.add(data);
        }
    };

    /**
     * Get installation ID.
     *
     * @param {Function} callback
     */
    NCMB.prototype.getInstallationId = function(callback) {
        argscheck.checkArgs('f', 'NCMB.monaca.getInstallationId', arguments);
        exec(callback, null, pluginName, 'getInstallationId', []);
    };

    /**
     * Set receipt status.
     *
     * @param {boolean} status
     * @param {Function} callback (OPTIONAL)
     */
    NCMB.prototype.setReceiptStatus = function(status, callback) {
        argscheck.checkArgs('*F', 'NCMB.monaca.setReceiptStatus', arguments);
        callback = callback || function() {};
        exec(callback, null, pluginName, 'setReceiptStatus', [status]);
    };

    /**
     * Get receipt status.
     *
     * @param {Function} callback
     */
    NCMB.prototype.getReceiptStatus = function(callback) {
        argscheck.checkArgs('f', 'NCMB.monaca.getReceiptStatus', arguments);
        exec(callback, null, pluginName, 'getReceiptStatus', []);
    };

    return NCMB;
}());

/**
 * NCMB Object.
 */
var ncmb = new NCMB();

/**
 * Register callback to receive push notification data.
 */
channel.onCordovaReady.subscribe(function() {
    exec(function(data) {
        ncmb.pushReceived(data);
    }, null, pluginName, 'pushReceived', []);
});


/**
 * Export NCMB.
 */
module.exports = ncmb;

