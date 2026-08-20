class UserModel {
  final int? userId;
  final String name;
  final String? email;
  final DateTime createdAt;

  UserModel({
    this.userId,
    required this.name,
    this.email,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'name': name,
      'email': email,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      userId: map['user_id'] as int?,
      name: map['name'] as String,
      email: map['email'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  UserModel copyWith({
    int? userId,
    String? name,
    String? email,
    DateTime? createdAt,
  }) {
    return UserModel(
      userId: userId ?? this.userId,
      name: name ?? this.name,
      email: email ?? this.email,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
