part of 'answer_key_content_controller.dart';

extension AnswerKeyContentControllerDataPart on AnswerKeyContentController {
  void _initialize() {
    final currentUserId = _resolveAnswerKeyContentCurrentUidFacade();
    _primeBookmarkState(currentUserId);
    unawaited(_loadBookmarkState(currentUserId));
  }

  void _primeBookmarkState(String currentUserId) {
    if (currentUserId.isEmpty) {
      isBookmarked.value = false;
      return;
    }
    final cachedIds = _answerKeyContentSavedIdsByUser[currentUserId];
    if (cachedIds != null) {
      isBookmarked.value = cachedIds.contains(model.docID);
      return;
    }
    isBookmarked.value = false;
  }

  Future<void> _loadBookmarkState(String currentUserId) async {
    if (currentUserId.isEmpty) return;

    try {
      final savedIds = await _loadAnswerKeyContentSavedIdsFacade(currentUserId);
      isBookmarked.value = savedIds.contains(model.docID);
    } catch (e) {
      log('Kaydet durumu okunamadı: $e');
    }
  }

  void _updateViewCount() {
    final currentUserId = _resolveAnswerKeyContentCurrentUidFacade();
    if (currentUserId.isNotEmpty && model.userID != currentUserId) {
      FirebaseFirestore.instance.collection('books').doc(model.docID).update({
        'viewCount': FieldValue.increment(1),
      }).then((_) {
        model.viewCount += 1;
        return null;
      }).catchError((e) {
        log('Görüntüleme güncelleme hatası: $e');
        return null;
      });
    }
  }

  Future<void> toggleBookmark() async {
    final userId = _resolveAnswerKeyContentCurrentUidFacade();
    if (userId.isEmpty) return;

    try {
      if (isBookmarked.value) {
        await _userSubcollectionRepository.deleteEntry(
          userId,
          subcollection: 'books',
          docId: model.docID,
        );
        isBookmarked.value = false;
        _answerKeyContentSavedIdsByUser[userId]?.remove(model.docID);
        return;
      }

      await _userSubcollectionRepository.upsertEntry(
        userId,
        subcollection: 'books',
        docId: model.docID,
        data: {
          'createdAt': DateTime.now().millisecondsSinceEpoch,
        },
      );
      isBookmarked.value = true;
      _answerKeyContentSavedIdsByUser
          .putIfAbsent(userId, () => <String>{})
          .add(model.docID);
    } catch (e) {
      log('Yer isareti degistirme hatasi: $e');
    }
  }
}
