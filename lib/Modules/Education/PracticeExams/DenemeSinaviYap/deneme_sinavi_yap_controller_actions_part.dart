part of 'deneme_sinavi_yap_controller.dart';

extension DenemeSinaviYapControllerActionsPart on DenemeSinaviYapController {
  void sinaviGecersizSay() {
    FirebaseFirestore.instance
        .collection("practiceExams")
        .doc(model.docID)
        .set({
      "gecersizSayilanlar": FieldValue.arrayUnion([
        _currentUserId,
      ]),
    }, SetOptions(merge: true));
    Get.back();
    showGecersizAlert();
  }

  Future<void> setData() async {
    final docID = DateTime.now().millisecondsSinceEpoch.toString();
    try {
      await FirebaseFirestore.instance
          .collection("practiceExams")
          .doc(model.docID)
          .collection("Yanitlar")
          .doc(docID)
          .set({
        "yanitlar": selectedAnswers,
        "userID": _currentUserId,
        "timeStamp": DateTime.now().millisecondsSinceEpoch.toInt(),
      });
      SetOptions(merge: true);

      List<DersVeSonuclar> yeniSonuclar = [];
      for (var ders in model.dersler) {
        int dogru = 0;
        int yanlis = 0;
        int bos = 0;

        for (var soru in list.where((soru) => soru.ders == ders)) {
          final index = list.indexOf(soru);
          final selected = selectedAnswers[index];

          if (selected == "" || selected.isEmpty) {
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

      dersSonuclari.value = yeniSonuclar;

      for (var sonuc in dersSonuclari) {
        await FirebaseFirestore.instance
            .collection("practiceExams")
            .doc(model.docID)
            .collection("Yanitlar")
            .doc(docID)
            .collection(sonuc.ders)
            .doc(docID)
            .set({
          "bos": sonuc.bos,
          "yanlis": sonuc.yanlis,
          "dogru": sonuc.dogru,
          "ders": sonuc.ders,
          "net": sonuc.dogru - (0.25 * sonuc.yanlis),
        });
        SetOptions(merge: true);
      }

      Get.back();
      sinaviBitir();
    } catch (error) {
      AppSnackbar('common.error'.tr, 'practice.answers_save_failed'.tr);
    }
  }

  Future<void> refreshData() async {
    await fetchUserData();
    await getSorular();
  }
}
