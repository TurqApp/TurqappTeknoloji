import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Models/report_model.dart';

class ReportAggregateItem {
  final String id;
  final Map<String, dynamic> data;

  const ReportAggregateItem({
    required this.id,
    required this.data,
  });
}

class ReportReasonItem {
  final String id;
  final Map<String, dynamic> data;

  const ReportReasonItem({
    required this.id,
    required this.data,
  });
}

class ReportRepository extends GetxService {
  static ReportRepository ensure() {
    if (Get.isRegistered<ReportRepository>()) {
      return Get.find<ReportRepository>();
    }
    return Get.put(ReportRepository(), permanent: true);
  }

  Future<void> submitReport({
    required String targetUserId,
    required String postId,
    required String commentId,
    required ReportModel selection,
  }) async {
    final reporterUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (reporterUserId.isEmpty) {
      throw StateError('auth_required');
    }

    final targetType = commentId.trim().isNotEmpty
        ? 'comment'
        : postId.trim().isNotEmpty
            ? 'post'
            : 'user';
    final targetId = commentId.trim().isNotEmpty
        ? commentId.trim()
        : postId.trim().isNotEmpty
            ? postId.trim()
            : targetUserId.trim();
    if (targetId.isEmpty) {
      throw StateError('report_target_required');
    }

    final callable = FirebaseFunctions.instanceFor(region: 'europe-west3')
        .httpsCallable('submitReport');
    await callable.call(<String, dynamic>{
      'reporterUserId': reporterUserId,
      'targetType': targetType,
      'targetId': targetId,
      'targetOwnerId': targetUserId.trim(),
      'postId': postId,
      'commentId': commentId,
      'categoryKey': selection.key,
      'title': selection.title,
      'description': selection.description,
      'source': 'app',
    });
  }

  Stream<List<ReportAggregateItem>> watchAggregates({int limit = 100}) {
    return FirebaseFirestore.instance
        .collection('reportAggregates')
        .orderBy('lastReportAt', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map(
                (doc) => ReportAggregateItem(
                  id: doc.id,
                  data: Map<String, dynamic>.from(doc.data()),
                ),
              )
              .toList(growable: false),
        );
  }

  Stream<List<ReportReasonItem>> watchReasonsForTarget(
    String targetKey, {
    int limit = 20,
  }) {
    return FirebaseFirestore.instance
        .collection('reportAggregates')
        .doc(targetKey)
        .collection('reasons')
        .orderBy('count', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) {
      final items = snap.docs
          .map(
            (doc) => ReportReasonItem(
              id: doc.id,
              data: Map<String, dynamic>.from(doc.data()),
            ),
          )
          .toList(growable: false);
      items.sort(
        (a, b) => _asInt(b.data['count']).compareTo(_asInt(a.data['count'])),
      );
      return items;
    });
  }

  Future<Map<String, dynamic>> ensureConfigWithCallable() async {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final callable = FirebaseFunctions.instanceFor(region: 'europe-west3')
        .httpsCallable('ensureReportsConfig');
    final res = await callable.call(<String, dynamic>{
      if (uid.isNotEmpty) 'uid': uid,
    });
    final data = res.data;
    if (data is Map && data['config'] is Map) {
      return Map<String, dynamic>.from(data['config'] as Map);
    }
    return const <String, dynamic>{};
  }

  Future<void> reviewAggregate({
    required String aggregateId,
    required bool restore,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final callable = FirebaseFunctions.instanceFor(region: 'europe-west3')
        .httpsCallable('reviewReportedTarget');
    await callable.call(<String, dynamic>{
      'aggregateId': aggregateId,
      'action': restore ? 'restore' : 'keep_hidden',
      if (uid.isNotEmpty) 'uid': uid,
    });
  }

  static int _asInt(dynamic raw) {
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    return int.tryParse(raw?.toString() ?? '') ?? 0;
  }
}
