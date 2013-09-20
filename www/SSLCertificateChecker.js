"use strict";
function SSLCertificateChecker() {}

SSLCertificateChecker.prototype.check = function (successCallback, errorCallback, serverURL, allowedFingerprint, allowedFingerprintAlt) {
    if (typeof errorCallback != "function") {
        console.log("SSLCertificateChecker.find failure: errorCallback parameter must be a function");
        return
    }
    
    if (typeof successCallback != "function") {
        console.log("SSLCertificateChecker.find failure: successCallback parameter must be a function");
        return
    }
    cordova.exec(successCallback, errorCallback, "SSLCertificateChecker", "check", [serverURL, allowedFingerprint, allowedFingerprintAlt]);
};

SSLCertificateChecker.install = function () {
    if (!window.plugins) {
        window.plugins = {};
    }
    
    window.plugins.sslCertificateChecker = new SSLCertificateChecker();
    return window.plugins.cameraRoll;
};

cordova.addConstructor(SSLCertificateChecker.install);