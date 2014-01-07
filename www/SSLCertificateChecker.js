"use strict";
var exec = require('cordova/exec');

function SSLCertificateChecker() {
}

SSLCertificateChecker.prototype.check = function (successCallback, errorCallback, serverURL, allowedSHA1Fingerprint, allowedSHA1FingerprintAlt) {
  if (typeof errorCallback != "function") {
    console.log("SSLCertificateChecker.find failure: errorCallback parameter must be a function");
    return
  }

  if (typeof successCallback != "function") {
    console.log("SSLCertificateChecker.find failure: successCallback parameter must be a function");
    return
  }
  cordova.exec(successCallback, errorCallback, "SSLCertificateChecker", "check", [serverURL, allowedSHA1Fingerprint, allowedSHA1FingerprintAlt]);
};

var sslCertificateChecker = new SSLCertificateChecker();
module.exports = sslCertificateChecker;