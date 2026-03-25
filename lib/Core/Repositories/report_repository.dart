import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/strings.dart';
import 'package:turqappv2/Models/report_model.dart';
import 'package:turqappv2/Services/current_user_service.dart';

part 'report_repository_models_part.dart';
part 'report_repository_data_part.dart';

class ReportRepository extends GetxService {
  static ReportRepository? maybeFind() {
    final isRegistered = Get.isRegistered<ReportRepository>();
    if (!isRegistered) return null;
    return Get.find<ReportRepository>();
  }

  static ReportRepository ensure() {
    final existing = maybeFind();
    if (existing != null) return existing;
    return Get.put(ReportRepository(), permanent: true);
  }

  Future<void> submitReport({
    required String targetUserId,
    required String postId,
    required String commentId,
    required ReportModel selection,
    String targetType = 'post',
  }) async {
    final reporterUserId = CurrentUserService.instance.effectiveUserId;
    if (reporterUserId.isEmpty) {
      throw StateError('auth_required');
    }

    targetType = commentId.trim().isNotEmpty
        ? 'comment'
        : postId.trim().isNotEmpty
            ? targetType
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
}
