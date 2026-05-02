part of 'scholarships_controller.dart';

const int _scholarshipShortLinkPrefetchLimit = 6;
const String _scholarshipDefaultOgImage =
    'https://cdn.turqapp.com/og/default.jpg';

extension ScholarshipsControllerSupportPart on ScholarshipsController {
  int get minSearchLength => 2;

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
    final shouldRefresh =
        allowBackgroundRefresh ?? allScholarships.isEmpty;
    final future = Future<void>(() async {
      if (!shouldRefresh) return;
      await fetchScholarships(silent: true, forceRefresh: false);
    });
    _startupPrepareFuture = future.whenComplete(() {
      if (identical(_startupPrepareFuture, future)) {
        _startupPrepareFuture = null;
      }
    });
    return _startupPrepareFuture!;
  }
}
