import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:turqappv2/Core/Services/read_budget_registry.dart';
import 'package:turqappv2/Models/Education/question_bank_model.dart';
import 'package:turqappv2/Modules/Education/Antreman3/AntremanComments/antreman_comments_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'antreman_repository_query_part.dart';
part 'antreman_repository_action_part.dart';

class AntremanRepository {
  AntremanRepository._();

  static AntremanRepository? _instance;
  static AntremanRepository? maybeFind() => _instance;

  static AntremanRepository ensure() =>
      maybeFind() ?? (_instance = AntremanRepository._());

  static const String _scoreCollection = 'questionBankSkor';
  static const String _localAnswersPrefsPrefix = 'antreman_answers_v1';
  static const String _localProgressPrefsPrefix = 'antreman_progress_v1';
  static const String _localScorePrefsPrefix = 'antreman_score_v1';
  static const String _localSavedPrefsPrefix = 'antreman_saved_v1';

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Map<String, List<Comment>> _commentsCache = <String, List<Comment>>{};
  final Map<String, List<Reply>> _repliesCache = <String, List<Reply>>{};
  Map<String, List<String>>? _uniqueFieldsCache;
  DateTime? _uniqueFieldsCachedAt;
  static const Duration _uniqueFieldsTtl = Duration(hours: 12);

  String _monthKey([DateTime? now]) {
    final current = now ?? DateTime.now();
    final month = current.month.toString().padLeft(2, '0');
    return '${current.year}-$month';
  }

  String _localAnswersPrefsKey(String userId) =>
      '$_localAnswersPrefsPrefix:$userId';

  String _localProgressPrefsKey(String userId, String categoryKey) =>
      '$_localProgressPrefsPrefix:$userId:$categoryKey';

  String _localScorePrefsKey(String userId, {DateTime? now}) =>
      '$_localScorePrefsPrefix:$userId:${_monthKey(now)}';

  String _localSavedPrefsKey(String userId) => '$_localSavedPrefsPrefix:$userId';

  Future<Map<String, dynamic>> _readPrefsJsonMap(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(key);
    if (raw == null || raw.isEmpty) return <String, dynamic>{};
    final decoded = jsonDecode(raw);
    if (decoded is! Map) return <String, dynamic>{};
    return decoded.map(
      (mapKey, value) => MapEntry(mapKey.toString(), value),
    );
  }

  Future<void> _writePrefsJsonMap(
    String key,
    Map<String, dynamic> value,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, jsonEncode(value));
  }
}
