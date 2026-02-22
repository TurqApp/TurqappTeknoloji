import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Models/Education/TestsModel.dart';

class TestPastResultContentController extends GetxController {
  final TestsModel model;
  final count = 0.obs;
  final isLoading = true.obs;
  final timeStamp = 0.obs;

  TestPastResultContentController(this.model);

  @override
  void onInit() {
    super.onInit();
    getData();
  }

  Future<void> getData() async {
    isLoading.value = true;
    count.value = 0;
    timeStamp.value = 0;
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection("Testler")
          .doc(model.docID)
          .collection("Yanitlar")
          .where(
            "userID",
            isEqualTo: FirebaseAuth.instance.currentUser!.uid,
          )
          .orderBy("timeStamp", descending: true)
          .limit(1)
          .get();

      print("Snapshot docs: ${snapshot.docs.length}");
      if (snapshot.docs.isNotEmpty) {
        count.value = snapshot.docs.length;
        timeStamp.value = snapshot.docs.first.get("timeStamp") as int;
        print("Fetched timeStamp: ${timeStamp.value}");
      } else {
        print("Hiç veri bulunamadı: ${model.docID}");
      }
    } catch (e) {
      print("Error fetching answer count: $e");
    } finally {
      isLoading.value = false;
    }
  }
}
