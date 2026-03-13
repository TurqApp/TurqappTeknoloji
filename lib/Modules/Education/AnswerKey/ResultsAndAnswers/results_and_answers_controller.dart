import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Repositories/optical_form_repository.dart';
import 'package:turqappv2/Models/Education/optical_form_model.dart';

class ResultsAndAnswersController extends GetxController {
  final OpticalFormRepository _opticalFormRepository =
      OpticalFormRepository.ensure();
  final OpticalFormModel model;
  final cevaplar = <String>[].obs;
  final dogruSayisi = 0.obs;
  final yanlisSayisi = 0.obs;
  final bosSayisi = 0.obs;
  final puan = 0.obs;

  ResultsAndAnswersController(this.model) {
    getCevaplarim();
  }

  Future<void> getCevaplarim() async {
    final fetchedCevaplar = await _opticalFormRepository.fetchUserAnswers(
      model.docID,
      FirebaseAuth.instance.currentUser!.uid,
      preferCache: true,
    );
    cevaplar.assignAll(fetchedCevaplar);
    hesaplaDogruYanlisBos();
  }

  void hesaplaDogruYanlisBos() {
    int dogru = 0;
    int yanlis = 0;
    int bos = 0;

    for (int i = 0; i < model.cevaplar.length; i++) {
      String dogruCevap = model.cevaplar[i];
      String kullaniciCevap = cevaplar.length > i ? cevaplar[i] : "";

      if (kullaniciCevap == "") {
        bos++;
      } else if (kullaniciCevap == dogruCevap) {
        dogru++;
      } else {
        yanlis++;
      }
    }

    dogruSayisi.value = dogru;
    yanlisSayisi.value = yanlis;
    bosSayisi.value = bos;
    puan.value = ((100 / model.cevaplar.length) * dogru).toInt();
  }
}
