import 'enums.dart';

class AppUser {
  final String id;
  final String name;
  final String email;
  final String password;
  final UserRole role;
  final bool active;

  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.password,
    required this.role,
    this.active = true,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'password': password,
        'role': role.name,
        'active': active,
      };

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        id: json['id'] as String,
        name: json['name'] as String,
        email: json['email'] as String,
        password: json['password'] as String,
        role: UserRole.values.byName(json['role'] as String),
        active: json['active'] as bool? ?? true,
      );
}
