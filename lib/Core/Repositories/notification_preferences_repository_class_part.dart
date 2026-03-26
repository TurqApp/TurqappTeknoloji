part of 'notification_preferences_repository.dart';

class NotificationPreferencesRepository extends GetxService {
  static const Duration _ttl = Duration(hours: 12);
  static const String _prefsPrefix = 'notification_preferences_repository_v1';
  final _NotificationPreferencesRepositoryState _state =
      _NotificationPreferencesRepositoryState();

  @override
  void onInit() {
    super.onInit();
    _handleNotificationPreferencesInit();
  }
}
