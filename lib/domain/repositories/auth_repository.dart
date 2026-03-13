import '../entities/user.dart';

abstract interface class AuthRepository {
  Future<User?> getCurrentUser();
  Future<User> login({required String username, required String password});
  Future<void> logout();
}
