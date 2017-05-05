cordova.commandProxy.add("SSLCertificateChecker", {

  checkInCertChain: function(successCallback, errorCallback, params) {
    if (typeof errorCallback != "function") {
      console.log("SSLCertificateChecker.find failure: errorCallback parameter must be a function");
      return
    }
    // note that this is entirely possible, but not implemented
    errorCallback("Function not supported in the current Windows implementation of this plugin, nor will it ever by because it's considered too insecure.");
  },

  check: function(successCallback, errorCallback, params) {
    var serverURL = params[0];
    // params[1] is irrelevant
    var allowedSHA1Fingerprints = params[2];

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
      // we expect something like "build.phonegap.com", without the "https://" and path
      var strippedURL = serverURL;
      if (strippedURL.indexOf("://") > -1) {
        strippedURL = strippedURL.substring(strippedURL.indexOf("://") + 3);
      }
      if (strippedURL.indexOf("/") > -1) {
        strippedURL = strippedURL.substring(0, strippedURL.indexOf("/"));
      }
      if (strippedURL.indexOf(":") > -1) {
          strippedURL = strippedURL.substring(0, strippedURL.indexOf(":"));
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
            // ignorable (http or self signed certificate), move on to .done
            return;
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

            for (var j = 0; j < allowedSHA1Fingerprints.length; j++) {
              if (certFp == allowedSHA1Fingerprints[j].toUpperCase().split(' ').join('')) {
                successCallback("CONNECTION_SECURE");
                return;
              }
            }
              errorCallback("CONNECTION_NOT_SECURE");
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
