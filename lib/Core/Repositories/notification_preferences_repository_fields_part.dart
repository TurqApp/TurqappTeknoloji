part of 'notification_preferences_repository.dart';

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
