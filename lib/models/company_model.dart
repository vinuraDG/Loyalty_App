class CompanyModel {
  final int    id;   // synthetic: index in the list (0-based) or from a known field
  final String name;

  const CompanyModel({required this.id, required this.name});

  factory CompanyModel.fromMap(Map<String, dynamic> m, {int fallbackIndex = 0}) {
    // GetAllCompanies has NO Id field — only Name, Address, Logo.
    // We store the list index as the id so callers can reference by position.
    final name = (m['Name'] ?? m['CompanyName'] ?? m['name'] ?? '').toString().trim();
    return CompanyModel(
      id:   fallbackIndex,
      name: name.isEmpty ? 'Company ${fallbackIndex + 1}' : name,
    );
  }

  /// Short label for filter tabs / biz cards (max 12 chars).
  String get label {
    if (name.length <= 12) return name;
    return '${name.substring(0, 11)}…';
  }

  @override
  String toString() => 'CompanyModel(id: $id, name: $name)';
}