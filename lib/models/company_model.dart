class CompanyModel {
  final int    Id;
  final String name;
  final String displayName;
  final String phoneNo;
  final int    transactionCompanyId;

  const CompanyModel({
    required this.Id,
    required this.name,
    required this.displayName,
    this.phoneNo = '',
    this.transactionCompanyId = 0,
  });

  factory CompanyModel.fromMap(Map<String, dynamic> m, {int fallbackIndex = 0}) {
    final name    = (m['Name'] ?? m['CompanyName'] ?? m['name'] ?? '').toString().trim();
    final raw     = (m['DisplayName'] ?? m['displayName'] ?? '').toString().trim();
    final fallback = name.isNotEmpty ? name : 'Company ${fallbackIndex + 1}';

    final idRaw = m['Id'];
    final id    = idRaw is int ? idRaw : int.tryParse(idRaw.toString()) ?? 0;

    final tcIdRaw = m['TransactionCompanyId'];
    final tcId    = tcIdRaw is int ? tcIdRaw : int.tryParse(tcIdRaw.toString()) ?? 0;

    return CompanyModel(
      Id:                   id,
      name:                 fallback,
      displayName:          raw.isNotEmpty ? raw : fallback,
      phoneNo:              (m['PhoneNo'] ?? m['Phone'] ?? m['phoneNo'] ?? '').toString().trim(),
      transactionCompanyId: tcId,
    );
  }

  /// True for companies that are earn-only (should NOT appear in the redeem list).
  /// Currently the Fuel company (Id 3 / DisplayName "Fuel") is earn-only.
  bool get isEarnOnly => Id == 3;

  @override
  String toString() =>
      'CompanyModel(Id: $Id, name: $name, displayName: $displayName, '
      'phoneNo: $phoneNo, transactionCompanyId: $transactionCompanyId)';
}
