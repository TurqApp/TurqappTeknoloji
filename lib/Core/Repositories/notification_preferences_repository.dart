import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'notification_preferences_repository_models_part.dart';
part 'notification_preferences_repository_cache_part.dart';

class NotificationPreferencesRepository extends GetxService {
  static const Duration _ttl = Duration(hours: 12);
  static const String _prefsPrefix = 'notification_preferences_repository_v1';

  SharedPreferences? _prefs;
  final Map<String, _CachedNotificationPreferences> _memory = {};

  static NotificationPreferencesRepository? maybeFind() {
    final isRegistered = Get.isRegistered<NotificationPreferencesRepository>();
    if (!isRegistered) return null;
    return Get.find<NotificationPreferencesRepository>();
  }

  static NotificationPreferencesRepository ensure() {
    final existing = maybeFind();
    if (existing != null) return existing;
    return Get.put(NotificationPreferencesRepository(), permanent: true);
  }

  @override
  void onInit() {
    super.onInit();
    _handleNotificationPreferencesInit();
  }

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
