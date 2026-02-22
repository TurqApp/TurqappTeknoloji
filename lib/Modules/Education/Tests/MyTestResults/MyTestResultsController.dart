import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Models/Education/TestsModel.dart';

class MyTestResultsController extends GetxController {
  final list = <TestsModel>[].obs;
  final isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    findAndGetTestler();
  }

  Future<void> findAndGetTestler() async {
    isLoading.value = true;
    list.clear();
    try {
      final currentUserID = FirebaseAuth.instance.currentUser!.uid;
      final testlerQuerySnapshot =
          await FirebaseFirestore.instance.collection("Testler").get();

      for (var doc in testlerQuerySnapshot.docs) {
        final yanitlarQuerySnapshot =
            await doc.reference
                .collection("Yanitlar")
                .where("userID", isEqualTo: currentUserID)
                .get();

        if (yanitlarQuerySnapshot.docs.isNotEmpty) {
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
      }
    } catch (e) {
      print("Error fetching test results: $e");
    } finally {
      isLoading.value = false;
    }
  }
}
