class MarketOfferModel {
  static int _asInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse((value ?? '').toString()) ?? 0;
  }

  static double _asDouble(Object? value) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse((value ?? '').toString()) ?? 0;
  }

  MarketOfferModel({
    required this.id,
    required this.itemId,
    required this.itemTitle,
    required this.buyerId,
    required this.sellerId,
    required this.offerPrice,
    required this.currency,
    required this.status,
    required this.createdAt,
    this.updatedAt = 0,
    this.respondedAt = 0,
    this.message = '',
    this.coverImageUrl = '',
    this.locationText = '',
  });

  final String id;
  final String itemId;
  final String itemTitle;
  final String buyerId;
  final String sellerId;
  final double offerPrice;
  final String currency;
  final String status;
  final int createdAt;
  final int updatedAt;
  final int respondedAt;
  final String message;
  final String coverImageUrl;
  final String locationText;

  factory MarketOfferModel.fromMap(Map<String, dynamic> json, String docId) {
    return MarketOfferModel(
      id: docId,
      itemId: (json['itemId'] ?? '').toString(),
      itemTitle: (json['itemTitle'] ?? '').toString(),
      buyerId: (json['buyerId'] ?? '').toString(),
      sellerId: (json['sellerId'] ?? '').toString(),
      offerPrice: _asDouble(json['offerPrice']),
      currency: (json['currency'] ?? 'TRY').toString(),
      status: (json['status'] ?? 'pending').toString(),
      createdAt: _asInt(json['createdAt']),
      updatedAt: _asInt(json['updatedAt']),
      respondedAt: _asInt(json['respondedAt']),
      message: (json['message'] ?? '').toString(),
      coverImageUrl: (json['coverImageUrl'] ?? '').toString(),
      locationText: (json['locationText'] ?? '').toString(),
    );
  }
}
