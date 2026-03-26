part of 'saved_items_controller.dart';

class SavedItemsController extends _SavedItemsControllerBase {
  @override
  void onInit() {
    super.onInit();
    unawaited(_bootstrapSavedItems());
  }

  @override
  void onClose() {
    pageController.dispose();
    super.onClose();
  }
}
