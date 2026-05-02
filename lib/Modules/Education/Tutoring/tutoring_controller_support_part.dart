part of 'tutoring_controller.dart';

String _tutoringFirstImage(TutoringModel item) {
  final imgs = item.imgs;
  if (imgs == null || imgs.isEmpty) return '';
  return imgs.first;
}

bool _sameTutoringEntries(
  List<TutoringModel> current,
  List<TutoringModel> next,
) {
  final currentKeys = current
      .map(
        (item) => [
          item.docID,
          item.baslik,
          item.brans,
          item.sehir,
          item.ilce,
          item.fiyat,
          item.timeStamp,
          item.viewCount ?? 0,
          item.applicationCount ?? 0,
          item.dersYeri.join('|'),
          _tutoringFirstImage(item),
        ].join('::'),
      )
      .toList(growable: false);
  final nextKeys = next
      .map(
        (item) => [
          item.docID,
          item.baslik,
          item.brans,
          item.sehir,
          item.ilce,
          item.fiyat,
          item.timeStamp,
          item.viewCount ?? 0,
          item.applicationCount ?? 0,
          item.dersYeri.join('|'),
          _tutoringFirstImage(item),
        ].join('::'),
      )
      .toList(growable: false);
  return listEquals(currentKeys, nextKeys);
}

bool _sameTutoringList(
  TutoringController controller,
  List<TutoringModel> next,
) {
  return _sameTutoringEntries(controller.tutoringList, next);
}

extension TutoringControllerSupportPart on TutoringController {
  void primePrimarySurfaceOnce() {
    if (_primarySurfacePrimedOnce) return;
    _primarySurfacePrimedOnce = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (isClosed) return;
      unawaited(onPrimarySurfaceVisible());
    });
  }

  Future<void> onPrimarySurfaceVisible() => prepareStartupSurface();

  Future<void> prepareStartupSurface({bool? allowBackgroundRefresh}) {
    final existing = _startupPrepareFuture;
    if (existing != null) return existing;
    final shouldRefresh = allowBackgroundRefresh ?? tutoringList.isEmpty;
    final future = Future<void>(() async {
      if (!shouldRefresh) return;
      await listenToTutoringData(forceRefresh: false);
    });
    _startupPrepareFuture = future.whenComplete(() {
      if (identical(_startupPrepareFuture, future)) {
        _startupPrepareFuture = null;
      }
    });
    return _startupPrepareFuture!;
  }
}
