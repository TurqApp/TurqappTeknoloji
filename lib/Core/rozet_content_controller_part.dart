part of 'rozet_content.dart';

abstract class _RozetControllerBase extends GetxController {
  _RozetControllerBase(this.userID);

  final String userID;
  final color = Colors.transparent.obs;

  @override
  void onInit() {
    super.onInit();
    _RozetControllerRuntimeX(this as RozetController).loadRozet();
  }
}

class RozetController extends _RozetControllerBase {
  RozetController(super.userID);

  static final Map<String, Color> _badgeCache = <String, Color>{};
  static final Map<String, int> _badgeCacheMs = <String, int>{};
  static const int _cacheTtlMs = 10 * 60 * 1000;
  static const int _staleRetentionMs = 30 * 60 * 1000;
}
