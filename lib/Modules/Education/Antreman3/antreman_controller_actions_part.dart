part of 'antreman_controller.dart';

extension AntremanControllerActionsPart on AntremanController {
  Future<int> getAntPoint() async {
    try {
      final monthlyScore = await _antremanRepository.getMonthlyScore(userID);
      if (monthlyScore != null) {
        return monthlyScore;
      }

      final userData = await _userRepository.getUserRaw(
        userID,
        preferCache: true,
      );
      return ((userData?['antPoint'] ?? 100) as num).toInt();
    } catch (e) {
      log("AntPoint alınırken hata: $e");
      return 100;
    }
  }

  Future<void> selectSubject(
      String subject, String anaBaslik, String sinavTuru) async {
    if (isSubjectSelecting.value) return;
    isSubjectSelecting.value = true;
    selectedSubject.value = subject;
    selectedSinavTuru.value = sinavTuru;
    isSortingEnabled.value = true;
    loadingProgress.value = 0.0;
    questions.clear();
    try {
      await fetchAllQuestions(anaBaslik, sinavTuru, subject);
    } finally {
      isSubjectSelecting.value = false;
    }
  }

  void setSearchQuery(String query) {
    searchQuery.value = query.trim();
    _searchDebounce?.cancel();
    if (!hasActiveSearch) {
      _searchToken++;
      isSearchLoading.value = false;
      searchResults.clear();
      return;
    }

    final token = ++_searchToken;
    isSearchLoading.value = true;
    _searchDebounce = Timer(const Duration(milliseconds: 150), () async {
      await _searchFromTypesense(searchQuery.value, token);
    });
  }

  Future<void> _searchFromTypesense(String query, int token) async {
    final normalized = query.trim();
    try {
      final result = await _questionBankSnapshotRepository.search(
        query: normalized,
        userId: _activeUid,
        limit: ReadBudgetRegistry.questionBankSearchInitialLimit,
        forceSync: true,
      );
      if (token != _searchToken || searchQuery.value.trim() != normalized) {
        return;
      }

      final rawResults = (result.data ?? const <QuestionBankModel>[])
          .where((item) => item.active)
          .toList(growable: false);
      final results = await _excludeAnsweredQuestions(rawResults);
      if (token != _searchToken || searchQuery.value.trim() != normalized) {
        return;
      }
      searchResults.assignAll(results);
    } catch (e) {
      log('Workout typesense search error: $e');
      if (token == _searchToken) {
        searchResults.clear();
      }
    } finally {
      if (token == _searchToken) {
        isSearchLoading.value = false;
      }
    }
  }

  Future<void> openSearchResult(QuestionBankModel question) async {
    if (_answeredQuestionIds.contains(question.docID)) {
      AppSnackbar("common.info".tr, "training.no_more_questions".tr);
      return;
    }
    final categoryKey = question.categoryKey.isNotEmpty
        ? question.categoryKey
        : _buildCategoryKey(
            question.anaBaslik, question.sinavTuru, question.ders);
    _activeCategoryKey.value = categoryKey;
    selectedSubject.value = question.ders;
    selectedSinavTuru.value = question.sinavTuru;
    loadingProgress.value = 1.0;
    questions.assignAll(<QuestionBankModel>[question]);
    _categoryPool
      ..clear()
      ..add(question);
    _loadedQuestionIds
      ..clear()
      ..add(question.docID);
    currentQuestionIndex.value = 0;
    await _hydrateAnswerAndSavedState(<QuestionBankModel>[question]);
    await _prefetchAspectRatios(<QuestionBankModel>[question]);
    await addToviewers(question);
    Get.to(
      () => QuestionContent(),
      transition: Transition.noTransition,
      preventDuplicates: true,
    );
  }

  Future<void> fetchAllQuestions(
      String anaBaslik, String sinavTuru, String ders) async {
    try {
      loadingProgress.value = 0.0;
      questions.clear();
      _loadedQuestionIds.clear();
      final categoryKey = _buildCategoryKey(anaBaslik, sinavTuru, ders);
      _activeCategoryKey.value = categoryKey;

      final cachedDocs = await _loadCachedCategoryPool(categoryKey);
      final filteredCachedDocs = await _excludeAnsweredQuestions(cachedDocs);
      if (filteredCachedDocs.isNotEmpty) {
        _categoryPool
          ..clear()
          ..addAll(filteredCachedDocs);

        await _appendQuestionsFromProgress(categoryKey, initialBatchSize);
        if (questions.isNotEmpty) {
          currentQuestionIndex.value = 0;
          await addToviewers(questions[0]);
          await _prefetchAspectRatios(questions.take(5).toList());
          Get.to(
            () => QuestionContent(),
            transition: Transition.noTransition,
            preventDuplicates: true,
          );
        }
      }

      final docs = await _fetchCategoryPoolDocs(
        anaBaslik,
        sinavTuru,
        ders,
        limit: ReadBudgetRegistry.antremanCategoryPoolInitialLimit,
      );
      final filteredDocs = await _excludeAnsweredQuestions(docs);
      _categoryPool
        ..clear()
        ..addAll(filteredDocs);
      await _saveCachedCategoryPool(categoryKey, docs);

      if (_categoryPool.isEmpty) {
        loadingProgress.value = 1.0;
        AppSnackbar("common.info".tr, "training.no_questions_in_category".tr);
        return;
      }

      if (questions.isEmpty) {
        await _appendQuestionsFromProgress(categoryKey, initialBatchSize);
      }
      if (questions.isNotEmpty && Get.currentRoute != '/QuestionContent') {
        currentQuestionIndex.value = 0;
        await addToviewers(questions[0]);
        await _prefetchAspectRatios(questions.take(5).toList());
        Get.to(
          () => QuestionContent(),
          transition: Transition.noTransition,
          preventDuplicates: true,
        );
      }
      // Kalan soruları arka planda doldur, ilk açılışı bloklama.
      _fillCategoryPoolInBackground(anaBaslik, sinavTuru, ders);
      loadingProgress.value = 1.0;
    } catch (e) {
      log("Sorular çekilirken hata oluştu: $e");
      // İlk yükleme sırasında geçici indeks/ağ dalgalanmalarında kullanıcıya
      // yanıltıcı hata göstermeyelim; ekranda soru yoksa üstteki bilgi mesajı
      // zaten gösteriliyor.
      loadingProgress.value = 1.0;
    }
  }

  Future<void> fetchSavedQuestions() async {
    try {
      loadingProgress.value = 0.0;
      savedQuestionsList.clear();
      final savedIds = await _antremanRepository.fetchSavedQuestionIds(
        userID,
        limit: ReadBudgetRegistry.antremanSavedQuestionInitialLimit,
      );
      if (savedIds.isEmpty) {
        loadingProgress.value = 1.0;
        return;
      }

      final models = await _fetchQuestionModelsByIds(savedIds);
      final filteredModels = await _excludeAnsweredQuestions(models);
      savedQuestionsList.assignAll(filteredModels);
      await _hydrateAnswerAndSavedState(filteredModels);
      await _prefetchAspectRatios(filteredModels.take(5).toList());
      loadingProgress.value = 1.0;
    } catch (e) {
      log("Kaydedilen sorular çekilirken hata oluştu");
      AppSnackbar("common.error".tr, "training.saved_load_failed".tr);
      loadingProgress.value = 1.0;
    }
  }

  void sortQuestions() {
    // Progress-based ordering is preserved intentionally.
  }

  Future<void> addToviewers(QuestionBankModel question) async {
    if (question.docID.isEmpty) return;
    try {
      await _antremanRepository.recordQuestionView(
        userId: userID,
        questionId: question.docID,
      );
    } catch (e) {
      AppSnackbar("common.error".tr, "training.view_update_failed".tr);
    }
  }

  void settings(BuildContext context) {
    AppSnackbar("common.info".tr, "training.settings_opening".tr);
  }

  void onScreenReEnter() {
    if (questions.isNotEmpty) {
      sortQuestions();
    }
  }

  void onQuestionScreenExit() {
    if (_pendingAnsweredQuestionIds.isNotEmpty) {
      final pendingIds = _pendingAnsweredQuestionIds.toList(growable: false);
      for (final questionId in pendingIds) {
        _consumeAnsweredQuestionForExit(questionId);
      }
      _pendingAnsweredQuestionIds.clear();
    }

    if (questions.isEmpty) {
      currentQuestionIndex.value = 0;
      justAnswered.value = '';
      return;
    }

    currentQuestionIndex.value =
        currentQuestionIndex.value.clamp(0, questions.length - 1).toInt();
    sortQuestions();
    justAnswered.value = '';
  }

  Future<void> fetchUniqueFields() async {
    final payload = await _antremanRepository.fetchUniqueFields(
      preferCache: true,
      forceRefresh: false,
    );
    log('Ana Başlıklar: ${payload['anaBaslik'] ?? const <String>[]}');
    log('Dersler: ${payload['ders'] ?? const <String>[]}');
    log('Sınav Türleri: ${payload['sinavTuru'] ?? const <String>[]}');
  }

  Future<void> fetchMoreQuestions() async {
    await fetchMoreQuestionsWithCount(batchSize);
  }

  Future<void> fetchMoreQuestionsWithCount(int count) async {
    if (_activeCategoryKey.value.isEmpty || _categoryPool.isEmpty) return;
    if (_isFetchingMore) return;

    try {
      _isFetchingMore = true;
      await _appendQuestionsFromProgress(_activeCategoryKey.value, count);
      loadingProgress.value = 1.0;
    } catch (e) {
      log("Daha fazla soru çekilirken hata oluştu: $e");
      AppSnackbar("common.error".tr, "training.fetch_more_failed".tr);
      loadingProgress.value = 1.0;
    } finally {
      _isFetchingMore = false;
    }
  }

  String _buildCategoryKey(String anaBaslik, String sinavTuru, String ders) {
    return '$anaBaslik|$sinavTuru|$ders';
  }

  int _gcd(int a, int b) {
    while (b != 0) {
      final t = b;
      b = a % b;
      a = t;
    }
    return a.abs();
  }

  int _coprimeStep(int n, math.Random random) {
    if (n <= 1) return 1;
    int step = random.nextInt(n - 1) + 1;
    int guard = 0;
    while (_gcd(step, n) != 1 && guard < n * 2) {
      step = random.nextInt(n - 1) + 1;
      guard++;
    }
    return step;
  }

  Map<String, dynamic> _newProgressState(int n, {int cycle = 0}) {
    final random = math.Random();
    return {
      'cursor': 0,
      'n': n,
      'a': _coprimeStep(n, random),
      'b': n > 0 ? random.nextInt(n) : 0,
      'cycle': cycle,
      'updatedDate': DateTime.now().millisecondsSinceEpoch,
    };
  }

  Future<List<QuestionBankModel>> _fetchCategoryPoolDocs(
      String anaBaslik, String sinavTuru, String ders,
      {int? limit}) async {
    return _antremanRepository.fetchCategoryQuestions(
      anaBaslik,
      sinavTuru,
      ders,
      limit: limit,
    );
  }

  Future<void> _fillCategoryPoolInBackground(
      String anaBaslik, String sinavTuru, String ders) async {
    try {
      final onWifi = await ConnectivityHelper.isWifi();
      if (!onWifi) return;
      final all = await _fetchCategoryPoolDocs(anaBaslik, sinavTuru, ders);
      await _saveCachedCategoryPool(
        _buildCategoryKey(anaBaslik, sinavTuru, ders),
        all,
      );
      final filteredAll = await _excludeAnsweredQuestions(all);
      if (_activeCategoryKey.value !=
          _buildCategoryKey(anaBaslik, sinavTuru, ders)) {
        return;
      }
      final existingIds = _categoryPool.map((e) => e.docID).toSet();
      for (final q in filteredAll) {
        if (!existingIds.contains(q.docID)) {
          _categoryPool.add(q);
          existingIds.add(q.docID);
        }
      }
    } catch (e) {
      log('Background pool fill error: $e');
    }
  }

  Future<void> _appendQuestionsFromProgress(
      String categoryKey, int count) async {
    if (_categoryPool.isEmpty || count <= 0) return;

    final progressData = await _antremanRepository.getProgress(
      userID,
      categoryKey,
    );
    final n = _categoryPool.length;
    Map<String, dynamic> progress;
    if (progressData == null) {
      progress = _newProgressState(n);
      await _antremanRepository.setProgress(userID, categoryKey, progress,
          merge: false);
    } else {
      progress = Map<String, dynamic>.from(progressData);
      final int prevN = (progress['n'] as num?)?.toInt() ?? 0;
      if (prevN != n || n == 0) {
        progress = _newProgressState(n,
            cycle: (progress['cycle'] as num?)?.toInt() ?? 0);
        await _antremanRepository.setProgress(userID, categoryKey, progress);
      }
    }

    int cursor = (progress['cursor'] as num?)?.toInt() ?? 0;
    int a = (progress['a'] as num?)?.toInt() ?? 1;
    int b = (progress['b'] as num?)?.toInt() ?? 0;
    int cycle = (progress['cycle'] as num?)?.toInt() ?? 0;

    final appended = <QuestionBankModel>[];
    int guard = 0;
    while (appended.length < count && guard < n * 3) {
      if (n == 0) break;
      if (cursor >= n) {
        cycle += 1;
        final reset = _newProgressState(n, cycle: cycle);
        cursor = 0;
        a = reset['a'] as int;
        b = reset['b'] as int;
      }
      final idx = (a * cursor + b) % n;
      final q = _categoryPool[idx];
      if (!_loadedQuestionIds.contains(q.docID) &&
          !_answeredQuestionIds.contains(q.docID)) {
        appended.add(q);
        _loadedQuestionIds.add(q.docID);
      }
      cursor += 1;
      guard += 1;
    }

    if (appended.isEmpty) return;

    await _antremanRepository.setProgress(userID, categoryKey, {
      'cursor': cursor,
      'n': n,
      'a': a,
      'b': b,
      'cycle': cycle,
      'updatedDate': DateTime.now().millisecondsSinceEpoch,
    });

    questions.addAll(appended);
    await _hydrateAnswerAndSavedState(appended);
    await _prefetchAspectRatios(appended.take(5).toList());
  }

  Future<void> _hydrateAnswerAndSavedState(
      List<QuestionBankModel> models) async {
    if (models.isEmpty) return;
    final ids = models.map((e) => e.docID).toList();
    final savedSet = await _fetchSavedIds(ids);

    for (final q in models) {
      final key = q.docID;
      selectedAnswers[key] = selectedAnswers[key] ?? '';
      initialAnswers[key] = initialAnswers[key] ?? '';
      answerStates[key] = answerStates[key] ?? false;
      likedQuestions[key] = q.begeniler.contains(userID);
      savedQuestions[key] = savedSet.contains(key);
    }
  }

  Future<Set<String>> _fetchAnsweredIds(List<String> docIds) async {
    return _antremanRepository.fetchAnsweredIds(userID, docIds);
  }

  Future<List<QuestionBankModel>> _excludeAnsweredQuestions(
    List<QuestionBankModel> models,
  ) async {
    if (models.isEmpty) return const <QuestionBankModel>[];
    final ids = models.map((e) => e.docID).toList(growable: false);
    final answeredIds = await _fetchAnsweredIds(ids);
    _answeredQuestionIds.addAll(answeredIds);
    return models
        .where((model) => !_answeredQuestionIds.contains(model.docID))
        .toList(growable: false);
  }

  int _removeAnsweredQuestionFromLocalState(String questionId) {
    _categoryPool.removeWhere((question) => question.docID == questionId);
    _loadedQuestionIds.remove(questionId);
    searchResults.removeWhere((question) => question.docID == questionId);
    savedQuestionsList.removeWhere((question) => question.docID == questionId);
    selectedAnswers.remove(questionId);
    initialAnswers.remove(questionId);
    answerStates.remove(questionId);

    final removeIndex =
        questions.indexWhere((question) => question.docID == questionId);
    if (removeIndex >= 0) {
      questions.removeAt(removeIndex);
    }
    return removeIndex;
  }

  Future<void> consumeAnsweredQuestion(String questionId) async {
    if (questionId.isEmpty) return;
    _answeredQuestionIds.add(questionId);
    final removeIndex = _removeAnsweredQuestionFromLocalState(questionId);

    if (questions.isEmpty) {
      currentQuestionIndex.value = 0;
      await fetchMoreQuestionsWithCount(batchSize);
      if (questions.isEmpty) {
        AppSnackbar("common.info".tr, "training.no_more_questions".tr);
        return;
      }
    }

    final nextIndex = (removeIndex < 0
            ? currentQuestionIndex.value.clamp(0, questions.length - 1)
            : removeIndex.clamp(0, questions.length - 1))
        .toInt();
    currentQuestionIndex.value = nextIndex;
    await addToviewers(questions[nextIndex]);
    final nextQuestion = questions[nextIndex];
    if (!imageAspectRatios.containsKey(nextQuestion.soru)) {
      final aspectRatio = await getImageAspectRatio(nextQuestion.soru);
      imageAspectRatios[nextQuestion.soru] = aspectRatio ?? 1.0;
    }
    await maybePrefetchMoreQuestions();
  }

  void _consumeAnsweredQuestionForExit(String questionId) {
    if (questionId.isEmpty) return;
    _answeredQuestionIds.add(questionId);
    _removeAnsweredQuestionFromLocalState(questionId);
  }

  Future<void> maybePrefetchMoreQuestions() async {
    if (_activeCategoryKey.value.isEmpty || questions.isEmpty) return;
    final remainingAfterCurrent =
        questions.length - (currentQuestionIndex.value + 1);
    if (remainingAfterCurrent > prefetchRemainingThreshold) return;
    await fetchMoreQuestionsWithCount(batchSize);
  }

  Future<Set<String>> _fetchSavedIds(List<String> docIds) async {
    return _antremanRepository.fetchSavedIds(userID, docIds);
  }

  Future<List<QuestionBankModel>> _fetchQuestionModelsByIds(
      List<String> ids) async {
    return _antremanRepository.fetchQuestionModelsByIds(ids);
  }

  Future<void> _prefetchAspectRatios(List<QuestionBankModel> models) async {
    await Future.wait(
      models.map((question) async {
        if (!imageAspectRatios.containsKey(question.soru)) {
          final aspectRatio = await getImageAspectRatio(question.soru);
          imageAspectRatios[question.soru] = aspectRatio ?? 1.0;
        }
      }),
    );
  }

  String _cacheKeyForCategory(String categoryKey) {
    return '$_categoryCachePrefix${_activeUid}_$categoryKey';
  }

  String _cacheTimeKeyForCategory(String categoryKey) {
    return '$_categoryCacheTimePrefix${_activeUid}_$categoryKey';
  }

  Future<List<QuestionBankModel>> _loadCachedCategoryPool(
      String categoryKey) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheTime = prefs.getInt(_cacheTimeKeyForCategory(categoryKey));
      final payload = prefs.getString(_cacheKeyForCategory(categoryKey));
      if (cacheTime == null || payload == null || payload.isEmpty) {
        return <QuestionBankModel>[];
      }

      final age = DateTime.now().difference(
        DateTime.fromMillisecondsSinceEpoch(cacheTime),
      );
      if (age > _categoryCacheTtl) {
        return <QuestionBankModel>[];
      }

      final decoded = jsonDecode(payload);
      if (decoded is! List) return <QuestionBankModel>[];

      return decoded
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .map(QuestionBankModel.fromJson)
          .toList();
    } catch (e) {
      log('Kategori cache okunamadi: $e');
      return <QuestionBankModel>[];
    }
  }

  Future<void> _saveCachedCategoryPool(
    String categoryKey,
    List<QuestionBankModel> docs,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final payload = jsonEncode(
        docs.map((question) => question.toJson()).toList(),
      );
      await prefs.setString(_cacheKeyForCategory(categoryKey), payload);
      await prefs.setInt(
        _cacheTimeKeyForCategory(categoryKey),
        DateTime.now().millisecondsSinceEpoch,
      );
    } catch (e) {
      log('Kategori cache yazilamadi: $e');
    }
  }

  Future<void> _prefetchSelectedMainCategoryOnWifi(String category) async {
    try {
      final onWifi = await ConnectivityHelper.isWifi();
      if (!onWifi) return;

      final categorySubjects = subjects[category];
      if (categorySubjects == null) return;

      for (final entry in categorySubjects.entries) {
        final sinavTuru = entry.key;
        for (final ders in entry.value) {
          final categoryKey = _buildCategoryKey(category, sinavTuru, ders);
          final cached = await _loadCachedCategoryPool(categoryKey);
          if (cached.length >= _mainCategoryWarmupLimit) {
            continue;
          }

          final docs = await _fetchCategoryPoolDocs(
            category,
            sinavTuru,
            ders,
            limit: _mainCategoryWarmupLimit,
          );
          if (docs.isNotEmpty) {
            await _saveCachedCategoryPool(categoryKey, docs);
            await _prefetchAspectRatios(docs.take(3).toList());
          }
        }
      }
    } catch (e) {
      log('Secilen ana baslik warm cache hatasi: $e');
    }
  }
}
