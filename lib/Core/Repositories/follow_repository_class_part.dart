part of 'follow_repository.dart';

class FollowRepository extends GetxService {
  static const Duration _ttl = Duration(minutes: 15);
  static const String _prefsKeyPrefix = 'follow_repository_v1';
  static const String _relationPrefsKeyPrefix = 'follow_relation_repository_v1';

  SharedPreferences? _prefs;
  final Map<String, _CachedFollowingSet> _memory = {};
  final Map<String, _CachedFollowingSet> _relationMemory = {};

  @override
  void onInit() {
    super.onInit();
    _handleFollowRepositoryInit();
  }
}
