part of 'my_tutoring_applications_controller.dart';

class MyTutoringApplicationsController extends GetxController {
  static MyTutoringApplicationsController ensure({
    String? tag,
    bool permanent = false,
  }) {
    final existing = maybeFind(tag: tag);
    if (existing != null) return existing;
    return Get.put(
      MyTutoringApplicationsController(),
      tag: tag,
      permanent: permanent,
    );
  }

  static MyTutoringApplicationsController? maybeFind({String? tag}) {
    final isRegistered =
        Get.isRegistered<MyTutoringApplicationsController>(tag: tag);
    if (!isRegistered) return null;
    return Get.find<MyTutoringApplicationsController>(tag: tag);
  }

  final UserSubcollectionRepository _subcollectionRepository =
      UserSubcollectionRepository.ensure();
  final TutoringRepository _tutoringRepository = TutoringRepository.ensure();
  static const Duration _silentRefreshInterval = Duration(minutes: 5);
  RxList<TutoringApplicationModel> applications =
      <TutoringApplicationModel>[].obs;
  var isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    _handleInit();
  }

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
