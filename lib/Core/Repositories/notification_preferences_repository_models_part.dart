part of 'notification_preferences_repository.dart';

class _CachedNotificationPreferences {
  final Map<String, dynamic> data;
  final DateTime cachedAt;

  const _CachedNotificationPreferences({
    required this.data,
    required this.cachedAt,
  });
}

extension NotificationPreferencesRepositoryRuntimePart
    on NotificationPreferencesRepository {
  void _handleNotificationPreferencesInit() {
    ensureLocalPreferenceRepository().sharedPreferences().then((prefs) {
      _prefs = prefs;
    });
  }
}
