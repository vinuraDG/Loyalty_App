class OfferModel {
  final String id;
  final String title;
  final String description;
  final String business;
  final int    pointsCost;
  final String companyPhoneNo;
  // Company.Id — used to filter PointsOwnCompanyId in the ledger for balance lookup.
  final int    companyId;
  // Company.TransactionCompanyId — sent as TransactionCompanyId in RedeemPoints call.
  final int    companyTransactionId;

  const OfferModel({
    required this.id,
    required this.title,
    required this.description,
    required this.business,
    required this.pointsCost,
    this.companyPhoneNo = '',
    this.companyId = 0,
    this.companyTransactionId = 0,
  });
}