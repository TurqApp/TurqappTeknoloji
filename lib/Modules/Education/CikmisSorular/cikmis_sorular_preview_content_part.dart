part of 'cikmis_sorular_preview.dart';

extension CikmisSorularPreviewContentPart on _CikmisSorularPreviewState {
  Widget _buildPage(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: Container(
                    color: Colors.white,
                    child: ListView(
                      controller: _scrollController,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (var entry in dersler.asMap().entries)
                              _buildSubjectSection(entry),
                            const SizedBox(height: 60),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            _buildFinishButton(),
            if (showAlert) _buildResultOverlay(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        BackButtons(text: 'past_questions.questions_title'.tr),
        Padding(
          padding: const EdgeInsets.only(right: 15),
          child: Text(
            _formatTime(_hours, _minutes, _seconds),
            style: const TextStyle(
              color: Colors.black,
              fontSize: 15,
              fontFamily: 'MontserratMedium',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubjectSection(MapEntry<int, String> entry) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () {
            _updateViewState(() {
              selectedSubject =
                  selectedSubject == entry.value ? null : entry.value;
            });
            _scrollController.jumpTo(0);
          },
          child: Container(
            height: 50,
            alignment: Alignment.centerLeft,
            color: tumderslerColors[entry.key],
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    entry.value,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontFamily: 'MontserratBold',
                    ),
                  ),
                  Icon(
                    selectedSubject == entry.value
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: Colors.white,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ),
        if (selectedSubject == entry.value) ..._buildSubjectQuestions(entry),
      ],
    );
  }

  List<Widget> _buildSubjectQuestions(MapEntry<int, String> entry) {
    final subjectQuestions = list
        .asMap()
        .entries
        .where((question) => question.value.ders == entry.value)
        .toList(growable: false);
    final children = <Widget>[];
    for (var i = 0; i < subjectQuestions.length; i++) {
      final questionEntry = subjectQuestions[i];
      children.add(_buildQuestionCard(questionEntry));
      if ((i + 1) % 3 == 0) {
        children.add(
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Center(child: AdmobKare()),
          ),
        );
      }
    }
    return children;
  }

  Widget _buildQuestionCard(
      MapEntry<int, CikmisSorularinModeli> questionEntry) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.5),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 15),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Text(
                              'tests.question_number'.trParams({
                                'index': questionEntry.value.soruNo,
                              }),
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 20,
                                fontFamily: 'MontserratBold',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        CachedNetworkImage(imageUrl: questionEntry.value.soru),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            _buildAnswerOptions(questionEntry),
          ],
        ),
      ),
    );
  }

  Widget _buildAnswerOptions(
      MapEntry<int, CikmisSorularinModeli> questionEntry) {
    final options = widget.anaBaslik == 'LGS'
        ? const ['A', 'B', 'C', 'D']
        : const ['A', 'B', 'C', 'D', 'E'];
    return Container(
      color: Colors.pinkAccent.withValues(alpha: 0.5),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        child: Row(
          mainAxisAlignment: widget.anaBaslik == 'LGS'
              ? MainAxisAlignment.spaceAround
              : MainAxisAlignment.spaceBetween,
          children: options
              .map((option) => _buildAnswerOption(questionEntry.key, option))
              .toList(),
        ),
      ),
    );
  }

  Widget _buildAnswerOption(int questionIndex, String option) {
    final isSelected = selectedAnswers[questionIndex] == option;
    return GestureDetector(
      onTap: () {
        _updateViewState(() {
          selectedAnswers[questionIndex] = isSelected ? '' : option;
        });
      },
      child: Container(
        width: 40,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? Colors.black : Colors.grey[100],
          shape: BoxShape.circle,
          border: Border.all(color: Colors.black),
        ),
        child: Text(
          option,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
    );
  }

  Widget _buildFinishButton() {
    return GestureDetector(
      onTap: _persistAndShowResults,
      child: Container(
        margin: const EdgeInsets.all(15),
        height: 50,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.green,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          'tests.finish_test'.tr,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontFamily: 'MontserratBold',
          ),
        ),
      ),
    );
  }

  void _persistAndShowResults() {
    _repository.saveResult(
      uid: CurrentUserService.instance.effectiveUserId.isNotEmpty
          ? CurrentUserService.instance.effectiveUserId
          : 'local',
      anaBaslik: widget.anaBaslik,
      sinavTuru: widget.sinavTuru,
      yil: widget.yil,
      baslik2: widget.baslik2,
      baslik3: widget.baslik3,
      cikmisSoruID: docIDCopy,
      soruSayisi: list.length,
      dogruSayisi: _correctCount,
      yanlisSayisi: _wrongCount,
      bosSayisi: _emptyCount,
      net: _netScore,
    );
    _updateViewState(() => showAlert = true);
  }

  Widget _buildResultOverlay(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            alignment: Alignment.center,
            color: Colors.black.withValues(alpha: 0.2),
          ),
        ),
        Container(
          height:
              (MediaQuery.of(context).size.height * 0.34).clamp(220.0, 260.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.only(
              topRight: Radius.circular(18),
              topLeft: Radius.circular(18),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                spreadRadius: 5,
                blurRadius: 7,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'tests.completed_title'.tr,
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 20,
                            fontFamily: 'MontserratBold',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.12),
                        borderRadius: const BorderRadius.all(
                          Radius.circular(10),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _resultItem(
                              'tests.correct'.tr, _correctCount.toString()),
                          _resultItem('tests.wrong'.tr, _wrongCount.toString()),
                          _resultItem('tests.blank'.tr, _emptyCount.toString()),
                          _resultItem(
                            'past_questions.net_label'.tr,
                            _netScore.toStringAsFixed(2),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 15),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        height: 50,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                        ),
                        child: Text(
                          'past_questions.continue_solving'.tr,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontFamily: 'MontserratMedium',
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
