# road_eye

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.


## Icono 

```yml
dev_dependencies:
  flutter_launcher_icons: "^0.13.1"

flutter_launcher_icons:
  android: true
  #ios: true
  image_path: "assets/img/icon.png"
  min_sdk_android: 21
```

imagen de minino 512x512

    $ flutter pub run flutter_launcher_icons:main

https://pub.dev/packages/flutter_launcher_icons

## Splash

```yml
dev_dependencies:
  flutter_native_splash: ^2.2.16

flutter_native_splash:
  android: true
  #ios: true
  #color: "#ffffff"
  #image: assets/splash.png
  background_image: assets/img/splash_background.png
  branding: assets/img/splash_branding.png
  image: assets/img/splash_icon.png
  background_image_dark:
  assets/img/splash_background_dark.png
  branding_dark: assets/img/splash_branding_dark.png
  image_dark: assets/img/splash_icon_dark.png
```

    $ flutter pub run flutter_native_splash:create

https://pub.dev/packages/flutter_native_splash
