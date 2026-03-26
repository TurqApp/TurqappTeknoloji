part of 'report_repository.dart';

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
