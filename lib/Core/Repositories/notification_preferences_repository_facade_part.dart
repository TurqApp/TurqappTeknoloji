part of 'notification_preferences_repository.dart';

NotificationPreferencesRepository?
    maybeFindNotificationPreferencesRepository() {
  final isRegistered = Get.isRegistered<NotificationPreferencesRepository>();
  if (!isRegistered) return null;
  return Get.find<NotificationPreferencesRepository>();
}

NotificationPreferencesRepository ensureNotificationPreferencesRepository() {
  final existing = maybeFindNotificationPreferencesRepository();
  if (existing != null) return existing;
  return Get.put(NotificationPreferencesRepository(), permanent: true);
}

extension NotificationPreferencesRepositoryFacadePart
    on NotificationPreferencesRepository {
  Future<Map<String, dynamic>?> getPreferences(
    String uid, {
    bool preferCache = true,
    bool forceRefresh = false,
  }) =>
      _getPreferencesImpl(
        uid,
        preferCache: preferCache,
        forceRefresh: forceRefresh,
      );

  Stream<Map<String, dynamic>> watchPreferences(String uid) =>
      _watchPreferencesImpl(uid);

  Future<void> putPreferences(String uid, Map<String, dynamic> data) =>
      _putPreferencesImpl(uid, data);

  Future<void> invalidate(String uid) => _invalidateImpl(uid);
}
