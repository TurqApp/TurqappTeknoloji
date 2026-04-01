part of 'swr_controller_library.dart';

abstract class SWRController<T> extends GetxController
    with _SWRControllerBasePart<T> {
  Future<List<T>> loadFromCache();

  Future<List<T>> fetchFromNetwork({T? cursor});

  @override
  void onInit() {
    super.onInit();
    _SWRControllerRuntimePart<T>(this).handleOnInit();
  }

  @override
  Future<void> refresh() => _SWRControllerRuntimePart<T>(this).refresh();
}
