import 'package:perfectshelter/utils/hive_keys.dart';
import 'package:perfectshelter/utils/hive_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive/hive.dart';

class AppThemeCubit extends Cubit<ThemeMode> {
  AppThemeCubit() : super(_getInitialThemeMode());

  static ThemeMode _getInitialThemeMode() {
    final savedTheme = HiveUtils.getCurrentTheme();
    if (savedTheme == 'system') {
      return ThemeMode.system;
    } else if (savedTheme == 'dark') {
      return ThemeMode.dark;
    } else {
      return ThemeMode.light;
    }
  }

  void changeTheme(ThemeMode themeMode) {
    // Save the theme preference
    String themeValue;
    switch (themeMode) {
      case ThemeMode.system:
        themeValue = 'system';
      case ThemeMode.dark:
        themeValue = 'dark';
      case ThemeMode.light:
        themeValue = 'light';
    }

    Hive.box<dynamic>(HiveKeys.themeBox).put(HiveKeys.currentTheme, themeValue);
    emit(themeMode);
  }

  bool get isDarkMode {
    if (state == ThemeMode.system) {
      final brightness =
          WidgetsBinding.instance.platformDispatcher.platformBrightness;
      return brightness == Brightness.dark;
    }
    return state == ThemeMode.dark;
  }
}
