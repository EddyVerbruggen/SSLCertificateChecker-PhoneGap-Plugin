"use strict";
function SSLCertificateChecker() {}

// TODO pass in array of fingerPrints
SSLCertificateChecker.prototype.check = function (serverURL, _fingerprint, successCallback, errorCallback) {
    if (typeof errorCallback != "function") {
        console.log("SSLCertificateChecker.find failure: errorCallback parameter must be a function");
        return
    }
    
    if (typeof successCallback != "function") {
        console.log("SSLCertificateChecker.find failure: successCallback parameter must be a function");
        return
    }
    cordova.exec(successCallback, errorCallback, "SSLCertificateChecker", "check", [serverURL, _fingerprint]);
};

SSLCertificateChecker.install = function () {
    if (!window.plugins) {
        window.plugins = {};
    }
    
    window.plugins.sslCertificateChecker = new SSLCertificateChecker();
    return window.plugins.cameraRoll;
};

cordova.addConstructor(SSLCertificateChecker.install);