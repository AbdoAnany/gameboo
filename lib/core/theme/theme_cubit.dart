import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Theme States
abstract class ThemeState extends Equatable {
  const ThemeState();

  @override
  List<Object?> get props => [];
}

class ThemeInitial extends ThemeState {}

class ThemeChanged extends ThemeState {
  final ThemeMode themeMode;

  const ThemeChanged(this.themeMode);

  @override
  List<Object?> get props => [themeMode];
}

// Theme Cubit
class ThemeCubit extends Cubit<ThemeState> {
  static const String _themeKey = 'theme_mode';

  ThemeCubit() : super(ThemeInitial()) {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final themeModeString = prefs.getString(_themeKey) ?? 'system';

      final themeMode = switch (themeModeString) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      };

      emit(ThemeChanged(themeMode));
    } catch (e) {
      emit(const ThemeChanged(ThemeMode.system));
    }
  }

  Future<void> setThemeMode(ThemeMode themeMode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final themeModeString = switch (themeMode) {
        ThemeMode.light => 'light',
        ThemeMode.dark => 'dark',
        ThemeMode.system => 'system',
      };

      await prefs.setString(_themeKey, themeModeString);
      emit(ThemeChanged(themeMode));
    } catch (e) {
      // Handle error if needed
      emit(ThemeChanged(themeMode));
    }
  }

  Future<void> toggleTheme() async {
    if (state is ThemeChanged) {
      final currentTheme = (state as ThemeChanged).themeMode;
      final newTheme = currentTheme == ThemeMode.light
          ? ThemeMode.dark
          : ThemeMode.light;
      await setThemeMode(newTheme);
    } else {
      await setThemeMode(ThemeMode.dark);
    }
  }

  ThemeMode get currentThemeMode {
    if (state is ThemeChanged) {
      return (state as ThemeChanged).themeMode;
    }
    return ThemeMode.system;
  }
}
