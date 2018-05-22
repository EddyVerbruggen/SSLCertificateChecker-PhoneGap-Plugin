# PhoneGap SSL Certificate Checker plugin

[![NPM version][npm-image]][npm-url]
[![Downloads][downloads-image]][npm-url]
[![Twitter Follow][twitter-image]][twitter-url]

[npm-image]:http://img.shields.io/npm/v/cordova-plugin-sslcertificatechecker.svg
[npm-url]:https://npmjs.org/package/cordova-plugin-sslcertificatechecker
[downloads-image]:http://img.shields.io/npm/dm/cordova-plugin-sslcertificatechecker.svg
[twitter-image]:https://img.shields.io/twitter/follow/eddyverbruggen.svg?style=social&label=Follow%20me
[twitter-url]:https://twitter.com/eddyverbruggen

1. [Description](https://github.com/EddyVerbruggen/SSLCertificateChecker-PhoneGap-Plugin#1-description)
2. [Installation](https://github.com/EddyVerbruggen/SSLCertificateChecker-PhoneGap-Plugin#2-installation)
3. [Usage](https://github.com/EddyVerbruggen/SSLCertificateChecker-PhoneGap-Plugin#3-usage)
4. [Credits](https://github.com/EddyVerbruggen/SSLCertificateChecker-PhoneGap-Plugin#4-credits)

<table width="100%">
    <tr>
        <td width="100">Need SSL Pinning?</td>
        <td>If checking the certificate manually isn't sufficient for your needs and you want to be absolutely positive each and every HTTPS request is sent to your server, then take a look at the <a href="http://plugins.telerik.com/plugin/secure-http">Secure HTTP plugin</a>.</td>
    </tr>
    <tr>
        <td>Cert Chain checking</td>
        <td>Up until version 4.0.0 this plugin offered a way to check the chain through the `checkInCertChain` property, but this is actually not really secure so I removed it from the plugin. If you need this (and don't want to do pinning, so I would advise against it) then use an older version.</td>
    </tr>
</table>

## 1. Description

This plugin can be used to add an extra layer of security by preventing 'Man in the Middle' attacks.
When correctly used, it will be very hard for hackers to intercept communication between your app and your server,
because you can actively verify the SSL certificate of the server by comparing actual and expected fingerprints.

You may want to check the connection when the app is started, but you can choose to invoke this plugin
everytime you communicate with the server. In either case, you can add your logic to the success and error callbacks.

* This version is for PhoneGap 3.0 and higher.
* PhoneGap 2.9 and lower is available in the [pre-phonegap-3 tree](https://github.com/EddyVerbruggen/SSLCertificateChecker-PhoneGap-Plugin/tree/pre-phonegap-3).
* Compatible with [Cordova Plugman](https://github.com/apache/cordova-plugman).
* [Officially supported by PhoneGap Build](https://build.phonegap.com/plugins).

## 2. Installation

Latest stable version from npm:
```
$ cordova plugin add cordova-plugin-sslcertificatechecker
```

Bleeding edge version from Github:
```
$ cordova plugin add https://github.com/EddyVerbruggen/SSLCertificateChecker-PhoneGap-Plugin
```

### PhoneGap Build

```xml
<gap:plugin name="cordova-plugin-sslcertificatechecker" />
```

## 3. Usage

First obtain the fingerprint of the SSL certificate of your server(s).
You can find it f.i. by opening the server URL in Chrome. Then click the green certificate in front of the URL, click 'Connection',
'Certificate details', expand the details and scroll down to the **SHA256** fingerprint.

> BEWARE: in plugin version < 6 you had to use SHA1, now it's SHA256 for iOS and Android (for Windows it's still SHA1 though).

```javascript
  var server = "https://build.phonegap.com";
  var fingerprint = "C6 2D 93 39 C2 9F 82 8E 1E BE FD DC 2D 7B 7D 24 31 1A 59 E1 0B 4B C8 04 6E 21 F6 FA A2 37 11 45";

  window.plugins.sslCertificateChecker.check(
          successCallback,
          errorCallback,
          server,
          fingerprint);

   function successCallback(message) {
     alert(message);
     // Message is always: CONNECTION_SECURE.
     // Now do something with the trusted server.
   }

   function errorCallback(message) {
     alert(message);
     if (message === "CONNECTION_NOT_SECURE") {
       // There is likely a man in the middle attack going on, be careful!
     } else if (message.indexOf("CONNECTION_FAILED") >- 1) {
       // There was no connection (yet). Internet may be down. Try again (a few times) after a little timeout.
     }
   }
```

Need more than one fingerprint? In case your certificate is about to expire, you can add it already to your app, while still supporting the old certificate.
Note you may want to force clients to update the app when the new certificate is activated.
```javascript
  // an array of any number of fingerprints
  var fingerprints = ["C6 2D 93 39 C2 9F 82 8E 1E BE FD DC 2D 7B 7D 24 31 1A 59 E1 0B 4B C8 04 6E 21 F6 FA A2 37 11 45", "SE CO ND", ..];

  window.plugins.sslCertificateChecker.check(
          successCallback,
          errorCallback,
          server,
          fingerprints);
```


## 4. Credits
The iOS code was inspired by a closed-source, purely native certificate pinning implementation by Rob Bosman.

[Jacob Weber](https://github.com/EddyVerbruggen/SSLCertificateChecker-PhoneGap-Plugin/issues/9) did some great work to support checking multiple certificates on iOS, thanks!
