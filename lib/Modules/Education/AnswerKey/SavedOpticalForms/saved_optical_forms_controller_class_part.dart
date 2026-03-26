part of 'saved_optical_forms_controller.dart';

class SavedOpticalFormsController extends GetxController {
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
