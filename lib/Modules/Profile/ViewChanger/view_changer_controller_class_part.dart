part of 'view_changer_controller.dart';

class ViewChangerController extends GetxController {
  var selection = 0.obs;

  ViewChangerController({required RxInt selection}) {
    this.selection.value = selection.value;
  }

  Future<void> updateViewMode(int value) async {
    selection.value = value;
    await CurrentUserService.instance.updateFields({
      "viewSelection": value,
    });
  }
}
