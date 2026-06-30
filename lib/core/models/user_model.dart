class UserModel {
  final int? id;
  final String username;
  final String passwordHash;
  final String role;
  final DateTime createdAt;

  const UserModel({
    this.id,
    required this.username,
    required this.passwordHash,
    this.role = 'manager',
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'username': username,
        'password_hash': passwordHash,
        'role': role,
        'created_at': createdAt.toIso8601String(),
      };

  factory UserModel.fromMap(Map<String, dynamic> map) => UserModel(
        id: map['id'] as int?,
        username: map['username'] as String,
        passwordHash: map['password_hash'] as String,
        role: map['role'] as String? ?? 'manager',
        createdAt: DateTime.parse(map['created_at'] as String),
      );
}
