part of 'runtime_invariant_guard.dart';

class _RuntimeInvariantGuardState {
  final RxList<RuntimeInvariantViolation> recent =
      <RuntimeInvariantViolation>[].obs;
}

extension RuntimeInvariantGuardFieldsPart on RuntimeInvariantGuard {
  RxList<RuntimeInvariantViolation> get _recent => _state.recent;
  bool get _enabled => kDebugMode || kProfileMode;
}
