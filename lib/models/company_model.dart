class CompanyModel {
  final int    Id;
  final String name;        // full name from backend Name field
  final String displayName; // short name from backend DisplayName field
  final String phoneNo;     // company phone number from backend PhoneNo field

  const CompanyModel({
    required this.Id,
    required this.name,
    required this.displayName,
    this.phoneNo = '',
  });

  factory CompanyModel.fromMap(Map<String, dynamic> m, {int fallbackIndex = 0}) {
    final name = (m['Name'] ?? m['CompanyName'] ?? m['name'] ?? '').toString().trim();
    final raw  = (m['DisplayName'] ?? m['displayName'] ?? '').toString().trim();
    final fallback = name.isNotEmpty ? name : 'Company ${fallbackIndex + 1}';

    final idRaw = m['Id'] ;
    final Id = idRaw is int ? idRaw : int.tryParse(idRaw.toString()) ?? 0;
    return CompanyModel(
      Id:          Id,
      name:        fallback,
      displayName: raw.isNotEmpty ? raw : fallback,
      phoneNo:     (m['PhoneNo'] ?? m['Phone'] ?? m['phoneNo'] ?? '').toString().trim(),
    );
  }

  @override
  String toString() => 'CompanyModel(Id: $Id, name: $name, displayName: $displayName, phoneNo: $phoneNo)';
}
