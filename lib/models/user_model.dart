enum UserTier { bronze, silver, gold, platinum }

class UserModel {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String role;
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

  // ── Computed ──────────────────────────────────────────────
  int get points => totalPoints;

  UserTier get tier {
    if (totalPoints >= 5000) return UserTier.gold;
    if (totalPoints >= 1000) return UserTier.silver;
    return UserTier.bronze;
  }

  String get loyaltyTier {
    switch (tier) {
      case UserTier.gold:     return 'Gold';
      case UserTier.silver:   return 'Silver';
      case UserTier.platinum: return 'Platinum';
      default:                return 'Bronze';
    }
  }

  int get pointsToNextTier {
    if (totalPoints >= 5000) return 0;
    if (totalPoints >= 1000) return 5000 - totalPoints;
    return 1000 - totalPoints;
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