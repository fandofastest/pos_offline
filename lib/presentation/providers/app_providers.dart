import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/user.dart';
import '../../core/providers/core_providers.dart';
import '../../core/storage/preferences_service.dart';
import '../providers/auth_providers.dart';

final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  final prefs = ref.watch(preferencesServiceProvider);
  return ThemeModeNotifier(prefs);
});

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier(this._prefs) : super(ThemeMode.system) {
    _load();
  }

  final PreferencesService _prefs;

  Future<void> _load() async {
    final saved = await _prefs.getThemeMode();
    if (saved != null) {
      state = saved;
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    await _prefs.setThemeMode(mode);
  }
}

final sessionProvider = FutureProvider<User?>((ref) async {
  final authRepo = ref.watch(authRepositoryProvider);
  return authRepo.getCurrentUser();
});

final taxRateProvider = StateNotifierProvider<TaxRateNotifier, double>((ref) {
  final prefs = ref.watch(preferencesServiceProvider);
  return TaxRateNotifier(prefs);
});

class TaxRateNotifier extends StateNotifier<double> {
  TaxRateNotifier(this._prefs) : super(0) {
    _load();
  }

  final PreferencesService _prefs;

  Future<void> _load() async {
    state = await _prefs.getTaxRate();
  }

  Future<void> setRate(double rate) async {
    final normalized = rate.isNaN || rate.isInfinite ? 0.0 : rate;
    state = normalized;
    await _prefs.setTaxRate(normalized);
  }
}

final lowStockThresholdProvider = StateNotifierProvider<LowStockThresholdNotifier, int>((ref) {
  final prefs = ref.watch(preferencesServiceProvider);
  return LowStockThresholdNotifier(prefs);
});

class LowStockThresholdNotifier extends StateNotifier<int> {
  LowStockThresholdNotifier(this._prefs) : super(5) {
    _load();
  }

  final PreferencesService _prefs;

  Future<void> _load() async {
    state = await _prefs.getLowStockThreshold();
  }

  Future<void> setThreshold(int value) async {
    final normalized = value < 0 ? 0 : value;
    state = normalized;
    await _prefs.setLowStockThreshold(normalized);
  }
}
