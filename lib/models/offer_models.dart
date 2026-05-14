class OfferModel {
  final String id;
  final String title;
  final String description;
  final String business;
  final int pointsCost;

  const OfferModel({
    required this.id, required this.title, required this.description,
    required this.business, required this.pointsCost,
  });
}