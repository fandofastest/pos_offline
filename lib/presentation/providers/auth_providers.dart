import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/core_providers.dart';
import '../../core/storage/preferences_service.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/repositories/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final db = ref.watch(databaseProvider);
  final PreferencesService prefs = ref.watch(preferencesServiceProvider);
  return AuthRepositoryImpl(db, prefs);
});
