part of 'booklet_preview_controller.dart';

class BookletPreviewControllerRuntimePart {
  const BookletPreviewControllerRuntimePart(this.controller);

  final BookletPreviewController controller;

  void initialize() {
    final currentUserId = CurrentUserService.instance.effectiveUserId;
    controller._loadBookmarkState(currentUserId);
    controller.fetchAnswerKeys();
    controller.fetchUserData();
  }

  Future<void> loadBookmarkState(String currentUserId) async {
    if (currentUserId.isEmpty) return;

    try {
      final savedDoc = await controller._subcollectionRepository.getEntry(
        currentUserId,
        subcollection: 'books',
        docId: controller.model.docID,
        preferCache: true,
      );
      controller.isBookmarked.value = savedDoc != null;
    } catch (_) {}
  }

  Future<void> fetchAnswerKeys() async {
    try {
      final rawItems = await controller._bookletRepository.fetchAnswerKeys(
        controller.model.docID,
        preferCache: true,
      );
      final newList = <AnswerKeySubModel>[];
      for (final item in rawItems) {
        final data = Map<String, dynamic>.from(
          (item['data'] as Map?) ?? const <String, dynamic>{},
        );
        final baslik = (data['baslik'] ?? '').toString();
        final rawCevaplar = data['dogruCevaplar'];
        final cevaplar = rawCevaplar is List
            ? rawCevaplar.map((e) => e.toString()).toList()
            : <String>[];
        final sira = data['sira'] is num
            ? data['sira'] as num
            : num.tryParse((data['sira'] ?? '0').toString()) ?? 0;

        newList.add(
          AnswerKeySubModel(
            baslik: baslik,
            docID: (item['id'] ?? '').toString(),
            dogruCevaplar: cevaplar,
            sira: sira,
          ),
        );
      }
      newList.sort((a, b) => a.sira.compareTo(b.sira));
      controller.answerKeys.assignAll(newList);
    } catch (_) {}
  }

  Future<void> fetchUserData() async {
    try {
      final data = await controller._userSummaryResolver.resolve(
            controller.model.userID,
            preferCache: true,
          ) ??
          controller._userSummaryResolver.resolveFromMaps(
            controller.model.userID,
          );
      controller.nickname.value = data.nickname;
      controller.avatarUrl.value = data.avatarUrl;
      controller.fullName.value = data.displayName;
      if (controller.fullName.value.isEmpty) {
        controller.fullName.value = controller.nickname.value;
      }
    } catch (_) {}
  }
}
