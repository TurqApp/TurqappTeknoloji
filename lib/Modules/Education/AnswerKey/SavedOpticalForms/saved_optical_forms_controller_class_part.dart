part of 'saved_optical_forms_controller.dart';

class SavedOpticalFormsController extends GetxController {
  static SavedOpticalFormsController ensure({
    String? tag,
    bool permanent = false,
  }) {
    final existing = maybeFind(tag: tag);
    if (existing != null) return existing;
    return Get.put(
      SavedOpticalFormsController(),
      tag: tag,
      permanent: permanent,
    );
  }

  static SavedOpticalFormsController? maybeFind({String? tag}) {
    final isRegistered =
        Get.isRegistered<SavedOpticalFormsController>(tag: tag);
    if (!isRegistered) return null;
    return Get.find<SavedOpticalFormsController>(tag: tag);
  }

  final BookletRepository _bookletRepository = BookletRepository.ensure();
  static const Duration _silentRefreshInterval = Duration(minutes: 5);
  final list = <BookletModel>[].obs;
  final isLoading = false.obs;
  final UserSubcollectionRepository _userSubcollectionRepository =
      UserSubcollectionRepository.ensure();

  @override
  void onInit() {
    super.onInit();
    unawaited(_bootstrapData());
  }
}
