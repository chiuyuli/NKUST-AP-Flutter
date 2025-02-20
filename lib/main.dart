import 'dart:io';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart'
    show debugDefaultTargetPlatformOverride;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:nkust_ap/app.dart';
import 'package:nkust_ap/config/constants.dart';
import 'package:nkust_ap/res/app_icon.dart';
import 'package:nkust_ap/res/app_theme.dart';
import 'package:nkust_ap/utils/preferences.dart';

void main() async {
  bool isInDebugMode = Constants.isInDebugMode;
  await Preferences.init();
  AppIcon.code =
      Preferences.getString(Constants.PREF_ICON_STYLE_CODE, AppIcon.OUTLINED);
  AppTheme.code =
      Preferences.getString(Constants.PREF_THEME_CODE, AppTheme.LIGHT);
  if (kIsWeb) {
  } else if (Platform.isIOS || Platform.isAndroid) {
    Crashlytics.instance.enableInDevMode = isInDebugMode;
    // Pass all uncaught errors from the framework to Crashlytics.
    FlutterError.onError = Crashlytics.instance.recordFlutterError;
  } else {
    _setTargetPlatformForDesktop();
  }
  runApp(
    MyApp(
      themeData: AppTheme.data,
    ),
  );
}

void _setTargetPlatformForDesktop() {
  TargetPlatform targetPlatform;
  if (Platform.isMacOS) {
    targetPlatform = TargetPlatform.iOS;
  } else if (Platform.isLinux || Platform.isWindows) {
    targetPlatform = TargetPlatform.android;
  }
  if (targetPlatform != null) {
    debugDefaultTargetPlatformOverride = targetPlatform;
  }
}
