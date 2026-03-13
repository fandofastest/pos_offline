enum UserRole { admin, cashier }

class User {
  const User({
    required this.id,
    required this.username,
    required this.role,
  });

  final int id;
  final String username;
  final UserRole role;
}
