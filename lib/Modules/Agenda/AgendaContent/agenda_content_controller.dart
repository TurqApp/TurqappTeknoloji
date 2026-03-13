import '../Common/post_content_controller.dart';

class AgendaContentController extends PostContentController {
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
