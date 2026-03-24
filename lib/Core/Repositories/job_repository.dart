import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:turqappv2/Core/Repositories/notifications_repository.dart';
import 'package:turqappv2/Core/job_collection_helper.dart';
import 'package:turqappv2/Core/Services/read_budget_registry.dart';
import 'package:turqappv2/Core/Utils/text_normalization_utils.dart';
import 'package:turqappv2/Models/job_review_model.dart';
import 'package:turqappv2/Models/job_model.dart';
import 'package:turqappv2/Models/job_application_model.dart';

part 'job_repository_query_part.dart';
part 'job_repository_action_part.dart';

class JobRepository extends GetxService {
  JobRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  static const Duration _ttl = Duration(hours: 6);
  static const String _prefsPrefix = 'job_repository_v1';
  final Map<String, _TimedJobs> _memory = <String, _TimedJobs>{};
  final Map<String, _TimedBool> _boolMemory = <String, _TimedBool>{};
  SharedPreferences? _prefs;

  static JobRepository? maybeFind() {
    final isRegistered = Get.isRegistered<JobRepository>();
    if (!isRegistered) return null;
    return Get.find<JobRepository>();
  }

  static JobRepository ensure() {
    final existing = maybeFind();
    if (existing != null) return existing;
    return Get.put(JobRepository(), permanent: true);
  }

  @override
  void onInit() {
    super.onInit();
    SharedPreferences.getInstance().then((prefs) => _prefs = prefs);
  }

  Future<void> clearAll() async {
    _memory.clear();
    _boolMemory.clear();
    final prefs = _prefs ??= await SharedPreferences.getInstance();
    final keys = prefs
        .getKeys()
        .where((key) => key.startsWith(_prefsPrefix))
        .toList(growable: false);
    for (final key in keys) {
      await prefs.remove(key);
    }
  }

  List<JobModel>? _getFromMemory(String key) {
    final entry = _memory[key];
    if (entry == null) return null;
    if (DateTime.now().difference(entry.cachedAt) > _ttl) {
      _memory.remove(key);
      return null;
    }
    return List<JobModel>.from(entry.items);
  }

  Future<_TimedJobs?> _getFromPrefsEntry(String key) async {
    final prefs = _prefs ??= await SharedPreferences.getInstance();
    final raw = prefs.getString('$_prefsPrefix::$key');
    if (raw == null || raw.isEmpty) return null;
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    final cachedAt = DateTime.tryParse(decoded['cachedAt'] as String? ?? '');
    if (cachedAt == null || DateTime.now().difference(cachedAt) > _ttl) {
      await prefs.remove('$_prefsPrefix::$key');
      return null;
    }
    final items =
        (decoded['items'] as List<dynamic>? ?? const <dynamic>[]).map((item) {
      final map = Map<String, dynamic>.from(item as Map);
      return JobModel.fromMap(
        Map<String, dynamic>.from(map['data'] as Map),
        map['docID'] as String? ?? '',
      );
    }).toList(growable: false);
    return _TimedJobs(items: items, cachedAt: cachedAt);
  }

  Future<void> _store(String key, List<JobModel> items) async {
    _memory[key] =
        _TimedJobs(items: List<JobModel>.from(items), cachedAt: DateTime.now());
    final prefs = _prefs ??= await SharedPreferences.getInstance();
    final payload = jsonEncode(<String, dynamic>{
      'cachedAt': DateTime.now().toIso8601String(),
      'items': items
          .map((item) => <String, dynamic>{
                'docID': item.docID,
                'data': item.toMap(),
              })
          .toList(growable: false),
    });
    await prefs.setString('$_prefsPrefix::$key', payload);
  }

  Future<List<Map<String, dynamic>>?> _readList(String key) async {
    final prefs = _prefs ??= await SharedPreferences.getInstance();
    final raw = prefs.getString('$_prefsPrefix::$key');
    if (raw == null || raw.isEmpty) return null;
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    final cachedAt = DateTime.tryParse(decoded['cachedAt'] as String? ?? '');
    if (cachedAt == null || DateTime.now().difference(cachedAt) > _ttl) {
      await prefs.remove('$_prefsPrefix::$key');
      return null;
    }
    return (decoded['items'] as List<dynamic>? ?? const <dynamic>[])
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList(growable: false);
  }

  Future<void> _writeList(String key, List<Map<String, dynamic>> items) async {
    final prefs = _prefs ??= await SharedPreferences.getInstance();
    await prefs.setString(
      '$_prefsPrefix::$key',
      jsonEncode(<String, dynamic>{
        'cachedAt': DateTime.now().toIso8601String(),
        'items': items,
      }),
    );
  }

  Future<void> _invalidateListCache(String key) async {
    final prefs = _prefs ??= await SharedPreferences.getInstance();
    await prefs.remove('$_prefsPrefix::$key');
  }

  String _statusBody(String status, String title, String companyName) {
    final displayTitle = title.isNotEmpty
        ? title
        : companyName.isNotEmpty
            ? companyName
            : 'ilan';
    switch (status) {
      case 'accepted':
        return '$displayTitle başvurun kabul edildi.';
      case 'reviewing':
        return '$displayTitle başvurun incelemeye alındı.';
      case 'rejected':
        return '$displayTitle başvurun reddedildi.';
      default:
        return '$displayTitle başvuru durumun güncellendi.';
    }
  }

  List<List<String>> _chunkIds(List<String> input, int size) {
    if (input.isEmpty) return const <List<String>>[];
    final chunks = <List<String>>[];
    for (var i = 0; i < input.length; i += size) {
      final end = (i + size > input.length) ? input.length : i + size;
      chunks.add(input.sublist(i, end));
    }
    return chunks;
  }
}

class _TimedJobs {
  const _TimedJobs({
    required this.items,
    required this.cachedAt,
  });

  final List<JobModel> items;
  final DateTime cachedAt;
}

class _TimedBool {
  const _TimedBool({
    required this.value,
    required this.cachedAt,
  });

  final bool value;
  final DateTime cachedAt;
}
