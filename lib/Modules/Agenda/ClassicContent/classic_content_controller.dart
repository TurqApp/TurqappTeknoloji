import 'package:flutter/animation.dart';

import '../agenda_controller.dart';
import '../Common/post_content_controller.dart';

class ClassicContentController extends PostContentController {
  ClassicContentController({required super.model})
      : super(
          enableLegacyCommentSync: true,
          scrollFeedToTopOnReshare: true,
        );

  Future<void> onReshareAdded(String? uid, {String? targetPostId}) async {
    if (scrollFeedToTopOnReshare) {
      try {
        final controller = agendaController.scrollController;
        if (controller.hasClients) {
          await controller.animateTo(
            0,
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeInOut,
          );
        }
      } catch (_) {}
    }
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
