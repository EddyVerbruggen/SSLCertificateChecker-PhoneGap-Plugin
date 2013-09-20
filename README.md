# PhoneGap SSL Certificate Checker plugin

for iOS and (soon) Android, by [Eddy Verbruggen](http://www.x-services.nl)


TODO



1. [Description](https://github.com/EddyVerbruggen/CameraRoll-PhoneGap-Plugin#1-description)
2. [Installation](https://github.com/EddyVerbruggen/CameraRoll-PhoneGap-Plugin#2-installation)
	2. [Automatically (CLI / Plugman)](https://github.com/EddyVerbruggen/CameraRoll-PhoneGap-Plugin#automatically-cli--plugman)
	2. [Manually](https://github.com/EddyVerbruggen/CameraRoll-PhoneGap-Plugin#manually)
	2. [PhoneGap Build](https://github.com/EddyVerbruggen/CameraRoll-PhoneGap-Plugin#phonegap-build)
3. [Usage](https://github.com/EddyVerbruggen/CameraRoll-PhoneGap-Plugin#3-usage)
4. [License](https://github.com/EddyVerbruggen/CameraRoll-PhoneGap-Plugin#5-license)

## 1. Description

This plugin allows you to use photos from the cameraroll (photo album) of the mobile device.

* Compatible with [Cordova Plugman](https://github.com/apache/cordova-plugman) and ready for PhoneGap 3.0
* Submitted and waiting for approval at PhoneGap Build ([more information](https://build.phonegap.com/plugins))
* You can count the total number of photos and/or videos.
* You can find photos only (videos would likely crash your app).
* You can limit the number of returned photos by passing a `max` parameter.
* All methods work without showing the cameraroll to the user. Your app never looses control.

### iOS specifics
* Supported methods: `find`, `count`.

### Android specifics
* Work in progress.. support will be added soon

## 2. Installation

### Automatically (CLI / Plugman)
Calendar is compatible with [Cordova Plugman](https://github.com/apache/cordova-plugman) and ready for the [PhoneGap 3.0 CLI](http://docs.phonegap.com/en/3.0.0/guide_cli_index.md.html#The%20Command-line%20Interface_add_features), here's how it works with the CLI:

```
$ phonegap local plugin add https://github.com/EddyVerbruggen/CameraRoll-PhoneGap-Plugin.git
```
or
```
$ cordova plugin add https://github.com/EddyVerbruggen/CameraRoll-PhoneGap-Plugin.git
```
don't forget to run this command afterwards:
```
$ cordova build
```

### Manually

1\. Add the following xml to your `config.xml`:
```xml
<!-- for iOS -->
<feature name="CameraRoll">
	<param name="ios-package" value="CameraRoll" />
</feature>
```

```xml
<!-- for Android as plugin (deprecated) -->
<plugin name="Calendar" value="nl.xservices.plugins.CameraRoll"/>
```

```xml
<!-- for Android as feature -->
<feature name="CameraRoll">
  <param name="android-package" value="nl.xservices.plugins.CameraRoll" />
</feature>
```

2\. Grab a copy of CameraRoll.js, add it to your project and reference it in `index.html`:
```html
<script type="text/javascript" src="js/CameraRoll.js"></script>
```

3\. Download the source files for iOS and/or Android and copy them to your project.

iOS: Copy the four `.h` and `.m` to `platforms/ios/<ProjectName>/Plugins`

Android: Copy `CameraRoll.java` to `platforms/android/src/nl/xservices/plugins` (create the folders)

### PhoneGap Build

Using CameraRoll with PhoneGap Build requires these simple steps:

1\. Add the following xml to your `config.xml` to always use the latest version of this plugin:
```xml
<gap:plugin name="nl.x-services.plugins.cameraroll" />
```
or to use this exact version:
```xml
<gap:plugin name="nl.x-services.plugins.cameraroll" version="1.0" />
```

2\. Reference the JavaScript code in your `index.html`:
```html
<!-- below <script src="phonegap.js"></script> -->
<script src="js/plugins/CameraRoll.js"></script>
```


## 3. Usage

Counting the number of photos in the photo library:

```javascript
  // prep some variables
  var includePhotos = true;
  var includeVideos = false;
  window.plugins.cameraRoll.count(includePhotos, includeVideos, cameraRollCountResult, cameraRollError);

  function showImageCount(count) {
    alert("Found " + count + " photos");
  }
```

Find and show max 10 photos from the photo library:

```javascript
  var maxAssets = 10;
  window.plugins.cameraRoll.find(maxAssets, cameraRollFindResult, cameraRollError);

  function cameraRollFindResult(photos) {
    var content = '';
    for (var i in photos) {
      content += '<br/><img src="data:image/png;base64,'+photos[i]+'" style="max-width:240px"/>';
    }
    document.getElementById("imgContainer").innerHTML = content;
}```


## 4. License

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
