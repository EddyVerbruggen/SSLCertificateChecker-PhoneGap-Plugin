cordova.commandProxy.add("SSLCertificateChecker", {

  checkInCertChain: function(successCallback, errorCallback, params) {
    if (typeof errorCallback != "function") {
      console.log("SSLCertificateChecker.find failure: errorCallback parameter must be a function");
      return
    }
    // note that this is entirely possible, but not implemented
    errorCallback("Function not supported in the current Windows implementation of this plugin");
  },

  check: function(successCallback, errorCallback, params) {
    var serverURL = params[0];
    // params[1] is irrelevant
    var allowedSHA1Fingerprint = params[2];
    var allowedSHA1FingerprintAlt = params[3];

    if (typeof errorCallback != "function") {
      console.log("SSLCertificateChecker.find failure: errorCallback parameter must be a function");
      return
    }

    if (typeof successCallback != "function") {
      console.log("SSLCertificateChecker.find failure: successCallback parameter must be a function");
      return
    }

    var hostName;
    try {
      // we expect something like "build.phonegap.com", without the "https://"
      var strippedURL = serverURL;
      if (strippedURL.indexOf("://") > -1) {
        strippedURL = strippedURL.substring(strippedURL.indexOf("://") + 3);
      }
      hostName = new Windows.Networking.HostName(strippedURL);
    } catch (error) {
      errorCallback("CONNECTION_FAILED. Details: Invalid serverURL, " + serverURL);
      return;
    }

    var stateHolder = {};
    stateHolder.closing = false;
    stateHolder.clientSocket = new Windows.Networking.Sockets.StreamSocket();

    // Connect to the server
    stateHolder.clientSocket.connectAsync(
        hostName,
        443, // port
        Windows.Networking.Sockets.SocketProtectionLevel.ssl)
        .then(function () {
          // No SSL errors: return an empty promise and continue processing in the .done function
          return
        }, function (reason) {
          if (stateHolder.clientSocket.information.serverCertificateErrorSeverity ===
              Windows.Networking.Sockets.SocketSslErrorSeverity.ignorable) {
            return shouldIgnoreCertificateErrorsAsync(
                stateHolder.clientSocket.information.serverCertificateErrors)
                .then(function (userAcceptedRetry) {
                  if (userAcceptedRetry) {
                    return connectSocketWithRetryHandleSslErrorAsync(hostName, serviceName);
                  }
                  errorCallback("CONNECTION_NOT_SECURE");
                  return
                });
          }
          errorCallback("CONNECTION_FAILED. Details: " + reason);
        })
        .done(function () {
          // Get detailed certificate information.
          if (stateHolder.clientSocket.information.serverCertificate != null) {
            var certFp = "";
            var fpHash = stateHolder.clientSocket.information.serverCertificate.getHashValue();
            for (var i = 0; i < fpHash.length; i++) {
              var block = fpHash[i].toString(16);
              if (block.length == 1) {
                certFp += "0";
              }
              certFp += block;
            }
            certFp = certFp.toUpperCase();

            stateHolder.clientSocket.close();
            stateHolder.clientSocket = null;

            var fpOK = allowedSHA1Fingerprint !== undefined && certFp == allowedSHA1Fingerprint.toUpperCase().split(' ').join('');
            var fpAltOK = allowedSHA1FingerprintAlt !== undefined && certFp == allowedSHA1FingerprintAlt.toUpperCase().split(' ').join('');

            if (fpOK || fpAltOK) {
              successCallback("CONNECTION_SECURE");
            } else {
              errorCallback("CONNECTION_NOT_SECURE");
            }
          }
        }, function (reason) {
          // If this is an unknown status it means that the error is fatal and retry will likely fail.
          if (("number" in reason) &&
              (Windows.Networking.Sockets.SocketError.getStatus(reason.number) ===
              Windows.Networking.Sockets.SocketErrorStatus.unknown)) {
            throw reason;
          }

          stateHolder.clientSocket.close();
          stateHolder.clientSocket = null;
          errorCallback("CONNECTION_FAILED. Details: " + reason);
        });
  }
});
