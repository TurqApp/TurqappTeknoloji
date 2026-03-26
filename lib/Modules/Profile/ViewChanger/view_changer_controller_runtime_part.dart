part of 'view_changer_controller.dart';

extension ViewChangerControllerRuntimeX on ViewChangerController {
  Future<void> updateViewMode(int value) async {
    selection.value = value;
    await CurrentUserService.instance.updateFields({
      "viewSelection": value,
    });
  }
}
