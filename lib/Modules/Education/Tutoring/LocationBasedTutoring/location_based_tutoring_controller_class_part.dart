part of 'location_based_tutoring_controller.dart';

class LocationBasedTutoringController extends GetxController {
  static const String _cacheKey = 'location_tutoring_cache_v1';
  final TutoringSnapshotRepository _tutoringSnapshotRepository =
      ensureTutoringSnapshotRepository();
  final _state = _LocationBasedTutoringControllerState();

  @override
  void onInit() {
    super.onInit();
    unawaited(_bootstrapData());
  }

  Future<void> _bootstrapData() =>
      _LocationBasedTutoringControllerRuntimeX(this).bootstrapData();
}
