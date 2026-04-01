part of 'my_tutoring_applications_controller.dart';

MyTutoringApplicationsController ensureMyTutoringApplicationsController({
  String? tag,
  bool permanent = false,
}) =>
    maybeFindMyTutoringApplicationsController(tag: tag) ??
    Get.put(
      MyTutoringApplicationsController(),
      tag: tag,
      permanent: permanent,
    );

MyTutoringApplicationsController? maybeFindMyTutoringApplicationsController({
  String? tag,
}) =>
    Get.isRegistered<MyTutoringApplicationsController>(tag: tag)
        ? Get.find<MyTutoringApplicationsController>(tag: tag)
        : null;

extension MyTutoringApplicationsControllerFacadePart
    on MyTutoringApplicationsController {
  Future<void> loadApplications({
    bool silent = false,
    bool forceRefresh = false,
  }) =>
      _loadApplicationsImpl(
        silent: silent,
        forceRefresh: forceRefresh,
      );

  Future<void> cancelApplication(String tutoringDocID) =>
      _cancelApplicationImpl(tutoringDocID);
}
