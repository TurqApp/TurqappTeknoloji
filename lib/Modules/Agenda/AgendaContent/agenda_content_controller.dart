import 'package:get/get.dart';

import '../Common/post_content_controller.dart';

class AgendaContentController extends PostContentController {
  static AgendaContentController? maybeFind({String? tag}) {
    if (!Get.isRegistered<AgendaContentController>(tag: tag)) return null;
    return Get.find<AgendaContentController>(tag: tag);
  }

  AgendaContentController({required super.model});

  @override
  Future<void> onReshareAdded(String? uid, {String? targetPostId}) async {
    if (uid == null) return;
    try {
      await agendaController.addNewReshareEntryWithoutScroll(
        (targetPostId ?? model.docID).trim(),
        uid,
      );
    } catch (_) {}
  }

  @override
  Future<void> onReshareRemoved(String? uid, {String? targetPostId}) async {
    if (uid == null) return;
    try {
      agendaController.removeReshareEntry(
        (targetPostId ?? model.docID).trim(),
        uid,
      );
    } catch (_) {}
  }
}
