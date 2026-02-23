import '../Common/post_content_controller.dart';

class AgendaContentController extends PostContentController {
  AgendaContentController({required super.model});

  @override
  Future<void> onReshareAdded(String? uid) async {
    if (uid == null) return;
    try {
      await agendaController.addNewReshareEntryWithoutScroll(model.docID, uid);
    } catch (_) {}
  }

  @override
  Future<void> onReshareRemoved(String? uid) async {
    if (uid == null) return;
    try {
      agendaController.removeReshareEntry(model.docID, uid);
    } catch (_) {}
  }
}
