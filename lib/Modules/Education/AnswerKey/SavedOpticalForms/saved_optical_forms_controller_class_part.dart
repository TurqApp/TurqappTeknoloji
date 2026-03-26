part of 'saved_optical_forms_controller.dart';

class SavedOpticalFormsController extends GetxController {
  static SavedOpticalFormsController ensure({
    String? tag,
    bool permanent = false,
  }) =>
      ensureSavedOpticalFormsController(
        tag: tag,
        permanent: permanent,
      );

  static SavedOpticalFormsController? maybeFind({String? tag}) =>
      maybeFindSavedOpticalFormsController(tag: tag);

  final BookletRepository _bookletRepository = ensureBookletRepository();
  static const Duration _silentRefreshInterval = Duration(minutes: 5);
  final list = <BookletModel>[].obs;
  final isLoading = false.obs;
  final UserSubcollectionRepository _userSubcollectionRepository =
      ensureUserSubcollectionRepository();

  @override
  void onInit() {
    super.onInit();
    unawaited(_bootstrapData());
  }
}
