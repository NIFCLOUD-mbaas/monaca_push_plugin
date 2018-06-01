#!/usr/bin/env node
'use strict';

/**
 * MIT License
 * Copyright (c) 2016 Robert Arnesson AB
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */
var fs = require('fs');
var path = require('path');

fs.ensureDirSync = function (dir) {
    if (!fs.existsSync(dir)) {
        dir.split(path.sep).reduce(function (currentPath, folder) {
            currentPath += folder + path.sep;
            if (!fs.existsSync(currentPath)) {
                fs.mkdirSync(currentPath);
            }
            return currentPath;
        }, '');
    }
};

var ANDROID_DIR = 'platforms/android';
var PLATFORM = {
    ANDROID: {
        src: 'google-services.json',
        stringsXml: fileExists(ANDROID_DIR + '/app/src/main/res/values/strings.xml') ? ANDROID_DIR + '/app/src/main/res/values/strings.xml' : ANDROID_DIR + '/res/values/strings.xml'
    }
};

function updateStringsXml(contents) {
    var json = JSON.parse(contents);
    var strings = fs.readFileSync(PLATFORM.ANDROID.stringsXml).toString();

    // strip non-default value
    strings = strings.replace(new RegExp('<string name="google_app_id">([^\@<]+?)</string>', 'i'), '');

    // strip non-default value
    strings = strings.replace(new RegExp('<string name="google_api_key">([^\@<]+?)</string>', 'i'), '');

    // strip empty lines
    strings = strings.replace(new RegExp('(\r\n|\n|\r)[ \t]*(\r\n|\n|\r)', 'gm'), '$1');

    // replace the default value
    strings = strings.replace(new RegExp('<string name="google_app_id">([^<]+?)</string>', 'i'), '<string name="google_app_id">' + json.client[0].client_info.mobilesdk_app_id + '</string>');

    // replace the default value
    strings = strings.replace(new RegExp('<string name="google_api_key">([^<]+?)</string>', 'i'), '<string name="google_api_key">' + json.client[0].api_key[0].current_key + '</string>');

    fs.writeFileSync(PLATFORM.ANDROID.stringsXml, strings);
}

function readFile(platform, callback) {
    var file = platform.src;
    if (fileExists(file)) {
        try {
            var contents = fs.readFileSync(file).toString();
            callback && callback(contents);
        } catch (err) {
            console.log(err)
            throw err;
        }
    } else {
        throw "Please place your Firebase configuration file (google-services.json) in the root folder of this project.";
    }
}

function fileExists(path) {
    try {
        return fs.statSync(path).isFile();
    } catch (e) {
        return false;
    }
}

function directoryExists(path) {
    try {
        return fs.statSync(path).isDirectory();
    } catch (e) {
        return false;
    }
}

module.exports = function(context) {
    //get platform from the context supplied by cordova
    var platforms = context.opts.platforms;
    if (platforms.indexOf('android') !== -1 && directoryExists(ANDROID_DIR)) {
        console.log('Preparing Firebase on Android');
        readFile(PLATFORM.ANDROID, updateStringsXml)
    }
};