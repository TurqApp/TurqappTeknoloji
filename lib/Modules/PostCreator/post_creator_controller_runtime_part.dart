part of 'post_creator_controller.dart';

extension PostCreatorControllerRuntimePart on PostCreatorController {
  String _requireCurrentUid() {
    final uid = _currentUid;
    if (uid.isEmpty) {
      throw StateError('Current user uid unavailable');
    }
    return uid;
  }

  int allocateComposerItemIndex() {
    final next = _nextComposerItemIndex;
    _nextComposerItemIndex++;
    return next;
  }

  PostCreatorModel insertComposerItemAfter(int listIndex) {
    final newIndex = allocateComposerItemIndex();
    final model = PostCreatorModel(index: newIndex, text: "");
    final insertAt = (listIndex + 1).clamp(0, postList.length);
    postList.insert(insertAt, model);
    postList.refresh();
    return model;
  }

  void resetComposerItemIndexSeed([int next = 1]) {
    _nextComposerItemIndex = next;
  }

  CreatorContentController ensureComposerControllerFor(int composerIndex) {
    final tag = composerIndex.toString();
    return CreatorContentController.ensure(tag: tag);
  }
}
