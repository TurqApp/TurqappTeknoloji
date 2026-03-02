import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Modules/Education/PracticeExams/sinav_model.dart';

class DenemeTurleriListesiController extends GetxController {
  var list = <SinavModel>[].obs;
  var isLoading = false.obs;
  var isInitialized = false.obs;

  final String sinavTuru;

  DenemeTurleriListesiController({required this.sinavTuru});

  @override
  void onInit() {
    super.onInit();
    getData();
  }

  Future<void> getData() async {
    isLoading.value = true;
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection("practiceExams")
          .where("sinavTuru", isEqualTo: sinavTuru)
          .get();

      list.clear();
      for (var doc in snapshot.docs) {
        String cover = doc.get("cover");
        String sinavAciklama = doc.get("sinavAciklama");
        String sinavAdi = doc.get("sinavAdi");
        String sinavTuru = doc.get("sinavTuru");
        num timeStamp = doc.get("timeStamp");
        String kpssSecilenLisans = doc.get("kpssSecilenLisans");
        List<String> dersler = List<String>.from(doc['dersler']);
        List<String> soruSayisi = List<String>.from(doc['soruSayilari']);
        String userID = doc.get("userID");
        bool taslak = doc.get("taslak");
        bool public = doc.get("public");
        num bitisDk = doc.get("bitisDk");
        num bitis = doc.get("bitis");

        list.add(
          SinavModel(
            docID: doc.id,
            cover: cover,
            sinavTuru: sinavTuru,
            timeStamp: timeStamp,
            sinavAciklama: sinavAciklama,
            sinavAdi: sinavAdi,
            kpssSecilenLisans: kpssSecilenLisans,
            dersler: dersler,
            userID: userID,
            public: public,
            taslak: taslak,
            soruSayilari: soruSayisi,
            bitis: bitis,
            bitisDk: bitisDk,
          ),
        );
      }
    } catch (error) {
      AppSnackbar("Hata", "Sınavlar yüklenemedi.");
    } finally {
      isLoading.value = false;
      isInitialized.value = true;
    }
  }
}
