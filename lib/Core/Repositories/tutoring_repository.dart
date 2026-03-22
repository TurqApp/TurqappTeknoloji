import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:turqappv2/Core/Repositories/notifications_repository.dart';
import 'package:turqappv2/Core/Utils/location_text_utils.dart';
import 'package:turqappv2/Models/Education/tutoring_application_model.dart';
import 'package:turqappv2/Models/Education/tutoring_model.dart';
import 'package:turqappv2/Models/Education/tutoring_review_model.dart';

part 'tutoring_repository_query_part.dart';
part 'tutoring_repository_action_part.dart';

class TutoringRepository extends GetxService {
  TutoringRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  static const Duration _ttl = Duration(hours: 12);
  static const String _prefsPrefix = 'tutoring_repository_v1';
  final Map<String, _TimedValue<dynamic>> _memory =
      <String, _TimedValue<dynamic>>{};
  SharedPreferences? _prefs;
  static const int _thirtyDaysInMillis = 30 * 24 * 60 * 60 * 1000;

  static TutoringRepository? maybeFind() {
    final isRegistered = Get.isRegistered<TutoringRepository>();
    if (!isRegistered) return null;
    return Get.find<TutoringRepository>();
  }

  static TutoringRepository ensure() {
    final existing = maybeFind();
    if (existing != null) return existing;
    return Get.put(TutoringRepository(), permanent: true);
  }

  @override
  void onInit() {
    super.onInit();
    SharedPreferences.getInstance().then((prefs) => _prefs = prefs);
  }

  Future<Map<String, dynamic>?> _getCachedMap(String key) async {
    final value = await _getCachedValue(key);
    if (value is Map<String, dynamic>) return value;
    return null;
  }

  Future<List<Map<String, dynamic>>?> _getCachedList(String key) async {
    final value = await _getCachedValue(key);
    if (value is List) {
      return value.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    }
    return null;
  }

  Future<dynamic> _getCachedValue(String key) async {
    final memory = _memory[key];
    if (memory != null && DateTime.now().difference(memory.cachedAt) <= _ttl) {
      return memory.value;
    }
    _prefs ??= await SharedPreferences.getInstance();
    final raw = _prefs?.getString('$_prefsPrefix:$key');
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final ts = (decoded['t'] as num?)?.toInt() ?? 0;
      if (ts <= 0) return null;
      if (DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(ts)) >
          _ttl) {
        return null;
      }
      final value = decoded['v'];
      _memory[key] =
          _TimedValue<dynamic>(value: value, cachedAt: DateTime.now());
      return value;
    } catch (_) {
      return null;
    }
  }

  Future<void> _storeMap(String key, Map<String, dynamic> value) =>
      _storeValue(key, value);

  Future<void> _storeValue(String key, dynamic value) async {
    final now = DateTime.now();
    _memory[key] = _TimedValue<dynamic>(value: value, cachedAt: now);
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs?.setString(
      '$_prefsPrefix:$key',
      jsonEncode({
        't': now.millisecondsSinceEpoch,
        'v': value,
      }),
    );
  }
}

class TutoringPage {
  const TutoringPage({
    required this.items,
    required this.lastDocument,
    required this.hasMore,
  });

  final List<TutoringModel> items;
  final DocumentSnapshot? lastDocument;
  final bool hasMore;
}

class _TimedValue<T> {
  const _TimedValue({
    required this.value,
    required this.cachedAt,
  });

  final T value;
  final DateTime cachedAt;
}
