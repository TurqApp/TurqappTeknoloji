part of 'antreman_controller.dart';

extension AntremanControllerQuestionActionsPart on AntremanController {
  Future<void> addToSonraCoz(QuestionBankModel question) async {
    if (question.docID.isEmpty) return;
    final key = question.docID;
    final isSaved = savedQuestions[key] ?? false;
    try {
      await _antremanRepository.toggleSavedQuestion(
        userId: userID,
        questionId: question.docID,
        currentlySaved: isSaved,
      );
      savedQuestions[key] = !isSaved;
      AppSnackbar(
        "common.success".tr,
        isSaved ? "training.saved_removed".tr : "training.saved_added".tr,
      );
    } catch (e) {
      AppSnackbar(
        "common.error".tr,
        isSaved
            ? "training.saved_remove_failed".tr
            : "training.saved_update_failed".tr,
      );
    }
  }

  Future<void> addTolikes(QuestionBankModel question) async {
    if (question.docID.isEmpty) return;
    final key = question.docID;
    final isLiked = likedQuestions[key] ?? false;
    try {
      await _antremanRepository.toggleLikedQuestion(
        userId: userID,
        questionId: question.docID,
        currentlyLiked: isLiked,
      );

      if (isLiked) {
        question.begeniler.remove(userID);
      } else {
        question.begeniler.add(userID);
      }
      likedQuestions[key] = !isLiked;
      AppSnackbar(
        "common.success".tr,
        isLiked ? "training.like_removed".tr : "training.liked".tr,
      );
    } catch (e) {
      AppSnackbar(
        "common.error".tr,
        isLiked
            ? "training.like_remove_failed".tr
            : "training.like_add_failed".tr,
      );
    }
  }

  Future<void> addToPaylasanlar(QuestionBankModel question) async {
    if (question.docID.isEmpty) return;
    try {
      await ShareActionGuard.run(() async {
        final shareId = 'question:${question.docID}';
        final shortUrl = await ShortLinkService().getEducationPublicUrl(
          shareId: shareId,
          title: 'training.share_question_link_title'.trParams({
            'exam': question.sinavTuru,
            'lesson': question.ders,
            'number': question.soruNo.toString(),
          }),
          desc: question.anaBaslik.isNotEmpty
              ? question.anaBaslik
              : 'training.share_question_desc'.tr,
          imageUrl: question.soru.isNotEmpty ? question.soru : null,
          existingShortUrl: question.shortUrl,
        );

        await ShareLinkService.shareUrl(
          url: shortUrl,
          title: 'training.share_question_title'.trParams({
            'exam': question.sinavTuru,
            'lesson': question.ders,
          }),
          subject: 'training.share_question_title'.trParams({
            'exam': question.sinavTuru,
            'lesson': question.ders,
          }),
        );

        unawaited(
          _antremanRepository
              .recordSharedQuestion(
                userId: userID,
                questionId: question.docID,
              )
              .catchError((_) {}),
        );
      });
    } catch (_) {
      AppSnackbar("common.error".tr, "training.share_failed".tr);
    }
  }

  Future<void> submitAnswer(
    String selectedAnswer,
    QuestionBankModel question,
  ) async {
    if (question.docID.isEmpty) return;
    final key = question.docID;

    if ((selectedAnswers[key] ?? '').isNotEmpty) {
      AppSnackbar("common.info".tr, "training.answer_locked".tr);
      return;
    }

    selectedAnswers[key] = selectedAnswer;
    initialAnswers[key] = selectedAnswer;
    bool isCorrect = selectedAnswer == question.dogruCevap;
    answerStates[key] = isCorrect;
    justAnswered.value = isCorrect ? 'correct' : 'incorrect';

    try {
      final Map<String, dynamic> userData = await _userRepository.getUserRaw(
            userID,
            preferCache: true,
          ) ??
          const <String, dynamic>{};
      await _antremanRepository.submitAnswer(
        userId: userID,
        question: question,
        selectedAnswer: selectedAnswer,
        categoryKey: question.categoryKey.isNotEmpty
            ? question.categoryKey
            : _activeCategoryKey.value,
        userData: userData,
      );
      _answeredQuestionIds.add(question.docID);
      _pendingAnsweredQuestionIds.add(question.docID);
    } catch (e) {
      log('submitAnswer error for ${question.docID}: $e');
      if (e.toString().contains('already_answered')) {
        AppSnackbar("common.info".tr, "training.answer_saved".tr);
        _answeredQuestionIds.add(question.docID);
        _pendingAnsweredQuestionIds.add(question.docID);
      } else {
        AppSnackbar("common.error".tr, "training.answer_save_failed".tr);
      }
    }
  }

  Future<double?> getImageAspectRatio(String imageUrl) async {
    try {
      final response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode == 200) {
        final Uint8List bytes = response.bodyBytes;
        final ui.Image image = await decodeImageFromList(bytes);
        return image.width / image.height;
      } else {
        debugPrint('Image load failed: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('Error fetching image aspect ratio: $e');
      return null;
    }
  }

  void nextQuestion() {
    if (currentQuestionIndex.value < questions.length - 1) {
      currentQuestionIndex.value++;
      addToviewers(questions[currentQuestionIndex.value]);
      final nextQuestion = questions[currentQuestionIndex.value];
      if (!imageAspectRatios.containsKey(nextQuestion.soru)) {
        getImageAspectRatio(nextQuestion.soru).then((aspectRatio) {
          imageAspectRatios[nextQuestion.soru] = aspectRatio ?? 1.0;
        });
      }
      unawaited(maybePrefetchMoreQuestions());
    } else {
      AppSnackbar("common.info".tr, "training.no_more_questions".tr);
    }
  }
}
