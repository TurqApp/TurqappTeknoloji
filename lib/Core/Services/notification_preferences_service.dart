import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:turqappv2/Core/Repositories/notification_preferences_repository.dart';

class NotificationPreferencesService {
  NotificationPreferencesService._();

  static Map<String, dynamic> defaults() {
    return {
      'pauseAll': false,
      'sleepMode': false,
      'messagesOnly': false,
      'messages': {
        'directMessages': true,
      },
      'posts': {
        'comments': true,
        'postActivity': true,
      },
      'followers': {
        'follows': true,
      },
      'opportunities': {
        'jobApplications': true,
        'tutoringApplications': true,
        'applicationStatus': true,
      },
    };
  }

  static NotificationPreferencesRepository get _repository =>
      NotificationPreferencesRepository.ensure();

  static Stream<Map<String, dynamic>> currentUserPreferencesStream() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return Stream.value(defaults());
    }
    return _repository.watchPreferences(uid).map(mergeWithDefaults);
  }

  static Future<Map<String, dynamic>> getCurrentUserPreferences() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return defaults();
    final data = await _repository.getPreferences(uid, preferCache: true);
    return mergeWithDefaults(data);
  }

  static Future<void> setValue(String path, dynamic value) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final current = mergeWithDefaults(
      await _repository.getPreferences(uid, preferCache: true),
    );
    final next = mergeWithDefaults(current);
    _writePath(next, path, value);
    await _repository.putPreferences(uid, next);
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('settings')
        .doc('notifications')
        .set(_pathMap(path, value), SetOptions(merge: true));
  }

  static Map<String, dynamic> mergeWithDefaults(Map<String, dynamic>? raw) {
    final merged = _deepMerge(defaults(), raw ?? <String, dynamic>{});
    return Map<String, dynamic>.from(merged);
  }

  static bool isTypeEnabled(String type, Map<String, dynamic>? rawPrefs) {
    final prefs = mergeWithDefaults(rawPrefs);
    final normalized = type.trim().toLowerCase();

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
      case 'reshared_posts':
      case 'shared_as_posts':
      case 'posts':
      case 'comment_like':
        return _readBool(prefs, 'posts.postActivity');
      case 'follow':
      case 'user':
        return _readBool(prefs, 'followers.follows');
      case 'job_application':
        return _readBool(prefs, 'opportunities.jobApplications');
      case 'tutoring_application':
        return _readBool(prefs, 'opportunities.tutoringApplications');
      case 'tutoring_status':
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
    return current == true;
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
          Map<String, dynamic>.from(overrideValue),
        );
      } else if (overrideValue != null) {
        result[key] = overrideValue;
      } else {
        result[key] = baseValue;
      }
    }
    return result;
  }

  static Map<String, dynamic> _pathMap(String path, dynamic value) {
    final segments = path.split('.');
    Map<String, dynamic> result = <String, dynamic>{segments.last: value};
    for (var i = segments.length - 2; i >= 0; i--) {
      result = <String, dynamic>{segments[i]: result};
    }
    return result;
  }

  static void _writePath(Map<String, dynamic> source, String path, dynamic value) {
    final segments = path.split('.');
    Map<String, dynamic> current = source;
    for (var i = 0; i < segments.length - 1; i++) {
      final key = segments[i];
      final next = current[key];
      if (next is Map<String, dynamic>) {
        current = next;
      } else if (next is Map) {
        final mapped = Map<String, dynamic>.from(next);
        current[key] = mapped;
        current = mapped;
      } else {
        final created = <String, dynamic>{};
        current[key] = created;
        current = created;
      }
    }
    current[segments.last] = value;
  }
}
