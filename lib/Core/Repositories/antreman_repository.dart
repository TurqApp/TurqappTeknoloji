import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:turqappv2/Models/Education/question_bank_model.dart';
import 'package:turqappv2/Modules/Education/Antreman3/AntremanComments/antreman_comments_controller.dart';

part 'antreman_repository_query_part.dart';
part 'antreman_repository_action_part.dart';

class AntremanRepository {
  AntremanRepository._();

  static AntremanRepository? _instance;
  static AntremanRepository? maybeFind() => _instance;

  static AntremanRepository ensure() =>
      maybeFind() ?? (_instance = AntremanRepository._());

  static const String _scoreCollection = 'questionBankSkor';

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
}
