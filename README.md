# PhoneGap SSL Certificate Checker plugin (iOS and Android)

by [Eddy Verbruggen](http://www.x-services.nl)
for PhoneGap 3.0.0 and up.


1. [Description](https://github.com/EddyVerbruggen/SSLCertificateChecker-PhoneGap-Plugin#1-description)
2. [Installation](https://github.com/EddyVerbruggen/SSLCertificateChecker-PhoneGap-Plugin#2-installation)
	2. [Automatically (CLI / Plugman)](https://github.com/EddyVerbruggen/SSLCertificateChecker-PhoneGap-Plugin#automatically-cli--plugman)
	2. [Manually](https://github.com/EddyVerbruggen/SSLCertificateChecker-PhoneGap-Plugin#manually)
	2. [PhoneGap Build](https://github.com/EddyVerbruggen/SSLCertificateChecker-PhoneGap-Plugin#phonegap-build)
3. [Usage](https://github.com/EddyVerbruggen/SSLCertificateChecker-PhoneGap-Plugin#3-usage)
4. [Credits](https://github.com/EddyVerbruggen/SSLCertificateChecker-PhoneGap-Plugin#4-credits)
5. [License](https://github.com/EddyVerbruggen/SSLCertificateChecker-PhoneGap-Plugin#5-license)

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

### Automatically (CLI / Plugman)
SSLCertificateChecker is compatible with [Cordova Plugman](https://github.com/apache/cordova-plugman) and compatible with [PhoneGap 3.0 CLI](http://docs.phonegap.com/en/3.0.0/guide_cli_index.md.html#The%20Command-line%20Interface_add_features), here's how it works with the CLI:

```
$ phonegap local plugin add https://github.com/EddyVerbruggen/SSLCertificateChecker-PhoneGap-Plugin.git
```
or
```
$ cordova plugin add https://github.com/EddyVerbruggen/SSLCertificateChecker-PhoneGap-Plugin.git
```
Run `cordova prepare` or `cordova build` afterwards.

### Manually

1\. Add the following xml to your `config.xml`:
```xml
<!-- for iOS -->
<feature name="SSLCertificateChecker">
	<param name="ios-package" value="SSLCertificateChecker" />
</feature>
```

```xml
<!-- for Android -->
<feature name="SSLCertificateChecker">
  <param name="android-package" value="nl.xservices.plugins.SSLCertificateChecker" />
</feature>
```

2\. Grab a copy of SSLCertificateChecker.js, add it to your project and reference it in `index.html`:
```html
<script type="text/javascript" src="js/SSLCertificateChecker.js"></script>
```

3\. Download the source files for iOS and/or Android and copy them to your project.

Android:
- Copy `SSLCertificateChecker.java` to `platforms/android/src/nl/xservices/plugins` (create the folders)

iOS:
- Add a dependency to `Security.framework`: Go to Your project > Build Phases > Link binaries with libraries > Click `+` > Security.framework.
- Copy `SSLCertificateChecker.*` to `platforms/ios/<ProjectName>/Plugins`.


### PhoneGap Build

Using SSLCertificateChecker with PhoneGap Build requires these simple steps:

1\. Add the following xml to your `config.xml` to always use the latest version of this plugin:
```xml
<gap:plugin name="nl.x-services.plugins.sslcertificatechecker" />
```
or to use this exact version:
```xml
<gap:plugin name="nl.x-services.plugins.sslcertificatechecker" version="3.2" />
```

## 3. Usage

First obtain the fingerprint of the SSL certificate of your server(s).
You can find it f.i. by opening the server URL in Chrome. Then click the green certificate in front of the URL, click 'Connection',
'Certificate details', expand the details and scroll down to the SHA1 fingerprint.

```javascript
  var server = "https://build.phonegap.com";
  var fingerprint = "29 96 0F D5 FE 78 AA EF F4 36 CC 51 79 E4 8C 3C C7 B0 B7 8E"; // valid until sep 2014

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
     if (message == "CONNECTION_NOT_SECURE") {
       // There is likely a man in the middle attack going on, be careful!
     } else if (message == "CONNECTION_FAILED") {
       // There was no connection (yet). Internet may be down. Try again (a few times) after a little timeout.
     }
   }
```

Need more than one fingerprint? In case your certificate is about to expire, you can add it already to your app, while still supporting the old certificate.
Note you may want to force clients to update the app when the new certificate is activated.
```javascript
  var fingerprintNew = "82 CB 5E 46 C2 AB E9 BF 1D EA D1 B9 BB C6 4B DF 25 2A 34 3F";

  window.plugins.sslCertificateChecker.check(
          successCallback,
          errorCallback,
          server,
          fingerprint,
          fingerprintNew);
```


## 4. Credits
The iOS code was inspired by a closed-source, purely native certificate pinning implementation by Rob Bosman.

[Jacob Weber](https://github.com/EddyVerbruggen/SSLCertificateChecker-PhoneGap-Plugin/issues/9) did some great work to support checking multiple certificates on iOS, thanks!

## 5. License

[The MIT License (MIT)](http://www.opensource.org/licenses/mit-license.html)

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
