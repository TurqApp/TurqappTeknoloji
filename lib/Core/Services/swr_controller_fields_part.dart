part of 'swr_controller_library.dart';

class _SWRControllerState<T> {
  final RxList<T> items = <T>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isRevalidating = false.obs;
  final RxBool hasMore = true.obs;
  DateTime? lastRevalidated;
}

extension SWRControllerFieldsPart<T> on SWRController<T> {
  RxList<T> get items => _state.items;
  RxBool get isLoading => _state.isLoading;
  RxBool get isRevalidating => _state.isRevalidating;
  RxBool get hasMore => _state.hasMore;
  DateTime? get _lastRevalidated => _state.lastRevalidated;
  set _lastRevalidated(DateTime? value) => _state.lastRevalidated = value;
}
