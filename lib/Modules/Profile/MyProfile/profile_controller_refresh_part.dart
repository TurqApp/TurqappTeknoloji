part of 'profile_controller.dart';

extension ProfileControllerRefreshPart on ProfileController {
  Future<void> _performRefreshAll({bool forceSync = false}) async {
    try {
      await _bootstrapHeaderFromTypesense();
      await getCounters();

      await Future.wait([
        _loadInitialPrimaryBuckets(forceSync: forceSync),
        getReshares(),
      ]);
    } catch (e) {
      print('refreshAll error: $e');
    }
  }
}
