import 'package:cloud_functions/cloud_functions.dart';

class TypesenseMarketAdminService {
  TypesenseMarketAdminService._();

  static final TypesenseMarketAdminService instance =
      TypesenseMarketAdminService._();

  final FirebaseFunctions _functions =
      FirebaseFunctions.instanceFor(region: 'us-central1');

  Future<Map<String, dynamic>> ensureCollection() async {
    final response = await _functions
        .httpsCallable('f25_ensureMarketTypesenseCollectionCallable')
        .call(<String, dynamic>{});
    return Map<String, dynamic>.from(response.data as Map? ?? const {});
  }

  Future<Map<String, dynamic>> reindex({
    int limit = 200,
    String? cursor,
    bool dryRun = false,
  }) async {
    final response = await _functions
        .httpsCallable('f25_reindexMarketToTypesenseCallable')
        .call(<String, dynamic>{
      'limit': limit,
      if ((cursor ?? '').trim().isNotEmpty) 'cursor': cursor,
      'dryRun': dryRun,
    });
    return Map<String, dynamic>.from(response.data as Map? ?? const {});
  }
}
