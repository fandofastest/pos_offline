import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  static const _kThemeMode = 'theme_mode';
  static const _kSessionUserId = 'session_user_id';
  static const _kTaxRate = 'tax_rate';
  static const _kLowStockThreshold = 'low_stock_threshold';

  Future<ThemeMode?> getThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final v = prefs.getString(_kThemeMode);
    return switch (v) {
      'system' => ThemeMode.system,
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => null,
    };
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    final v = switch (mode) {
      ThemeMode.system => 'system',
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
    };
    await prefs.setString(_kThemeMode, v);
  }

  Future<int?> getSessionUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_kSessionUserId);
  }

  Future<void> setSessionUserId(int? userId) async {
    final prefs = await SharedPreferences.getInstance();
    if (userId == null) {
      await prefs.remove(_kSessionUserId);
      return;
    }
    await prefs.setInt(_kSessionUserId, userId);
  }

  Future<double> getTaxRate() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_kTaxRate) ?? 0.10;
  }

  Future<void> setTaxRate(double rate) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_kTaxRate, rate);
  }

  Future<int> getLowStockThreshold() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_kLowStockThreshold) ?? 5;
  }

  Future<void> setLowStockThreshold(int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kLowStockThreshold, value);
  }
}
