import 'package:cloud_functions/cloud_functions.dart';

class TypesenseMarketAdminService {
  TypesenseMarketAdminService._();

  static TypesenseMarketAdminService? _instance;
  static TypesenseMarketAdminService? maybeFind() => _instance;

  static TypesenseMarketAdminService ensure() =>
      maybeFind() ?? (_instance = TypesenseMarketAdminService._());

  static TypesenseMarketAdminService get instance => ensure();

  final FirebaseFunctions _functions =
      FirebaseFunctions.instanceFor(region: 'us-central1');

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

  static Map<String, dynamic> _cloneResponseMap(Map<String, dynamic> source) {
    return source.map(
      (key, value) => MapEntry(key, _cloneValue(value)),
    );
  }

  Future<Map<String, dynamic>> ensureCollection() async {
    final response = await _functions
        .httpsCallable('f25_ensureMarketTypesenseCollectionCallable')
        .call(<String, dynamic>{});
    return _cloneResponseMap(
      Map<String, dynamic>.from(response.data as Map? ?? const {}),
    );
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
    return _cloneResponseMap(
      Map<String, dynamic>.from(response.data as Map? ?? const {}),
    );
  }
}
