import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Repositories/notifications_repository.dart';
import 'package:turqappv2/Core/Repositories/user_repository.dart';
import 'package:turqappv2/Core/Utils/text_normalization_utils.dart';
import 'package:turqappv2/Services/current_user_service.dart';

part 'admin_push_repository_query_part.dart';
part 'admin_push_repository_action_part.dart';
part 'admin_push_repository_filter_part.dart';

class AdminPushReport {
  final String id;
  final Map<String, dynamic> data;

  const AdminPushReport({
    required this.id,
    required this.data,
  });
}

class AdminPushTargetFilters {
  final String uid;
  final String meslek;
  final String konum;
  final String gender;
  final int? minAge;
  final int? maxAge;

  const AdminPushTargetFilters({
    this.uid = '',
    this.meslek = '',
    this.konum = '',
    this.gender = '',
    this.minAge,
    this.maxAge,
  });
}

class AdminPushRepository extends GetxService {
  static AdminPushRepository? maybeFind() {
    final isRegistered = Get.isRegistered<AdminPushRepository>();
    if (!isRegistered) return null;
    return Get.find<AdminPushRepository>();
  }

  static AdminPushRepository ensure() {
    final existing = maybeFind();
    if (existing != null) return existing;
    return Get.put(AdminPushRepository(), permanent: true);
  }

  final UserRepository _userRepository = UserRepository.ensure();

  CollectionReference<Map<String, dynamic>> get _reportsRef =>
      FirebaseFirestore.instance
          .collection('adminConfig')
          .doc('admin')
          .collection('pushReports');

  Stream<List<AdminPushReport>> watchReports({int limit = 20}) =>
      _watchReportsImpl(limit: limit);

  Future<void> deleteReport(String reportId) => _deleteReportImpl(reportId);

  Future<void> addReport({
    required String senderUid,
    required String title,
    required String body,
    required String type,
    required int targetCount,
    required AdminPushTargetFilters filters,
  }) =>
      _addReportImpl(
        senderUid: senderUid,
        title: title,
        body: body,
        type: type,
        targetCount: targetCount,
        filters: filters,
      );

  Future<void> addPostReport({
    required String senderUid,
    required String title,
    required String body,
    required int targetCount,
    required String postId,
    String? imageUrl,
  }) =>
      _addPostReportImpl(
        senderUid: senderUid,
        title: title,
        body: body,
        targetCount: targetCount,
        postId: postId,
        imageUrl: imageUrl,
      );

  Future<List<String>> resolveTargetUids({
    required AdminPushTargetFilters filters,
  }) =>
      _resolveTargetUidsImpl(filters: filters);

  Future<void> sendPush({
    required String title,
    required String body,
    required String type,
    required List<String> targetUids,
  }) =>
      _sendPushImpl(
        title: title,
        body: body,
        type: type,
        targetUids: targetUids,
      );

  Future<int> sendPostPush({
    required String postId,
    required String title,
    required String body,
    String? imageUrl,
    AdminPushTargetFilters filters = const AdminPushTargetFilters(),
  }) =>
      _sendPostPushImpl(
        postId: postId,
        title: title,
        body: body,
        imageUrl: imageUrl,
        filters: filters,
      );
}
