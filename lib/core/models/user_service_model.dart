class UserService {
  final int? id;
  final String name;
  final double rate;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserService({
    this.id,
    required this.name,
    required this.rate,
    required this.createdAt,
    required this.updatedAt,
  });

  UserService copyWith({
    int? id,
    String? name,
    double? rate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      UserService(
        id: id ?? this.id,
        name: name ?? this.name,
        rate: rate ?? this.rate,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'name': name,
        'rate': rate,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  factory UserService.fromMap(Map<String, dynamic> map) => UserService(
        id: map['id'] as int?,
        name: map['name'] as String,
        rate: (map['rate'] as num).toDouble(),
        createdAt: DateTime.parse(map['created_at'] as String),
        updatedAt: DateTime.parse(map['updated_at'] as String),
      );
}
