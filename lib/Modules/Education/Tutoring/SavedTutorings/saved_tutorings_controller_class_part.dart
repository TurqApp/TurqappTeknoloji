part of 'saved_tutorings_controller.dart';

class SavedTutoringsController extends GetxController {
  final UserSubcollectionRepository _subcollectionRepository =
      ensureUserSubcollectionRepository();
  var savedTutoringIds = <String>[].obs;

  @override
  void onInit() {
    super.onInit();
    _handleSavedTutoringsInit(this);
  }
}
