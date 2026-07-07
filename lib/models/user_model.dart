class UserModel {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final String role;
  final int totalPoints;
  final String address;
  final DateTime createdAt;

  const UserModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    this.role = 'customer',
    this.totalPoints = 0,
    this.address = '',
    required this.createdAt,
  });

  // ── Computed ───────────────────────────────────────────────────────────────

  /// Full display name, e.g. "Kasun Perera"
  String get name => '$firstName $lastName'.trim();

  /// Two-letter initials from first + last name, e.g. "KP"
  String get initials {
    final f = firstName.isNotEmpty ? firstName[0].toUpperCase() : '';
    final l = lastName.isNotEmpty  ? lastName[0].toUpperCase()  : '';
    return '$f$l'.isNotEmpty ? '$f$l' : '?';
  }

  String get loyaltyTier {
    if (totalPoints >= 5000) return 'Platinum';
    if (totalPoints >= 2000) return 'Gold';
    if (totalPoints >= 500)  return 'Silver';
    return 'Bronze';
  }

  int get pointsToNextTier {
    if (totalPoints >= 5000) return 0;
    if (totalPoints >= 2000) return 5000 - totalPoints;
    if (totalPoints >= 500)  return 2000 - totalPoints;
    return 500 - totalPoints;
  }

  double get tierProgress {
    if (totalPoints >= 5000) return 1.0;
    if (totalPoints >= 2000) return (totalPoints - 2000) / 3000;
    if (totalPoints >= 500)  return (totalPoints - 500) / 1500;
    return totalPoints / 500;
  }

  bool get isEmployee => role == 'employee';

  // ── copyWith ───────────────────────────────────────────────────────────────

  UserModel copyWith({
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
    String? address,
    int? totalPoints,
  }) =>
      UserModel(
        id: id,
        role: role,
        createdAt: createdAt,
        firstName: firstName ?? this.firstName,
        lastName: lastName ?? this.lastName,
        email: email ?? this.email,
        phone: phone ?? this.phone,
        address: address ?? this.address,
        totalPoints: totalPoints ?? this.totalPoints,
      );

  // ── Serialisation ──────────────────────────────────────────────────────────

  Map<String, dynamic> toJson() => {
    'id': id,
    'firstName': firstName,
    'lastName': lastName,
    'email': email,
    'phone': phone,
    'role': role,
    'totalPoints': totalPoints,
    'address': address,
    'createdAt': createdAt.toIso8601String(),
  };

  factory UserModel.fromJson(Map<String, dynamic> j) {
    // ── backwards-compat: if old data only has 'name', split it ──
    String first = j['firstName'] ?? '';
    String last  = j['lastName']  ?? '';
    if (first.isEmpty && last.isEmpty && j['name'] != null) {
      final parts = (j['name'] as String).trim().split(' ');
      first = parts.first;
      last  = parts.length > 1 ? parts.sublist(1).join(' ') : '';
    }

    return UserModel(
      id: j['id'],
      firstName: first,
      lastName: last,
      email: j['email'],
      phone: j['phone'],
      role: j['role'] ?? 'customer',
      totalPoints: j['totalPoints'] ?? 0,
      address: j['address'] ?? '',
      createdAt: DateTime.parse(j['createdAt']),
    );
  }
}