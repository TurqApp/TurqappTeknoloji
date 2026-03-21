import 'package:get/get.dart';
import 'package:turqappv2/Services/current_user_service.dart';

class ViewChangerController extends GetxController {
  static ViewChangerController ensure({
    required RxInt selection,
    String? tag,
    bool permanent = false,
  }) {
    final existing = maybeFind(tag: tag);
    if (existing != null) return existing;
    return Get.put(
      ViewChangerController(selection: selection),
      tag: tag,
      permanent: permanent,
    );
  }

  static ViewChangerController? maybeFind({String? tag}) {
    final isRegistered = Get.isRegistered<ViewChangerController>(tag: tag);
    if (!isRegistered) return null;
    return Get.find<ViewChangerController>(tag: tag);
  }

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
