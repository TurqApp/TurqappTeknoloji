import 'package:get/get.dart';

import '../agenda_controller.dart';
import '../Common/post_content_controller.dart';

class AgendaContentController extends PostContentController {
  static AgendaContentController? maybeFind({String? tag}) {
    final isRegistered = Get.isRegistered<AgendaContentController>(tag: tag);
    if (!isRegistered) return null;
    return Get.find<AgendaContentController>(tag: tag);
  }

  AgendaContentController({required super.model});

  Future<void> onReshareAdded(String? uid, {String? targetPostId}) async {
    if (uid == null) return;
    try {
      await AgendaControllerResharePart(agendaController)
          .addNewReshareEntryWithoutScroll(
        (targetPostId ?? model.docID).trim(),
        uid,
      );
    } catch (_) {}
  }

  @override
  Future<void> onReshareRemoved(String? uid, {String? targetPostId}) async {
    if (uid == null) return;
    try {
      AgendaControllerResharePart(agendaController).removeReshareEntry(
        (targetPostId ?? model.docID).trim(),
        uid,
      );
    } catch (_) {}
  }
}
