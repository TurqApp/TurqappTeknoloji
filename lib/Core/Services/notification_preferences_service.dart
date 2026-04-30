import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:turqappv2/Core/Repositories/notification_preferences_repository.dart';
import 'package:turqappv2/Core/Services/app_firestore.dart';
import 'package:turqappv2/Modules/InAppNotifications/notification_post_types.dart';
import 'package:turqappv2/Services/current_user_service.dart';

class NotificationPreferencesService {
  NotificationPreferencesService._();

  static Map<String, dynamic> defaults() {
    return _clonePreferencesMap({
      'pauseAll': false,
      'sleepMode': false,
      'messagesOnly': false,
      'messages': {
        'directMessages': true,
      },
      'posts': {
        'posts': true,
        'comments': true,
        'likes': true,
      },
      'followers': {
        'follows': true,
      },
      'opportunities': {
        'jobApplications': true,
        'tutoringApplications': true,
        'applicationStatus': true,
      },
    });
  }

  static NotificationPreferencesRepository get _repository =>
      ensureNotificationPreferencesRepository();

  static Stream<Map<String, dynamic>> currentUserPreferencesStream() {
    final uid = CurrentUserService.instance.effectiveUserId;
    if (uid.isEmpty) {
      return Stream.value(defaults());
    }
    return _repository.watchPreferences(uid).map(mergeWithDefaults);
  }

  static Future<Map<String, dynamic>> getCurrentUserPreferences() async {
    final uid = CurrentUserService.instance.effectiveUserId;
    if (uid.isEmpty) return defaults();
    final data = await _repository.getPreferences(uid, preferCache: true);
    return mergeWithDefaults(data);
  }

  static Future<void> setValue(String path, dynamic value) async {
    final uid = CurrentUserService.instance.effectiveUserId;
    if (uid.isEmpty) return;
    final current = mergeWithDefaults(
      await _repository.getPreferences(uid, preferCache: true),
    );
    final next = mergeWithDefaults(current);
    _writePath(next, path, value);
    await _repository.putPreferences(uid, next);
    await AppFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('settings')
        .doc('notifications')
        .set(_pathMap(path, value), SetOptions(merge: true));
  }

  static Map<String, dynamic> mergeWithDefaults(Map<String, dynamic>? raw) {
    final merged = _deepMerge(
      defaults(),
      _normalizeLegacyPreferences(raw ?? <String, dynamic>{}),
    );
    return _clonePreferencesMap(merged);
  }

  static bool isTypeEnabled(String type, Map<String, dynamic>? rawPrefs) {
    final prefs = mergeWithDefaults(rawPrefs);
    final normalized = normalizeNotificationType(type, '');

    if (_readBool(prefs, 'pauseAll')) {
      return false;
    }

    if (_readBool(prefs, 'messagesOnly')) {
      return normalized == 'message' || normalized == 'chat';
    }

    switch (normalized) {
      case 'message':
      case 'chat':
        return _readBool(prefs, 'messages.directMessages');
      case 'comment':
        return _readBool(prefs, 'posts.comments');
      case 'like':
      case 'comment_like':
        return _readBool(prefs, 'posts.likes');
      case 'reshared_posts':
      case 'shared_as_posts':
      case 'posts':
        return _readBool(prefs, 'posts.posts');
      case 'follow':
      case 'user':
        return _readBool(prefs, 'followers.follows');
      case 'job_application':
      case 'market_offer':
        return _readBool(prefs, 'opportunities.jobApplications');
      case 'tutoring_application':
        return _readBool(prefs, 'opportunities.tutoringApplications');
      case 'tutoring_status':
      case 'market_offer_status':
        return _readBool(prefs, 'opportunities.applicationStatus');
      default:
        return true;
    }
  }

  static bool _readBool(Map<String, dynamic> source, String path) {
    dynamic current = source;
    for (final segment in path.split('.')) {
      if (current is! Map) return false;
      current = current[segment];
    }
    return _asNullableBool(current) ?? false;
  }

  static Map<String, dynamic> _deepMerge(
      Map<String, dynamic> base, Map<String, dynamic> override) {
    final result = <String, dynamic>{};
    final keys = <String>{...base.keys, ...override.keys};
    for (final key in keys) {
      final baseValue = base[key];
      final overrideValue = override[key];
      if (baseValue is Map<String, dynamic> && overrideValue is Map) {
        result[key] = _deepMerge(
          baseValue,
          _clonePreferencesMap(
            overrideValue.map(
              (nestedKey, nestedValue) =>
                  MapEntry(nestedKey.toString(), nestedValue),
            ),
          ),
        );
      } else if (overrideValue != null) {
        result[key] = _clonePreferencesValue(overrideValue);
      } else {
        result[key] = _clonePreferencesValue(baseValue);
      }
    }
    return result;
  }

  static Map<String, dynamic> _normalizeLegacyPreferences(
    Map<String, dynamic> raw,
  ) {
    final normalized = _clonePreferencesMap(raw);
    final posts = normalized['posts'];
    if (posts is Map) {
      final mappedPosts = _clonePreferencesMap(
        posts.map((key, value) => MapEntry(key.toString(), value)),
      );
      final legacyPostActivity = _asNullableBool(mappedPosts['postActivity']);
      if (legacyPostActivity != null) {
        mappedPosts.putIfAbsent('posts', () => legacyPostActivity);
        mappedPosts.putIfAbsent('likes', () => legacyPostActivity);
      }
      normalized['posts'] = mappedPosts;
    }
    return normalized;
  }

  static bool? _asNullableBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      if (normalized.isEmpty) return null;
      switch (normalized) {
        case 'true':
        case '1':
        case 'yes':
        case 'y':
        case 'on':
          return true;
        case 'false':
        case '0':
        case 'no':
        case 'n':
        case 'off':
          return false;
      }
    }
    return null;
  }

  static Map<String, dynamic> _pathMap(String path, dynamic value) {
    final segments = path.split('.');
    Map<String, dynamic> result = <String, dynamic>{
      segments.last: _clonePreferencesValue(value),
    };
    for (var i = segments.length - 2; i >= 0; i--) {
      result = <String, dynamic>{segments[i]: result};
    }
    return result;
  }

  static void _writePath(
      Map<String, dynamic> source, String path, dynamic value) {
    final segments = path.split('.');
    Map<String, dynamic> current = source;
    for (var i = 0; i < segments.length - 1; i++) {
      final key = segments[i];
      final next = current[key];
      if (next is Map<String, dynamic>) {
        current = next;
      } else if (next is Map) {
        final mapped = _clonePreferencesMap(
          next.map((mapKey, mapValue) => MapEntry(mapKey.toString(), mapValue)),
        );
        current[key] = mapped;
        current = mapped;
      } else {
        final created = <String, dynamic>{};
        current[key] = created;
        current = created;
      }
    }
    current[segments.last] = _clonePreferencesValue(value);
  }

  static Map<String, dynamic> _clonePreferencesMap(
    Map<String, dynamic> source,
  ) {
    return source.map(
      (key, value) => MapEntry(key, _clonePreferencesValue(value)),
    );
  }

  static dynamic _clonePreferencesValue(dynamic value) {
    if (value is Map) {
      return value.map(
        (key, nestedValue) => MapEntry(
          key.toString(),
          _clonePreferencesValue(nestedValue),
        ),
      );
    }
    if (value is List) {
      return value.map(_clonePreferencesValue).toList(growable: false);
    }
    return value;
  }
}
