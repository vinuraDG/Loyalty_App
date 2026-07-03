class CompanyModel {
  final int    id;
  final String name;        // full name from backend Name field
  final String displayName; // short name from backend DisplayName field

  const CompanyModel({
    required this.id,
    required this.name,
    required this.displayName,
  });

  factory CompanyModel.fromMap(Map<String, dynamic> m, {int fallbackIndex = 0}) {
    final name = (m['Name'] ?? m['CompanyName'] ?? m['name'] ?? '').toString().trim();
    final raw  = (m['DisplayName'] ?? m['displayName'] ?? '').toString().trim();
    final fallback = name.isNotEmpty ? name : 'Company ${fallbackIndex + 1}';
    return CompanyModel(
      id:          fallbackIndex,
      name:        fallback,
      displayName: raw.isNotEmpty ? raw : fallback,
    );
  }

  @override
  String toString() => 'CompanyModel(id: $id, name: $name, displayName: $displayName)';
}
