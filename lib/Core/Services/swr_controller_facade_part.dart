part of 'swr_controller.dart';

extension SWRControllerFacadePart<T> on SWRController<T> {
  Future<void> revalidate({bool force = false}) =>
      _SWRControllerRuntimePart<T>(this).revalidate(force: force);

  Future<void> loadMore() => _SWRControllerRuntimePart<T>(this).loadMore();
}
