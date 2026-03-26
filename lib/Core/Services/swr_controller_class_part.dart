part of 'swr_controller.dart';

abstract class SWRController<T> extends GetxController {
  final _state = _SWRControllerState<T>();

  Duration get revalidateTTL => const Duration(minutes: 5);

  Future<List<T>> loadFromCache();

  Future<List<T>> fetchFromNetwork({T? cursor});

  void mergeItems(List<T> fresh) {
    items.addAll(fresh);
  }

  T? get paginationCursor => items.isEmpty ? null : items.last;

  @override
  void onInit() {
    super.onInit();
    _SWRControllerRuntimePart<T>(this).handleOnInit();
  }

  @override
  Future<void> refresh() => _SWRControllerRuntimePart<T>(this).refresh();
}
