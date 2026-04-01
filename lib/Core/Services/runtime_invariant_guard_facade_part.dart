part of 'runtime_invariant_guard.dart';

RuntimeInvariantGuard? maybeFindRuntimeInvariantGuard() {
  final isRegistered = Get.isRegistered<RuntimeInvariantGuard>();
  if (!isRegistered) return null;
  return Get.find<RuntimeInvariantGuard>();
}

RuntimeInvariantGuard ensureRuntimeInvariantGuard() {
  final existing = maybeFindRuntimeInvariantGuard();
  if (existing != null) return existing;
  return Get.put(RuntimeInvariantGuard(), permanent: true);
}

extension RuntimeInvariantGuardFacadePart on RuntimeInvariantGuard {
  List<RuntimeInvariantViolation> get recentViolations =>
      List.unmodifiable(_recent);

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
      payload: _cloneRuntimeInvariantPayload(payload),
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
