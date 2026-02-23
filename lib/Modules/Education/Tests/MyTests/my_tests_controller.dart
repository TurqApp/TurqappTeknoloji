import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Models/Education/tests_model.dart';

class MyTestsController extends GetxController {
  final list = <TestsModel>[].obs;
  final isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    getData();
  }

  Future<void> getData() async {
    isLoading.value = true;
    list.clear();
    try {
      final snap =
          await FirebaseFirestore.instance
              .collection("Testler")
              .where(
                "userID",
                isEqualTo: FirebaseAuth.instance.currentUser!.uid,
              )
              .get();

      final tempList = <TestsModel>[];

      for (var doc in snap.docs) {
        final aciklama = doc.get("aciklama") as String;
        final testTuru = doc.get("testTuru") as String;
        final dersler = List<String>.from(doc['dersler'] ?? []);
        final img = doc.get("img") as String;
        final timeStamp = doc.get("timeStamp") as String;
        final userID = doc.get("userID") as String;
        final paylasilabilir = doc.get("paylasilabilir") as bool;
        final taslak = doc.get("taslak") as bool;

        tempList.add(
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

      tempList.sort(
        (a, b) =>
            int.tryParse(
              b.timeStamp,
            )?.compareTo(int.tryParse(a.timeStamp) ?? 0) ??
            0,
      );

      list.assignAll(tempList);
    } catch (e) {
      print("Error fetching tests: $e");
    } finally {
      isLoading.value = false;
    }
  }
}
