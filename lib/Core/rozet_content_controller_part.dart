part of 'rozet_content.dart';

class RozetController extends _RozetControllerBase {
  RozetController(super.userID);

  static final Map<String, Color> _badgeCache = <String, Color>{};
  static final Map<String, int> _badgeCacheMs = <String, int>{};
  static const int _cacheTtlMs = 10 * 60 * 1000;
  static const int _staleRetentionMs = 30 * 60 * 1000;
}
