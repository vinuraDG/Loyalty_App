class UserModel {
  final String id, name, email, phone, role;
  int totalPoints;
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    this.role = 'customer',
    this.totalPoints = 0,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  String get loyaltyTier {
    if (totalPoints >= 5000) return 'Gold';
    if (totalPoints >= 1000) return 'Silver';
    return 'Bronze';
  }

  String get initials {
    final parts = name.trim().split(' ');
    return parts.length >= 2
        ? '${parts[0][0]}${parts[1][0]}'.toUpperCase()
        : name[0].toUpperCase();
  }

  UserModel copyWith({String? name, int? totalPoints}) => UserModel(
        id: id,
        email: email,
        phone: phone,
        role: role,
        name: name ?? this.name,
        totalPoints: totalPoints ?? this.totalPoints,
        createdAt: createdAt,
      );
}
