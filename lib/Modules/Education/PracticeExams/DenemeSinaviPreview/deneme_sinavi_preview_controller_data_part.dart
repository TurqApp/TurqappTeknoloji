part of 'deneme_sinavi_preview_controller.dart';

extension DenemeSinaviPreviewControllerDataPart
    on DenemeSinaviPreviewController {
  Future<void> _fetchUserDataImpl() async {
    try {
      final data = await _userSummaryResolver.resolve(
            model.userID,
            preferCache: true,
          ) ??
          _userSummaryResolver.resolveFromMaps(model.userID);
      nickname.value = data.preferredName;
      avatarUrl.value = data.avatarUrl;
    } catch (error) {
      AppSnackbar('common.error'.tr, 'practice.user_load_failed'.tr);
    } finally {
      isLoading.value = false;
      isInitialized.value = true;
    }
  }

  Future<void> _getGecersizlikDurumuImpl() async {
    try {
      final data = await _practiceExamRepository.fetchRawById(
        model.docID,
        preferCache: true,
      );

      if (data == null || !data.containsKey('gecersizSayilanlar')) {
        sinavaGirebilir.value = true;
        return;
      }

      final gecersizSayilanlar = List<String>.from(
        data['gecersizSayilanlar'] ?? [],
      );
      sinavaGirebilir.value = !gecersizSayilanlar.contains(_currentUserId);
    } catch (error) {
      AppSnackbar('common.error'.tr, 'practice.invalidity_load_failed'.tr);
      sinavaGirebilir.value = true;
    }
  }

  Future<Map<String, num>?> _getLatestExamSummaryImpl() async {
    try {
      final uid = _currentUserId;
      if (uid.isEmpty) return null;
      final answers = await _practiceExamRepository.fetchAnswers(
        model.docID,
        preferCache: true,
      );
      final userAnswers = answers
          .where((doc) => (doc["userID"] ?? "").toString() == uid)
          .toList(growable: false);

      if (userAnswers.isEmpty) return null;

      Map<String, dynamic> latest = userAnswers.first;
      for (final doc in userAnswers) {
        final currentTs = (doc["timeStamp"] ?? 0) as num;
        final latestTs = (latest["timeStamp"] ?? 0) as num;
        if (currentTs > latestTs) {
          latest = doc;
        }
      }

      final latestId = (latest["_docId"] ?? latest["id"] ?? "").toString();
      if (latestId.isEmpty) return null;

      num dogru = 0;
      num yanlis = 0;
      num bos = 0;
      num net = 0;

      final results = await _practiceExamRepository.fetchLessonResults(
        model.docID,
        latestId,
        model.dersler,
      );
      for (final result in results) {
        dogru += result.dogru;
        yanlis += result.yanlis;
        bos += result.bos;
        net += result.net;
      }

      return {
        "dogru": dogru,
        "yanlis": yanlis,
        "bos": bos,
        "net": net,
      };
    } catch (_) {
      return null;
    }
  }

  Future<void> _basvuruKontrolImpl() async {
    try {
      basvuranSayisi.value =
          await _practiceExamRepository.fetchParticipantCount(
        model.docID,
        preferCache: true,
      );
      dahaOnceBasvurdu.value = await _practiceExamRepository.hasApplication(
        model.docID,
        _currentUserId,
      );
    } catch (error) {
      AppSnackbar('common.error'.tr, 'practice.application_check_failed'.tr);
    }
  }

  Future<void> _refreshDataImpl() async {
    currentTime.value = DateTime.now().millisecondsSinceEpoch;
    await fetchUserData();
    await basvuruKontrol();
    await syncSavedState();
  }

  Future<void> _syncSavedStateImpl() async {
    final savedController = SavedPracticeExamsController.ensure();
    if (savedController.savedExamIds.isEmpty &&
        !savedController.isLoading.value) {
      await savedController.loadSavedExams();
    }
    isSaved.value = savedController.savedExamIds.contains(model.docID);
  }
}
