part of 'answer_key_content_controller.dart';

extension AnswerKeyContentControllerDataPart on AnswerKeyContentController {
  void _initialize() {
    final currentUserId = AnswerKeyContentController._resolveCurrentUid();
    _primeBookmarkState(currentUserId);
    unawaited(_loadBookmarkState(currentUserId));
  }

  void _primeBookmarkState(String currentUserId) {
    if (currentUserId.isEmpty) {
      isBookmarked.value = false;
      return;
    }
    final cachedIds = AnswerKeyContentController._savedIdsByUser[currentUserId];
    if (cachedIds != null) {
      isBookmarked.value = cachedIds.contains(model.docID);
      return;
    }
    isBookmarked.value = false;
  }

  Future<void> _loadBookmarkState(String currentUserId) async {
    if (currentUserId.isEmpty) return;

    try {
      final savedIds =
          await AnswerKeyContentController._loadSavedIds(currentUserId);
      isBookmarked.value = savedIds.contains(model.docID);
    } catch (e) {
      log('Kaydet durumu okunamadı: $e');
    }
  }

  void _updateViewCount() {
    final currentUserId = AnswerKeyContentController._resolveCurrentUid();
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
    final userId = AnswerKeyContentController._resolveCurrentUid();
    if (userId.isEmpty) return;

    try {
      if (isBookmarked.value) {
        await _userSubcollectionRepository.deleteEntry(
          userId,
          subcollection: 'books',
          docId: model.docID,
        );
        isBookmarked.value = false;
        AnswerKeyContentController._savedIdsByUser[userId]?.remove(model.docID);
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
      AnswerKeyContentController._savedIdsByUser
          .putIfAbsent(userId, () => <String>{})
          .add(model.docID);
    } catch (e) {
      log('Yer isareti degistirme hatasi: $e');
    }
  }
}
