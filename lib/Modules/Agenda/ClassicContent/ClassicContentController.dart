import '../Common/PostContentController.dart';

class ClassicContentController extends PostContentController {
  ClassicContentController({required super.model})
      : super(
          enableLegacyCommentSync: true,
          scrollFeedToTopOnReshare: true,
        );

  @override
  Future<void> onReshareAdded(String? uid) async {
    await super.onReshareAdded(uid);
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
