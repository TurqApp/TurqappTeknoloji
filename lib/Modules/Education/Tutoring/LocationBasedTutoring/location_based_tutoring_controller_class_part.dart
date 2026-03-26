part of 'location_based_tutoring_controller.dart';

class LocationBasedTutoringController extends GetxController {
  static LocationBasedTutoringController ensure({
    String? tag,
    bool permanent = false,
  }) {
    final existing = maybeFind(tag: tag);
    if (existing != null) return existing;
    return Get.put(
      LocationBasedTutoringController(),
      tag: tag,
      permanent: permanent,
    );
  }

  static LocationBasedTutoringController? maybeFind({String? tag}) {
    final isRegistered =
        Get.isRegistered<LocationBasedTutoringController>(tag: tag);
    if (!isRegistered) return null;
    return Get.find<LocationBasedTutoringController>(tag: tag);
  }

  static const String _cacheKey = 'location_tutoring_cache_v1';
  final TutoringSnapshotRepository _tutoringSnapshotRepository =
      TutoringSnapshotRepository.ensure();
  final _state = _LocationBasedTutoringControllerState();

  @override
  void onInit() {
    super.onInit();
    unawaited(_bootstrapData());
  }

  Future<void> _bootstrapData() =>
      _LocationBasedTutoringControllerRuntimeX(this).bootstrapData();

  Future<void> fetchLocationBasedTutoring({
    bool silent = false,
  }) =>
      _LocationBasedTutoringControllerRuntimeX(this)
          .fetchLocationBasedTutoring(silent: silent);
}
