part of 'admin_push_repository.dart';

extension AdminPushRepositoryFacadePart on AdminPushRepository {
  CollectionReference<Map<String, dynamic>> get _reportsRef =>
      _adminPushReportsRef();

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
    String? imageUrl,
  }) =>
      _sendPushImpl(
        title: title,
        body: body,
        type: type,
        targetUids: targetUids,
        imageUrl: imageUrl,
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
