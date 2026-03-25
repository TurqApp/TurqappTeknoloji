part of 'rozet_content.dart';

class RozetController extends GetxController {
  static RozetController ensure(
    String userID, {
    String? tag,
    bool permanent = false,
  }) {
    final existing = maybeFind(tag: tag);
    if (existing != null) return existing;
    return Get.put(
      RozetController(userID),
      tag: tag,
      permanent: permanent,
    );
  }

  static RozetController? maybeFind({String? tag}) {
    final isRegistered = Get.isRegistered<RozetController>(tag: tag);
    if (!isRegistered) return null;
    return Get.find<RozetController>(tag: tag);
  }

  final String userID;
  RozetController(this.userID);

  final UserSummaryResolver _userSummaryResolver = UserSummaryResolver.ensure();

  Rx<Color> color = Colors.transparent.obs;
  static final Map<String, Color> _badgeCache = <String, Color>{};
  static final Map<String, int> _badgeCacheMs = <String, int>{};
  static const int _cacheTtlMs = 10 * 60 * 1000;
  static const int _staleRetentionMs = 30 * 60 * 1000;

  @override
  void onInit() {
    super.onInit();
    _RozetControllerRuntimeX(this).loadRozet();
  }
}
