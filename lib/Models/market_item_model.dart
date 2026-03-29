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
    required List<String> categoryPath,
    required this.locationText,
    required this.city,
    required this.district,
    required this.coverImageUrl,
    required List<String> imageUrls,
    required this.sellerName,
    this.sellerUsername = '',
    this.sellerPhotoUrl = '',
    this.sellerRozet = '',
    this.shortId = '',
    this.shortUrl = '',
    this.sellerPhoneNumber = '',
    this.showPhone = false,
    required this.contactPreference,
    required this.status,
    required this.createdAt,
    this.favoriteCount = 0,
    this.offerCount = 0,
    this.viewCount = 0,
    this.isNegotiable = false,
    Map<String, dynamic> attributes = const <String, dynamic>{},
  })  : categoryPath = List<String>.from(categoryPath, growable: false),
        imageUrls = List<String>.from(imageUrls, growable: false),
        attributes = _cloneAttributes(attributes);

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
  final String sellerRozet;
  final String shortId;
  final String shortUrl;
  final String sellerPhoneNumber;
  final bool showPhone;
  final String contactPreference;
  final String status;
  final int createdAt;
  final int favoriteCount;
  final int offerCount;
  final int viewCount;
  final bool isNegotiable;
  final Map<String, dynamic> attributes;

  static dynamic _cloneValue(dynamic value) {
    if (value is Map) {
      return value.map(
        (key, nestedValue) => MapEntry(
          key.toString(),
          _cloneValue(nestedValue),
        ),
      );
    }
    if (value is List) {
      return value.map(_cloneValue).toList(growable: false);
    }
    return value;
  }

  static Map<String, dynamic> _cloneAttributes(Map source) {
    return source.map(
      (key, value) => MapEntry(key.toString(), _cloneValue(value)),
    );
  }

  String get categoryLabel {
    if (categoryPath.isNotEmpty) return categoryPath.last;
    return '';
  }

  bool get canShowPhone =>
      sellerPhoneNumber.trim().isNotEmpty ||
      showPhone ||
      contactPreference == 'phone';

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
      sellerName: (seller['displayName'] ??
              seller['name'] ??
              json['sellerDisplayName'] ??
              json['sellerName'] ??
              '')
          .toString(),
      sellerUsername: (seller['nickname'] ??
              seller['username'] ??
              json['sellerNickname'] ??
              json['sellerUsername'] ??
              '')
          .toString(),
      sellerPhotoUrl: (seller['avatarUrl'] ??
              seller['photoUrl'] ??
              json['sellerAvatarUrl'] ??
              json['sellerPhotoUrl'] ??
              '')
          .toString(),
      sellerRozet:
          (seller['rozet'] ?? json['sellerRozet'] ?? json['sellerBadge'] ?? '')
              .toString(),
      shortId: (json['shortId'] ?? '').toString(),
      shortUrl: (json['shortUrl'] ?? '').toString(),
      sellerPhoneNumber: (seller['phoneNumber'] ??
              json['sellerPhoneNumber'] ??
              json['phoneNumber'] ??
              '')
          .toString(),
      showPhone: json['showPhone'] == true,
      contactPreference:
          (json['contactPreference'] ?? 'message_only').toString(),
      status: (json['status'] ?? 'active').toString(),
      createdAt: _toMillis(json['createdAt']),
      favoriteCount: (json['favoriteCount'] as num?)?.toInt() ?? 0,
      offerCount: (json['offerCount'] as num?)?.toInt() ?? 0,
      viewCount: (json['viewCount'] as num?)?.toInt() ?? 0,
      isNegotiable: json['isNegotiable'] == true,
      attributes: _cloneAttributes(json['attributes'] as Map? ?? const {}),
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
      'categoryPath': List<String>.from(categoryPath, growable: false),
      'locationText': locationText,
      'city': city,
      'district': district,
      'coverImageUrl': coverImageUrl,
      'imageUrls': List<String>.from(imageUrls, growable: false),
      'sellerName': sellerName,
      'sellerUsername': sellerUsername,
      'sellerPhotoUrl': sellerPhotoUrl,
      'sellerRozet': sellerRozet,
      'shortId': shortId,
      'shortUrl': shortUrl,
      'sellerPhoneNumber': sellerPhoneNumber,
      'showPhone': showPhone,
      'contactPreference': contactPreference,
      'status': status,
      'createdAt': createdAt,
      'favoriteCount': favoriteCount,
      'offerCount': offerCount,
      'viewCount': viewCount,
      'isNegotiable': isNegotiable,
      'attributes': _cloneAttributes(attributes),
    };
  }

  MarketItemModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    double? price,
    String? currency,
    String? categoryKey,
    List<String>? categoryPath,
    String? locationText,
    String? city,
    String? district,
    String? coverImageUrl,
    List<String>? imageUrls,
    String? sellerName,
    String? sellerUsername,
    String? sellerPhotoUrl,
    String? sellerRozet,
    String? shortId,
    String? shortUrl,
    String? sellerPhoneNumber,
    bool? showPhone,
    String? contactPreference,
    String? status,
    int? createdAt,
    int? favoriteCount,
    int? offerCount,
    int? viewCount,
    bool? isNegotiable,
    Map<String, dynamic>? attributes,
  }) {
    return MarketItemModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      price: price ?? this.price,
      currency: currency ?? this.currency,
      categoryKey: categoryKey ?? this.categoryKey,
      categoryPath: categoryPath ?? this.categoryPath,
      locationText: locationText ?? this.locationText,
      city: city ?? this.city,
      district: district ?? this.district,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      imageUrls: imageUrls ?? this.imageUrls,
      sellerName: sellerName ?? this.sellerName,
      sellerUsername: sellerUsername ?? this.sellerUsername,
      sellerPhotoUrl: sellerPhotoUrl ?? this.sellerPhotoUrl,
      sellerRozet: sellerRozet ?? this.sellerRozet,
      shortId: shortId ?? this.shortId,
      shortUrl: shortUrl ?? this.shortUrl,
      sellerPhoneNumber: sellerPhoneNumber ?? this.sellerPhoneNumber,
      showPhone: showPhone ?? this.showPhone,
      contactPreference: contactPreference ?? this.contactPreference,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      favoriteCount: favoriteCount ?? this.favoriteCount,
      offerCount: offerCount ?? this.offerCount,
      viewCount: viewCount ?? this.viewCount,
      isNegotiable: isNegotiable ?? this.isNegotiable,
      attributes: attributes ?? this.attributes,
    );
  }

  static int _toMillis(dynamic value) {
    if (value is Timestamp) return value.millisecondsSinceEpoch;
    if (value is num) return value.toInt();
    return 0;
  }
}
