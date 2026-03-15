class MarketOfferModel {
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
      offerPrice: (json['offerPrice'] as num?)?.toDouble() ?? 0,
      currency: (json['currency'] ?? 'TRY').toString(),
      status: (json['status'] ?? 'pending').toString(),
      createdAt: (json['createdAt'] as num?)?.toInt() ?? 0,
      message: (json['message'] ?? '').toString(),
      coverImageUrl: (json['coverImageUrl'] ?? '').toString(),
      locationText: (json['locationText'] ?? '').toString(),
    );
  }
}
