import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Modules/Education/PracticeExams/soru_model.dart';

class SinavSorusuHazirlaController extends GetxController {
  var list = <SoruModel>[].obs;
  var isLoading = false.obs;
  var isInitialized = false.obs;

  String docID;
  String sinavTuru;
  List<String> tumDersler;
  List<String> derslerinSoruSayilari;
  Function() complated;

  SinavSorusuHazirlaController({
    required this.docID,
    required this.sinavTuru,
    required this.tumDersler,
    required this.derslerinSoruSayilari,
    required this.complated,
  });

  @override
  void onInit() {
    super.onInit();
    getSorular();
  }

  Future<void> getSorular() async {
    isLoading.value = true;
    try {
      QuerySnapshot snap = await FirebaseFirestore.instance
          .collection("practiceExams")
          .doc(docID)
          .collection("Sorular")
          .get();

      if (snap.docs.isNotEmpty) {
        list.clear();
        for (var doc in snap.docs) {
          String ders = doc.get("ders");
          String dogruCevap = doc.get("dogruCevap");
          num id = doc.get("id");
          String konu = doc.get("konu");
          String soru = doc.get("soru");

          list.add(
            SoruModel(
              id: id.toInt(),
              soru: soru,
              ders: ders,
              konu: konu,
              dogruCevap: dogruCevap,
              docID: doc.id,
            ),
          );
        }
      } else {
        await setList();
      }
    } catch (error) {
      AppSnackbar("Hata", "Sorular yüklenemedi.");
    } finally {
      isLoading.value = false;
      isInitialized.value = true;
    }
  }

  Future<void> setList() async {
    try {
      for (int i = 0; i < tumDersler.length; i++) {
        int soruSayisi = int.tryParse(derslerinSoruSayilari[i]) ?? 0;
        for (int j = 0; j < soruSayisi; j++) {
          await FirebaseFirestore.instance
              .collection("practiceExams")
              .doc(docID)
              .collection("Sorular")
              .doc(DateTime.now().microsecondsSinceEpoch.toString())
              .set({
            "id": j,
            "soru": "",
            "ders": tumDersler[i],
            "konu": "",
            "dogruCevap": "A",
            "yanitlayanlar": [],
          });
          SetOptions(merge: true);
        }
      }
      await getSorular();
    } catch (error) {
      AppSnackbar("Hata", "Sorular oluşturulamadı.");
    }
  }

  void completeExam() async {
    try {
      await FirebaseFirestore.instance
          .collection("practiceExams")
          .doc(docID)
          .set({
        "taslak": false,
      }, SetOptions(merge: true));
      complated();
      Get.back();
    } catch (error) {
      AppSnackbar("Hata", "Sınav tamamlanamadı.");
    }
  }
}
