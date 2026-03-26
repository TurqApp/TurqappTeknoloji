part of 'saved_optical_forms_controller.dart';

class SavedOpticalFormsController extends GetxController {
  final BookletRepository _bookletRepository = ensureBookletRepository();
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
