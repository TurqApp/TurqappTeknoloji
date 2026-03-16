import 'package:cloud_functions/cloud_functions.dart';
import 'dart:convert';
import 'package:turqappv2/Models/market_item_model.dart';

class TypesenseMarketSearchService {
  TypesenseMarketSearchService._();

  static final TypesenseMarketSearchService instance =
      TypesenseMarketSearchService._();

  final FirebaseFunctions _functions =
      FirebaseFunctions.instanceFor(region: 'us-central1');

  Future<List<MarketItemModel>> searchItems({
    required String query,
    int limit = 30,
    int page = 1,
    String? docId,
    String? userId,
    String? categoryKey,
    String? city,
    String? district,
  }) async {
    final normalized = query.trim().isEmpty ? '*' : query.trim();

    final callable = _functions.httpsCallable('f25_searchMarketCallable');
    final response = await callable.call(<String, dynamic>{
      'q': normalized,
      'limit': limit,
      'page': page,
      if ((docId ?? '').trim().isNotEmpty) 'docId': docId,
      if ((userId ?? '').trim().isNotEmpty) 'userId': userId,
      if ((categoryKey ?? '').trim().isNotEmpty) 'categoryKey': categoryKey,
      if ((city ?? '').trim().isNotEmpty) 'city': city,
      if ((district ?? '').trim().isNotEmpty) 'district': district,
    });

    final data = Map<String, dynamic>.from(response.data as Map? ?? {});
    final hits = (data['hits'] as List<dynamic>?) ?? const [];
    final items = <MarketItemModel>[];

    for (final rawHit in hits) {
      final hitMap = rawHit is Map ? Map<String, dynamic>.from(rawHit) : null;
      if (hitMap == null) continue;
      final docId = (hitMap['docId'] ?? hitMap['id'])?.toString().trim() ?? '';
      if (docId.isEmpty) continue;
      final attributesJson = (hitMap['attributesJson'] ?? '{}').toString();
      Map<String, dynamic> attributes = const <String, dynamic>{};
      try {
        final decoded = json.decode(attributesJson);
        if (decoded is Map) {
          attributes = Map<String, dynamic>.from(decoded);
        }
      } catch (_) {}
      final sellerPhoneNumber =
          (hitMap['sellerPhoneNumber'] ?? '').toString().trim();
      final contactPreference =
          (hitMap['contactPreference'] ?? 'message_only').toString();
      final showPhone = hitMap['showPhone'] == true ||
          sellerPhoneNumber.isNotEmpty ||
          contactPreference == 'phone';
      items.add(
        MarketItemModel(
          id: docId,
          userId: (hitMap['userId'] ?? '').toString(),
          title: (hitMap['title'] ?? '').toString(),
          description: (hitMap['description'] ?? '').toString(),
          price: (hitMap['price'] as num?)?.toDouble() ?? 0,
          currency: (hitMap['currency'] ?? 'TRY').toString(),
          categoryKey: (hitMap['categoryKey'] ?? '').toString(),
          categoryPath: ((hitMap['categoryPath'] as List<dynamic>?) ?? const [])
              .map((e) => e.toString())
              .where((e) => e.trim().isNotEmpty)
              .toList(growable: false),
          locationText: (hitMap['locationText'] ?? '').toString(),
          city: (hitMap['city'] ?? '').toString(),
          district: (hitMap['district'] ?? '').toString(),
          coverImageUrl: (hitMap['cover'] ?? '').toString(),
          imageUrls: ((hitMap['imageUrls'] as List<dynamic>?) ?? const [])
              .map((e) => e.toString())
              .where((e) => e.trim().isNotEmpty)
              .toList(growable: false),
          sellerName: (hitMap['sellerName'] ?? '').toString(),
          sellerUsername: (hitMap['sellerUsername'] ?? '').toString(),
          sellerPhotoUrl: (hitMap['sellerPhotoUrl'] ?? '').toString(),
          sellerRozet: (hitMap['sellerRozet'] ?? '').toString(),
          sellerPhoneNumber: sellerPhoneNumber,
          showPhone: showPhone,
          contactPreference: contactPreference,
          status: (hitMap['status'] ?? 'active').toString(),
          createdAt: (hitMap['createdAt'] as num?)?.toInt() ?? 0,
          favoriteCount: (hitMap['favoriteCount'] as num?)?.toInt() ?? 0,
          offerCount: (hitMap['offerCount'] as num?)?.toInt() ?? 0,
          viewCount: (hitMap['viewCount'] as num?)?.toInt() ?? 0,
          attributes: attributes,
        ),
      );
    }

    return items;
  }

  Future<MarketItemModel?> fetchByDocId(String docId) async {
    final items = await searchItems(
      query: '*',
      limit: 1,
      page: 1,
      docId: docId,
    );
    if (items.isEmpty) return null;
    return items.first;
  }
}
