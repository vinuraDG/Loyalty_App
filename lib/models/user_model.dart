class UserModel {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String role;
  final int totalPoints;
  final DateTime createdAt;

  const UserModel({
    required this.id, required this.name, required this.email,
    required this.phone, this.role = 'customer',
    this.totalPoints = 0, required this.createdAt,
  });

  String get loyaltyTier {
    if (totalPoints >= 5000) return 'Gold';
    if (totalPoints >= 1000) return 'Silver';
    return 'Bronze';
  }

  int get pointsToNextTier {
    if (totalPoints >= 5000) return 0;
    if (totalPoints >= 1000) return 5000 - totalPoints;
    return 1000 - totalPoints;
  }

  double get tierProgress {
    if (totalPoints >= 5000) return 1.0;
    if (totalPoints >= 1000) return (totalPoints - 1000) / 4000;
    return totalPoints / 1000;
  }

  String get initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  bool get isEmployee => role == 'employee';

  UserModel copyWith({String? name, String? email, String? phone, int? totalPoints}) => UserModel(
    id: id, role: role, createdAt: createdAt,
    name: name ?? this.name, email: email ?? this.email,
    phone: phone ?? this.phone, totalPoints: totalPoints ?? this.totalPoints,
  );

  Map<String, dynamic> toJson() => {
    'id': id, 'name': name, 'email': email, 'phone': phone,
    'role': role, 'totalPoints': totalPoints, 'createdAt': createdAt.toIso8601String(),
  };

  factory UserModel.fromJson(Map<String, dynamic> j) => UserModel(
    id: j['id'], name: j['name'], email: j['email'], phone: j['phone'],
    role: j['role'] ?? 'customer', totalPoints: j['totalPoints'] ?? 0,
    createdAt: DateTime.parse(j['createdAt']),
  );
}