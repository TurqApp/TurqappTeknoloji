part of 'deneme_sinavi_yap_controller.dart';

class _DenemeSinaviYapControllerRuntimePart {
  final DenemeSinaviYapController _controller;

  const _DenemeSinaviYapControllerRuntimePart(this._controller);

  void handleOnInit() {
    _controller.selection.value = _controller.uyariAtla ? 0 : 1;
    _controller.fetchUserData();
    _controller.getSorular();
    _controller.checkInternetConnection();
    WidgetsBinding.instance.addObserver(_controller);
  }

  void handleOnClose() {
    WidgetsBinding.instance.removeObserver(_controller);
  }

  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      print('Uygulama arka plana atıldı.');
    } else if (state == AppLifecycleState.resumed) {
      print('Uygulama ön plana geldi.');
      if (_controller.hataCount.value == 1) {
        sinaviGecersizSay();
      } else {
        AppSnackbar(
          'common.warning'.tr,
          'practice.background_warning'.tr,
        );
      }
      _controller.hataCount.value += 1;
      _controller.selectedAnswers.value =
          List<String>.filled(_controller.list.length, '');
    } else if (state == AppLifecycleState.detached) {
      sinaviGecersizSay();
    }
  }

  Future<void> fetchUserData() async {
    try {
      final data = await _controller._userSummaryResolver.resolve(
        _controller._currentUserId,
        preferCache: true,
      );
      _controller.fullName.value = data?.displayName.trim() ?? '';
    } catch (_) {
      AppSnackbar('common.error'.tr, 'practice.user_load_failed'.tr);
    } finally {
      _controller.isLoading.value = false;
      _controller.isInitialized.value = true;
    }
  }

  Future<void> getSorular() async {
    try {
      final questions =
          await _controller._practiceExamRepository.fetchQuestions(
        _controller.model.docID,
        preferCache: true,
      );
      _controller.list.value = questions;
      _controller.selectedAnswers.value =
          List<String>.filled(questions.length, '');
    } catch (_) {
      AppSnackbar('common.error'.tr, 'practice.questions_load_failed'.tr);
    } finally {
      _controller.isLoading.value = false;
      _controller.isInitialized.value = true;
    }
  }

  void checkInternetConnection() {
    Connectivity().onConnectivityChanged.listen((results) {
      _controller.isConnected.value =
          results.any((r) => r != ConnectivityResult.none);
      print(
        _controller.isConnected.value
            ? 'Connectivity available.'
            : 'No internet connection.',
      );
    });
  }

  void sinaviGecersizSay() {
    FirebaseFirestore.instance
        .collection('practiceExams')
        .doc(_controller.model.docID)
        .set({
      'gecersizSayilanlar': FieldValue.arrayUnion([
        _controller._currentUserId,
      ]),
    }, SetOptions(merge: true));
    Get.back();
    _controller.showGecersizAlert();
  }

  Future<void> setData() async {
    final docID = DateTime.now().millisecondsSinceEpoch.toString();
    try {
      await FirebaseFirestore.instance
          .collection('practiceExams')
          .doc(_controller.model.docID)
          .collection('Yanitlar')
          .doc(docID)
          .set({
        'yanitlar': _controller.selectedAnswers,
        'userID': _controller._currentUserId,
        'timeStamp': DateTime.now().millisecondsSinceEpoch.toInt(),
      });

      final yeniSonuclar = <DersVeSonuclar>[];
      for (final ders in _controller.model.dersler) {
        int dogru = 0;
        int yanlis = 0;
        int bos = 0;

        for (final soru
            in _controller.list.where((soru) => soru.ders == ders)) {
          final index = _controller.list.indexOf(soru);
          final selected = _controller.selectedAnswers[index];

          if (selected.isEmpty) {
            bos++;
          } else if (selected == soru.dogruCevap) {
            dogru++;
          } else {
            yanlis++;
          }
        }

        yeniSonuclar.add(
          DersVeSonuclar(ders: ders, dogru: dogru, yanlis: yanlis, bos: bos),
        );
      }

      _controller.dersSonuclari.value = yeniSonuclar;

      for (final sonuc in _controller.dersSonuclari) {
        await FirebaseFirestore.instance
            .collection('practiceExams')
            .doc(_controller.model.docID)
            .collection('Yanitlar')
            .doc(docID)
            .collection(sonuc.ders)
            .doc(docID)
            .set({
          'bos': sonuc.bos,
          'yanlis': sonuc.yanlis,
          'dogru': sonuc.dogru,
          'ders': sonuc.ders,
          'net': sonuc.dogru - (0.25 * sonuc.yanlis),
        });
      }

      Get.back();
      _controller.sinaviBitir();
    } catch (_) {
      AppSnackbar('common.error'.tr, 'practice.answers_save_failed'.tr);
    }
  }

  Future<void> refreshData() async {
    await fetchUserData();
    await getSorular();
  }
}
