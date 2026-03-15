import 'package:cloud_firestore/cloud_firestore.dart';

class MarketItemModel {
  MarketItemModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.price,
    required this.currency,
    required this.categoryKey,
    required this.categoryPath,
    required this.locationText,
    required this.city,
    required this.district,
    required this.coverImageUrl,
    required this.imageUrls,
    required this.sellerName,
    this.sellerUsername = '',
    this.sellerPhotoUrl = '',
    this.sellerPhoneNumber = '',
    required this.contactPreference,
    required this.status,
    required this.createdAt,
    this.favoriteCount = 0,
    this.offerCount = 0,
    this.isNegotiable = false,
    this.attributes = const <String, dynamic>{},
  });

  final String id;
  final String userId;
  final String title;
  final String description;
  final double price;
  final String currency;
  final String categoryKey;
  final List<String> categoryPath;
  final String locationText;
  final String city;
  final String district;
  final String coverImageUrl;
  final List<String> imageUrls;
  final String sellerName;
  final String sellerUsername;
  final String sellerPhotoUrl;
  final String sellerPhoneNumber;
  final String contactPreference;
  final String status;
  final int createdAt;
  final int favoriteCount;
  final int offerCount;
  final bool isNegotiable;
  final Map<String, dynamic> attributes;

  String get categoryLabel {
    if (categoryPath.isNotEmpty) return categoryPath.last;
    return '';
  }

  bool get canShowPhone => contactPreference == 'phone';

  factory MarketItemModel.fromMap(Map<String, dynamic> json, String docId) {
    final seller =
        Map<String, dynamic>.from(json['seller'] as Map? ?? const {});
    final categoryPath = (json['categoryPath'] as List<dynamic>? ?? const [])
        .map((e) => e.toString())
        .where((e) => e.trim().isNotEmpty)
        .toList(growable: false);
    final imageUrls = (json['imageUrls'] as List<dynamic>? ?? const [])
        .map((e) => e.toString())
        .where((e) => e.trim().isNotEmpty)
        .toList(growable: false);
    return MarketItemModel(
      id: docId,
      userId: (json['userId'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      price: (json['price'] as num?)?.toDouble() ?? 0,
      currency: (json['currency'] ?? 'TRY').toString(),
      categoryKey: (json['categoryKey'] ?? '').toString(),
      categoryPath: categoryPath,
      locationText: (json['locationText'] ?? '').toString(),
      city: (json['city'] ?? '').toString(),
      district: (json['district'] ?? '').toString(),
      coverImageUrl: (json['coverImageUrl'] ?? '').toString(),
      imageUrls: imageUrls,
      sellerName: (seller['name'] ?? json['sellerName'] ?? '').toString(),
      sellerUsername:
          (seller['username'] ?? json['sellerUsername'] ?? '').toString(),
      sellerPhotoUrl:
          (seller['photoUrl'] ?? json['sellerPhotoUrl'] ?? '').toString(),
      sellerPhoneNumber: (seller['phoneNumber'] ??
              json['sellerPhoneNumber'] ??
              json['phoneNumber'] ??
              '')
          .toString(),
      contactPreference:
          (json['contactPreference'] ?? 'message_only').toString(),
      status: (json['status'] ?? 'active').toString(),
      createdAt: _toMillis(json['createdAt']),
      favoriteCount: (json['favoriteCount'] as num?)?.toInt() ?? 0,
      offerCount: (json['offerCount'] as num?)?.toInt() ?? 0,
      isNegotiable: json['isNegotiable'] == true,
      attributes: Map<String, dynamic>.from(
        json['attributes'] as Map? ?? const {},
      ),
    );
  }

  factory MarketItemModel.fromJson(Map<String, dynamic> json) {
    return MarketItemModel.fromMap(json, (json['id'] ?? '').toString());
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'description': description,
      'price': price,
      'currency': currency,
      'categoryKey': categoryKey,
      'categoryPath': categoryPath,
      'locationText': locationText,
      'city': city,
      'district': district,
      'coverImageUrl': coverImageUrl,
      'imageUrls': imageUrls,
      'sellerName': sellerName,
      'sellerUsername': sellerUsername,
      'sellerPhotoUrl': sellerPhotoUrl,
      'sellerPhoneNumber': sellerPhoneNumber,
      'contactPreference': contactPreference,
      'status': status,
      'createdAt': createdAt,
      'favoriteCount': favoriteCount,
      'offerCount': offerCount,
      'isNegotiable': isNegotiable,
      'attributes': attributes,
    };
  }

  static int _toMillis(dynamic value) {
    if (value is Timestamp) return value.millisecondsSinceEpoch;
    if (value is num) return value.toInt();
    return 0;
  }
}
