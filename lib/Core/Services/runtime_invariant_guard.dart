import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

part 'runtime_invariant_guard_models_part.dart';
part 'runtime_invariant_guard_assertions_part.dart';

class RuntimeInvariantGuard extends GetxService {
  static RuntimeInvariantGuard? maybeFind() {
    final isRegistered = Get.isRegistered<RuntimeInvariantGuard>();
    if (!isRegistered) return null;
    return Get.find<RuntimeInvariantGuard>();
  }

  static RuntimeInvariantGuard ensure() {
    final existing = maybeFind();
    if (existing != null) return existing;
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
}
