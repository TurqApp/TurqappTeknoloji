import 'package:cloud_functions/cloud_functions.dart';
import 'package:turqappv2/Core/Services/app_cloud_functions.dart';

class TypesenseUserService {
  TypesenseUserService._();

  static TypesenseUserService? _instance;
  static TypesenseUserService? maybeFind() => _instance;

  static TypesenseUserService ensure() =>
      maybeFind() ?? (_instance = TypesenseUserService._());

  static TypesenseUserService get instance => ensure();

  final List<({String label, FirebaseFunctions fn})> _targets =
      <({String label, FirebaseFunctions fn})>[
    (label: 'default', fn: AppCloudFunctions.instance),
    (
      label: 'us-central1',
      fn: AppCloudFunctions.instanceFor(region: 'us-central1'),
    ),
    (
      label: 'europe-west1',
      fn: AppCloudFunctions.instanceFor(region: 'europe-west1'),
    ),
  ];

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

  static Map<String, dynamic> _cloneHitMap(Map<String, dynamic> source) {
    return source.map(
      (key, value) => MapEntry(key, _cloneValue(value)),
    );
  }

  Future<Map<String, Map<String, dynamic>>> getUserCardsByIds(
    List<String> ids,
  ) async {
    final cleaned = ids
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList(growable: false);
    if (cleaned.isEmpty) return const <String, Map<String, dynamic>>{};

    Object? lastError;
    for (final target in _targets) {
      try {
        final response =
            await target.fn.httpsCallable('f15_getUserCardsByIdsCallable').call(
          <String, dynamic>{'ids': cleaned},
        );
        final data = Map<String, dynamic>.from(response.data as Map? ?? {});
        final hits = (data['hits'] as List<dynamic>?) ?? const <dynamic>[];
        final out = <String, Map<String, dynamic>>{};
        for (final rawHit in hits) {
          final hitMap =
              rawHit is Map ? Map<String, dynamic>.from(rawHit) : null;
          if (hitMap == null) continue;
          final id = (hitMap['id'] ?? '').toString().trim();
          if (id.isEmpty) continue;
          out[id] = _cloneHitMap(hitMap);
        }
        return out;
      } catch (e) {
        lastError = e;
      }
    }

    throw lastError ?? Exception('typesense_user_cards_failed');
  }
}
