import 'package:loyalty_app/core/constants/app_constants.dart';

class CompanyModel {
  final int       Id;
  final String    name;
  final String    displayName;
  final String    phoneNo;
  final int       transactionCompanyId;
  final List<int> redeemCompanies;

  const CompanyModel({
    required this.Id,
    required this.name,
    required this.displayName,
    this.phoneNo = '',
    this.transactionCompanyId = 0,
    this.redeemCompanies = const [],
  });

  factory CompanyModel.fromMap(Map<String, dynamic> m, {int fallbackIndex = 0}) {
    final name    = (m['Name'] ?? m['CompanyName'] ?? m['name'] ?? '').toString().trim();
    final raw     = (m['DisplayName'] ?? m['displayName'] ?? '').toString().trim();
    final fallback = name.isNotEmpty ? name : 'Company ${fallbackIndex + 1}';

    final idRaw = m['Id'];
    final id    = idRaw is int ? idRaw : int.tryParse(idRaw.toString()) ?? 0;

    final tcIdRaw = m['TransactionCompanyId'];
    final tcId    = tcIdRaw is int ? tcIdRaw : int.tryParse(tcIdRaw.toString()) ?? 0;

    final redeemRaw = m['RedeemCompanies'];
    final redeemCompanies = redeemRaw is List
        ? redeemRaw
            .map((e) => e is int ? e : int.tryParse(e.toString()) ?? 0)
            .where((e) => e > 0)
            .toList()
        : <int>[];

    return CompanyModel(
      Id:                   id,
      name:                 fallback,
      displayName:          raw.isNotEmpty ? raw : fallback,
      phoneNo:              (m['PhoneNo'] ?? m['Phone'] ?? m['phoneNo'] ?? '').toString().trim(),
      transactionCompanyId: tcId,
      redeemCompanies:      redeemCompanies,
    );
  }

  /// True when this company is the active earn company (should NOT appear in the redeem list).
  /// Determined dynamically from AppConstants.activeCompanyId set at employee login.
  bool get isEarnOnly {
    final active = AppConstants.activeCompanyId;
    return active > 0 && transactionCompanyId == active;
  }

  @override
  String toString() =>
      'CompanyModel(Id: $Id, name: $name, displayName: $displayName, '
      'phoneNo: $phoneNo, transactionCompanyId: $transactionCompanyId, '
      'redeemCompanies: $redeemCompanies)';
}
