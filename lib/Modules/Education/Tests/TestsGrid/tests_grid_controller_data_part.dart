part of 'tests_grid_controller.dart';

extension TestsGridControllerDataPart on TestsGridController {
  void getUserData() async {
    final user = await _userSummaryResolver.resolve(
      model.userID,
      preferCache: true,
    );
    fullName.value = user?.displayName ?? '';
    avatarUrl.value = user?.avatarUrl ?? '';
    nickname.value = user?.preferredName ?? '';
  }

  void getTotalYanit() async {
    final snapshot = await _testRepository.fetchAnswers(
      model.docID,
      preferCache: true,
    );
    totalYanit.value = snapshot.length;
  }

  void getUygulamaLinks() async {
    final data = await ConfigRepository.ensure().getLegacyConfigDoc(
          collection: 'Yönetim',
          docId: 'Genel',
          preferCache: true,
          ttl: const Duration(hours: 12),
        ) ??
        const <String, dynamic>{};
    appStore.value = (data['appStore'] ?? '').toString();
    googlePlay.value = (data['googlePlay'] ?? '').toString();
  }

  void checkIfFavorite() async {
    final userId = CurrentUserService.instance.effectiveUserId;
    final data = await _testRepository.fetchRawById(
      model.docID,
      preferCache: true,
    );

    if (data != null) {
      final favorites = List<String>.from(data['favoriler'] ?? []);
      isFavorite.value = favorites.contains(userId);
    }
  }

  void toggleFavorite() async {
    final userId = CurrentUserService.instance.effectiveUserId;
    isFavorite.value = await _testRepository.toggleFavorite(
      model.docID,
      userId: userId,
    );
  }
}
