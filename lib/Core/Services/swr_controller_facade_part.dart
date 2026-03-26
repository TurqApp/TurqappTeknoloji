part of 'swr_controller.dart';

extension SWRControllerFacadePart<T> on SWRController<T> {
  Duration get revalidateTTL => const Duration(minutes: 5);

  void mergeItems(List<T> fresh) {
    items.addAll(fresh);
  }

  T? get paginationCursor => items.isEmpty ? null : items.last;

  Future<void> revalidate({bool force = false}) =>
      _SWRControllerRuntimePart<T>(this).revalidate(force: force);

  Future<void> loadMore() => _SWRControllerRuntimePart<T>(this).loadMore();
}
