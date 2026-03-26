part of 'report_user_controller.dart';

ReportUserController ensureReportUserController({
  required String userID,
  required String postID,
  required String commentID,
  String? tag,
  bool permanent = false,
}) {
  final existing = maybeFindReportUserController(tag: tag);
  if (existing != null) return existing;
  return Get.put(
    ReportUserController(
      userID: userID,
      postID: postID,
      commentID: commentID,
    ),
    tag: tag,
    permanent: permanent,
  );
}

ReportUserController? maybeFindReportUserController({String? tag}) {
  final isRegistered = Get.isRegistered<ReportUserController>(tag: tag);
  if (!isRegistered) return null;
  return Get.find<ReportUserController>(tag: tag);
}

extension ReportUserControllerFacadePart on ReportUserController {
  Future<void> report() => _ReportUserControllerRuntimePart(this).report();

  Future<void> block() => _ReportUserControllerRuntimePart(this).block();
}
