class OfferModel {
  final String id;
  final String title;
  final String description;
  final int pointsCost;
  final bool isFeatured;
  final String business;

  const OfferModel({
    required this.id,
    required this.title,
    required this.description,
    required this.pointsCost,
    this.isFeatured = false,
    required this.business,
  });
}