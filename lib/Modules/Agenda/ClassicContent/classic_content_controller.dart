import '../agenda_controller.dart';
import '../Common/post_content_controller.dart';

class ClassicContentController extends PostContentController {
  ClassicContentController({required super.model});

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
