## Versions

## 1.0.12
    * Fixed Android MethodChannel not working after back press or app background/foreground transitions.
    * Android PlatformView: stable view keys to avoid null `getView()` and duplicate parent attachment when rebuilding.
    * Android native ad PlatformView: clear IME/focus on dispose so Flutter text fields can show the keyboard again.

## 1.0.10
    * Fixed iOS platform channel thread issue by ensuring callback messages are sent on the main thread.

## 1.0.9
    * The minimum supported version of the iOS SDK has been updated to 6.5.34.
    * Native ads in PlatformView mode now support releasing iOS native objects.
    * Fixed a crash on iOS caused by the native ad Flutter API not passing in Scene/SceneID.

## 1.0.8
    * Supports ad source event callback & loaded multiple callbacks
    * Migrate for flutter’s gradle plugins. For more information, please refer to: [Deprecated imperative apply of Flutter's Gradle plugins](https://docs.flutter.dev/release/breaking-changes/flutter-gradle-plugin-apply)

## 1.0.7
    * Fix bugs.

## 1.0.6
    * Fix bugs.

## 1.0.5
    * Support custom parameters during display.
    * Supports entering scene statistics function.
    * Support automatic load API for rewardedvideo and interstitial.

## 1.0.4
    * Add support for DebuggerUI.

## 1.0.3
    * Optimizing native ads for iOS.

## 1.0.2
    * Support Google UMP SDK.

## 1.0.1
    * Fix scene ID related issues on iOS.

## 1.0.0
    * Initial implementation for Anythink SDK.
