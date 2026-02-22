import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Models/Education/OpticalFormModel.dart';

class ResultsAndAnswersController extends GetxController {
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
    final doc =
        await FirebaseFirestore.instance
            .collection("OptikKodlar")
            .doc(model.docID)
            .collection("Yanitlar")
            .doc(FirebaseAuth.instance.currentUser!.uid)
            .get();

    final fetchedCevaplar = List<String>.from(doc['cevaplar'] ?? []);
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
