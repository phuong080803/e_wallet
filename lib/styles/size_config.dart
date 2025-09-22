import 'package:flutter/material.dart';

class SizeConfig {
  SizeConfig._();
  static MediaQueryData? _mediaQueryData;
  static double? _screenWidth;
  static double? _screenHeight;
  static Orientation? _orientation;

  // Safe getters with fallback values
  static double get screenWidth => _screenWidth ?? 375.0; // Default iPhone width
  static double get screenHeight => _screenHeight ?? 812.0; // Default iPhone height
  static Orientation get orientation => _orientation ?? Orientation.portrait;

  static bool get isInitialized => _mediaQueryData != null;

  static void init(BuildContext context) {
    _mediaQueryData = MediaQuery.of(context);
    _screenWidth = _mediaQueryData!.size.width;
    _screenHeight = _mediaQueryData!.size.height;
    _orientation = _mediaQueryData!.orientation;
  }

  // Safe initialization method that can be called multiple times
  static void safeInit(BuildContext context) {
    if (!isInitialized) {
      init(context);
    }
  }
}
