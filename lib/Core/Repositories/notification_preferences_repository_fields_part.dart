part of 'notification_preferences_repository.dart';

class NotificationPreferencesRepository extends GetxService {
  static const Duration _ttl = Duration(hours: 12);
  static const String _prefsPrefix = 'notification_preferences_repository_v1';
  final _state = _NotificationPreferencesRepositoryState();

  @override
  void onInit() {
    super.onInit();
    _handleNotificationPreferencesInit();
  }
}

class _NotificationPreferencesRepositoryState {
  SharedPreferences? prefs;
  final memory = <String, _CachedNotificationPreferences>{};
}

extension NotificationPreferencesRepositoryX
    on NotificationPreferencesRepository {
  SharedPreferences? get _prefs => _state.prefs;
  set _prefs(SharedPreferences? value) => _state.prefs = value;
  Map<String, _CachedNotificationPreferences> get _memory => _state.memory;
}
