class UserModel {
  final String id;
  final String fullName;
  final String email;
  final String password; // Added for login
  final String role; // ADMIN, MANAGER, STAFF
  final String status; // ACTIVE, LOCKED

  UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.password,
    required this.role,
    required this.status,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      fullName: json['fullName'],
      email: json['email'],
      password: json['password'] ?? '123456', // Default password for backward compatibility
      role: json['role'],
      status: json['status'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'email': email,
      'password': password,
      'role': role,
      'status': status,
    };
  }
}
