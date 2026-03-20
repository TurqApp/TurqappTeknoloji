import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

class RuntimeInvariantViolation {
  const RuntimeInvariantViolation({
    required this.surface,
    required this.invariantKey,
    required this.message,
    required this.payload,
    required this.recordedAt,
  });

  final String surface;
  final String invariantKey;
  final String message;
  final Map<String, dynamic> payload;
  final DateTime recordedAt;
}

class RuntimeInvariantGuard extends GetxService {
  static RuntimeInvariantGuard ensure() {
    if (Get.isRegistered<RuntimeInvariantGuard>()) {
      return Get.find<RuntimeInvariantGuard>();
    }
    return Get.put(RuntimeInvariantGuard(), permanent: true);
  }

  final RxList<RuntimeInvariantViolation> _recent =
      <RuntimeInvariantViolation>[].obs;

  List<RuntimeInvariantViolation> get recentViolations =>
      List.unmodifiable(_recent);

  bool get _enabled => kDebugMode || kProfileMode;

  void record({
    required String surface,
    required String invariantKey,
    required String message,
    Map<String, dynamic> payload = const <String, dynamic>{},
  }) {
    if (!_enabled) return;
    final violation = RuntimeInvariantViolation(
      surface: surface,
      invariantKey: invariantKey,
      message: message,
      payload: Map<String, dynamic>.from(payload),
      recordedAt: DateTime.now(),
    );
    _recent.add(violation);
    if (_recent.length > 100) {
      _recent.removeRange(0, _recent.length - 100);
    }
    debugPrint(
      '[InvariantGuard][$surface][$invariantKey] $message payload=${violation.payload}',
    );
  }

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
    if (!hadSnapshot) return;
    if (previousCount <= 0) return;
    if (nextCount > 0) return;
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
    if (expected.isEmpty) return;
    if (!docIds.contains(expected)) return;
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
}
