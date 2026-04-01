import 'package:cloud_functions/cloud_functions.dart';

class TypesenseEducationAdminService {
  TypesenseEducationAdminService._();

  static TypesenseEducationAdminService? _instance;
  static TypesenseEducationAdminService? maybeFind() => _instance;

  static TypesenseEducationAdminService ensure() =>
      maybeFind() ?? (_instance = TypesenseEducationAdminService._());

  static TypesenseEducationAdminService get instance => ensure();

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

  Future<Map<String, dynamic>> ensureCollection({String? entity}) async {
    final response = await _functions
        .httpsCallable('f21_ensureEducationTypesenseCollectionCallable')
        .call(<String, dynamic>{
      if ((entity ?? '').trim().isNotEmpty) 'entity': entity,
    });
    return _cloneResponseMap(
      Map<String, dynamic>.from(response.data as Map? ?? const {}),
    );
  }

  Future<Map<String, dynamic>> reindex({
    required String entity,
    int limit = 200,
    String? cursor,
    bool dryRun = false,
  }) async {
    final response = await _functions
        .httpsCallable('f21_reindexEducationToTypesenseCallable')
        .call(<String, dynamic>{
      'entity': entity,
      'limit': limit,
      if ((cursor ?? '').trim().isNotEmpty) 'cursor': cursor,
      'dryRun': dryRun,
    });
    return _cloneResponseMap(
      Map<String, dynamic>.from(response.data as Map? ?? const {}),
    );
  }
}
