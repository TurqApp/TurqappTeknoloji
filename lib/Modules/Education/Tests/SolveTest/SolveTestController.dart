import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Models/Education/TestReadinessModel.dart';

class SolveTestController extends GetxController {
  final String testID;
  final Function showSucces;
  final soruList = <TestReadinessModel>[].obs;
  final selections = ['A'].obs;
  final cevap = ''.obs;
  final cevaplar = <String>[].obs;
  final elapsedTime = Duration.zero.obs;
  final fullname = ''.obs;
  final isLoading = true.obs;
  late DateTime _startTime;
  late Timer _timer;

  SolveTestController({required this.testID, required this.showSucces});

  @override
  void onInit() {
    super.onInit();
    _startTime = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      elapsedTime.value = DateTime.now().difference(_startTime);
    });
    getSorular();
    getUserFullName();
  }

  @override
  void onClose() {
    _timer.cancel();
    super.onClose();
  }

  String formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$hours:$minutes:$seconds";
  }

  Future<void> getSorular() async {
    isLoading.value = true;
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection("Testler")
          .doc(testID)
          .collection("Sorular")
          .orderBy("id", descending: false)
          .get();

      soruList.clear();
      for (var doc in snapshot.docs) {
        final img = doc.get("img") as String;
        final id = doc.get("id") as num;
        final dogruCevap = doc.get("dogruCevap") as String;
        final max = doc.get("max") as num;

        soruList.add(
          TestReadinessModel(
            id: id.toInt(),
            img: img,
            max: max.toInt(),
            dogruCevap: dogruCevap,
            docID: doc.id,
          ),
        );
      }
      cevaplar.assignAll(List.generate(soruList.length, (index) => ""));
    } catch (e) {
      print("Error fetching questions: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> getUserFullName() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection("users")
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .get();
      final firstName = doc.get("firstName") as String;
      final lastName = doc.get("lastName") as String;
      fullname.value = "$firstName $lastName";
    } catch (e) {
      print("Error fetching user data: $e");
      fullname.value = "";
    }
  }

  void updateAnswer(int index, String choice) {
    cevaplar[index] = choice;
  }

  void testiBitir() {
    FirebaseFirestore.instance
        .collection("Testler")
        .doc(testID)
        .collection("Yanitlar")
        .doc(DateTime.now().millisecondsSinceEpoch.toString())
        .set({
      "cevaplar": cevaplar.toList(),
      "timeStamp": DateTime.now().millisecondsSinceEpoch.toInt(),
      "userID": FirebaseAuth.instance.currentUser!.uid,
    }).then((value) {
      print("Yanitlar başarıyla eklendi: $testID");
    }).catchError((error) {
      print("Yanitlar eklenirken hata: $error");
    });
    Get.back();
    showSucces();
  }
}
