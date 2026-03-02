import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Modules/Education/PracticeExams/ders_ve_sonuclar_model.dart';
import 'package:turqappv2/Modules/Education/PracticeExams/sinav_model.dart';
import 'package:turqappv2/Modules/Education/PracticeExams/soru_model.dart';

class SinavSonuclariPreviewController extends GetxController {
  var yanitlar = <String>[].obs;
  var timeStamp = (0 as num).obs;
  var soruList = <SoruModel>[].obs;
  var expandedCategories = <String, bool>{}.obs;
  var dersVeSonuclar = <DersVeSonuclarDB>[].obs;
  var yanitID = "".obs;
  var isLoading = false.obs;
  var isInitialized = false.obs;

  final SinavModel model;

  SinavSonuclariPreviewController({required this.model});

  @override
  void onInit() {
    super.onInit();
    getYanitlar();
  }

  Future<void> getYanitlar() async {
    isLoading.value = true;
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection("practiceExams")
          .doc(model.docID)
          .collection("Yanitlar")
          .get();

      if (snapshot.docs.isNotEmpty) {
        final yanitlarData = List<String>.from(snapshot.docs.last['yanitlar']);
        num timeStampData = snapshot.docs.last["timeStamp"];
        String yanitIDData = snapshot.docs.last.id;

        yanitlar.assignAll(yanitlarData);
        timeStamp.value = timeStampData;
        yanitID.value = yanitIDData;

        await getSorular();
      } else {
        isLoading.value = false;
        isInitialized.value = true;
      }
    } catch (error) {
      AppSnackbar("Hata", "Yanıtlar yüklenemedi.");
      isLoading.value = false;
      isInitialized.value = true;
    }
  }

  Future<void> getSorular() async {
    try {
      QuerySnapshot snap = await FirebaseFirestore.instance
          .collection("practiceExams")
          .doc(model.docID)
          .collection("Sorular")
          .get();

      if (snap.docs.isNotEmpty) {
        List<SoruModel> tempList = [];
        for (var doc in snap.docs) {
          String ders = doc.get("ders");
          String dogruCevap = doc.get("dogruCevap");
          num id = doc.get("id");
          String konu = doc.get("konu");
          String soru = doc.get("soru");

          tempList.add(
            SoruModel(
              id: id.toInt(),
              soru: soru,
              ders: ders,
              konu: konu,
              dogruCevap: dogruCevap,
              docID: doc.id,
            ),
          );

          if (!expandedCategories.containsKey(ders)) {
            expandedCategories[ders] = false;
          }
        }

        soruList.assignAll(tempList);
        await getDersVeSonuclar(yanitID.value);
      }
    } catch (error) {
      AppSnackbar("Hata", "Sorular yüklenemedi.");
    } finally {
      isLoading.value = false;
      isInitialized.value = true;
    }
  }

  Future<void> getDersVeSonuclar(String docID) async {
    try {
      for (var item in model.dersler) {
        DocumentSnapshot doc = await FirebaseFirestore.instance
            .collection("practiceExams")
            .doc(model.docID)
            .collection("Yanitlar")
            .doc(docID)
            .collection(item)
            .doc(docID)
            .get();

        if (doc.exists) {
          dersVeSonuclar.add(
            DersVeSonuclarDB(
              ders: doc.get("ders"),
              dogru: doc.get("dogru"),
              yanlis: doc.get("yanlis"),
              bos: doc.get("bos"),
              net: doc.get("net"),
            ),
          );
        }
      }
    } catch (error) {
      AppSnackbar("Hata", "Ders sonuçları yüklenemedi.");
    }
  }

  void toggleCategory(String ders) {
    expandedCategories[ders] = !expandedCategories[ders]!;
  }
}
