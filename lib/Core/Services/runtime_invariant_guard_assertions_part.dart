part of 'runtime_invariant_guard.dart';

extension RuntimeInvariantGuardAssertionsPart on RuntimeInvariantGuard {
  void assertIndexInRange({
    required String surface,
    required String invariantKey,
    required int index,
    required int length,
    Map<String, dynamic> payload = const <String, dynamic>{},
  }) {
    if (length <= 0) return;
    if (index >= 0 && index < length) return;
    record(
      surface: surface,
      invariantKey: invariantKey,
      message: 'Index out of range',
      payload: <String, dynamic>{
        'index': index,
        'length': length,
        ...payload,
      },
    );
  }

  void assertNotEmptyAfterRefresh({
    required String surface,
    required String invariantKey,
    required bool hadSnapshot,
    required int previousCount,
    required int nextCount,
    Map<String, dynamic> payload = const <String, dynamic>{},
  }) {
    if (!hadSnapshot || previousCount <= 0 || nextCount > 0) return;
    record(
      surface: surface,
      invariantKey: invariantKey,
      message: 'List became empty despite previous snapshot',
      payload: <String, dynamic>{
        'previousCount': previousCount,
        'nextCount': nextCount,
        ...payload,
      },
    );
  }

  void assertCenteredSelection({
    required String surface,
    required String invariantKey,
    required int centeredIndex,
    required List<String> docIds,
    String? expectedDocId,
    Map<String, dynamic> payload = const <String, dynamic>{},
  }) {
    if (docIds.isEmpty) return;
    assertIndexInRange(
      surface: surface,
      invariantKey: invariantKey,
      index: centeredIndex,
      length: docIds.length,
      payload: payload,
    );
    if (centeredIndex < 0 || centeredIndex >= docIds.length) return;
    final expected = expectedDocId?.trim() ?? '';
    if (expected.isEmpty || !docIds.contains(expected)) return;
    if (docIds[centeredIndex] == expected) return;
    record(
      surface: surface,
      invariantKey: invariantKey,
      message: 'Centered doc changed although previous doc still exists',
      payload: <String, dynamic>{
        'centeredIndex': centeredIndex,
        'centeredDocId': docIds[centeredIndex],
        'expectedDocId': expected,
        ...payload,
      },
    );
  }

  void assertMutationMatched({
    required String surface,
    required String invariantKey,
    required int requestedCount,
    required int matchedCount,
    required String mutationName,
    Map<String, dynamic> payload = const <String, dynamic>{},
  }) {
    if (requestedCount <= 0 || matchedCount > 0) return;
    record(
      surface: surface,
      invariantKey: invariantKey,
      message: 'Optimistic mutation matched no items',
      payload: <String, dynamic>{
        'mutation': mutationName,
        'requestedCount': requestedCount,
        'matchedCount': matchedCount,
        ...payload,
      },
    );
  }

  void assertCountWithinLimit({
    required String surface,
    required String invariantKey,
    required int observedCount,
    required int maxAllowed,
    required String counterName,
    Map<String, dynamic> payload = const <String, dynamic>{},
  }) {
    if (observedCount <= maxAllowed) return;
    record(
      surface: surface,
      invariantKey: invariantKey,
      message: 'Observed count exceeded configured limit',
      payload: <String, dynamic>{
        'counter': counterName,
        'observedCount': observedCount,
        'maxAllowed': maxAllowed,
        ...payload,
      },
    );
  }
}
