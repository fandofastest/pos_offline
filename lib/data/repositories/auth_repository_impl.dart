import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../../core/database/app_database.dart';
import '../../core/storage/preferences_service.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._db, this._prefs);

  final AppDatabase _db;
  final PreferencesService _prefs;

  @override
  Future<User?> getCurrentUser() async {
    final userId = await _prefs.getSessionUserId();
    if (userId == null) return null;

    final database = await _db.database;
    final rows = await database.query(
      'users',
      where: 'id = ?',
      whereArgs: [userId],
      limit: 1,
    );
    if (rows.isEmpty) return null;

    return _mapUser(rows.first);
  }

  @override
  Future<User> login({required String username, required String password}) async {
    final database = await _db.database;
    final rows = await database.query(
      'users',
      where: 'username = ?',
      whereArgs: [username],
      limit: 1,
    );

    if (rows.isEmpty) {
      throw Exception('Invalid username or password');
    }

    final row = rows.first;
    final stored = (row['password'] as String?) ?? '';
    final hash = _sha256(password);
    if (stored != hash) {
      throw Exception('Invalid username or password');
    }

    final user = _mapUser(row);
    await _prefs.setSessionUserId(user.id);
    return user;
  }

  @override
  Future<void> logout() async {
    await _prefs.setSessionUserId(null);
  }

  String _sha256(String input) {
    final bytes = utf8.encode(input);
    return sha256.convert(bytes).toString();
  }

  User _mapUser(Map<String, Object?> row) {
    final roleStr = (row['role'] as String?) ?? 'cashier';
    final role = roleStr == 'admin' ? UserRole.admin : UserRole.cashier;

    return User(
      id: row['id'] as int,
      username: row['username'] as String,
      role: role,
    );
  }
}
