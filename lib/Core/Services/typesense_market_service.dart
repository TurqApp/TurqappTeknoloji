import 'package:cloud_functions/cloud_functions.dart';

class TypesenseMarketSearchService {
  TypesenseMarketSearchService._();

  static final TypesenseMarketSearchService instance =
      TypesenseMarketSearchService._();

  final FirebaseFunctions _functions =
      FirebaseFunctions.instanceFor(region: 'us-central1');

  Future<List<String>> searchDocIds({
    required String query,
    int limit = 30,
    int page = 1,
    String? categoryKey,
    String? city,
    String? district,
  }) async {
    final normalized = query.trim();
    if (normalized.isEmpty) return [];

    final callable = _functions.httpsCallable('f25_searchMarketCallable');
    final response = await callable.call(<String, dynamic>{
      'q': normalized,
      'limit': limit,
      'page': page,
      if ((categoryKey ?? '').trim().isNotEmpty) 'categoryKey': categoryKey,
      if ((city ?? '').trim().isNotEmpty) 'city': city,
      if ((district ?? '').trim().isNotEmpty) 'district': district,
    });

    final data = Map<String, dynamic>.from(response.data as Map? ?? {});
    final hits = (data['hits'] as List<dynamic>?) ?? const [];
    final ids = <String>[];

    for (final rawHit in hits) {
      final hitMap = rawHit is Map ? Map<String, dynamic>.from(rawHit) : null;
      if (hitMap == null) continue;
      final docId = (hitMap['docId'] ?? hitMap['id'])?.toString().trim() ?? '';
      if (docId.isNotEmpty) ids.add(docId);
    }

    return ids;
  }
}
