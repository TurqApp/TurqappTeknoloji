import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Models/Education/tests_model.dart';

class LessonBasedTestsController extends GetxController {
  final String testTuru;
  final list = <TestsModel>[].obs;
  final isLoading = false.obs;

  LessonBasedTestsController(this.testTuru);

  @override
  void onInit() {
    super.onInit();
    getData();
  }

  Future<void> getData() async {
    isLoading.value = true;
    try {
      list.clear();
      final snap =
          await FirebaseFirestore.instance
              .collection("Testler")
              .where("testTuru", isEqualTo: testTuru)
              .get();

      for (var doc in snap.docs) {
        final aciklama = doc.get("aciklama") as String;
        final testTuru = doc.get("testTuru") as String;
        final dersler = List<String>.from(doc['dersler'] ?? []);
        final img = doc.get("img") as String;
        final timeStamp = doc.get("timeStamp") as String;
        final userID = doc.get("userID") as String;
        final paylasilabilir = doc.get("paylasilabilir") as bool;
        final taslak = doc.get("taslak") as bool;

        list.add(
          TestsModel(
            userID: userID,
            timeStamp: timeStamp,
            aciklama: aciklama,
            dersler: dersler,
            img: img,
            docID: doc.id,
            paylasilabilir: paylasilabilir,
            testTuru: testTuru,
            taslak: taslak,
          ),
        );
      }
    } finally {
      isLoading.value = false;
    }
  }
}
