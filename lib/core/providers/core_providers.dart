import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/app_database.dart';
import '../storage/preferences_service.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  return AppDatabase.instance;
});

final preferencesServiceProvider = Provider<PreferencesService>((ref) {
  return PreferencesService();
});
