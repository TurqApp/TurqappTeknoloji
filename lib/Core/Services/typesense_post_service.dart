import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';

class TypesensePostService {
  TypesensePostService._();

  static final TypesensePostService instance = TypesensePostService._();

  final List<({String label, FirebaseFunctions fn})> _targets =
      <({String label, FirebaseFunctions fn})>[
    (label: 'default', fn: FirebaseFunctions.instance),
    (
      label: 'us-central1',
      fn: FirebaseFunctions.instanceFor(region: 'us-central1'),
    ),
    (
      label: 'europe-west1',
      fn: FirebaseFunctions.instanceFor(region: 'europe-west1'),
    ),
  ];

  Future<Map<String, Map<String, dynamic>>> getPostCardsByIds(
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
            await target.fn.httpsCallable('f15_getPostCardsByIdsCallable').call(
          <String, dynamic>{'ids': cleaned},
        );
        final data = Map<String, dynamic>.from(response.data as Map? ?? {});
        final hits = (data['hits'] as List<dynamic>?) ?? const <dynamic>[];
        final out = <String, Map<String, dynamic>>{};
        for (final rawHit in hits) {
          final hitMap = rawHit is Map ? Map<String, dynamic>.from(rawHit) : null;
          if (hitMap == null) continue;
          final id = (hitMap['id'] ?? hitMap['docID'] ?? '').toString().trim();
          if (id.isEmpty) continue;
          out[id] = hitMap;
        }
        return out;
      } catch (e) {
        lastError = e;
      }
    }

    throw lastError ?? Exception('typesense_post_cards_failed');
  }

  Future<void> syncPostById(String postId) async {
    final cleaned = postId.trim();
    if (cleaned.isEmpty) return;

    Object? lastError;
    for (final target in _targets) {
      try {
        debugPrint(
          '[TypesensePostService] syncPostById start postId=$cleaned target=${target.label}',
        );
        await target.fn.httpsCallable('f15_syncPostToTypesenseCallable').call(
          <String, dynamic>{'postId': cleaned},
        );
        debugPrint(
          '[TypesensePostService] syncPostById success postId=$cleaned target=${target.label}',
        );
        return;
      } catch (e) {
        debugPrint(
          '[TypesensePostService] syncPostById failed postId=$cleaned target=${target.label} error=$e',
        );
        lastError = e;
      }
    }

    debugPrint(
      '[TypesensePostService] syncPostById giving up postId=$cleaned error=$lastError',
    );
    throw lastError ?? Exception('typesense_post_sync_failed');
  }
}
