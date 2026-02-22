import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nsfw_detector_flutter/nsfw_detector_flutter.dart';
import 'package:path/path.dart';
import 'package:turqappv2/Core/External.dart';
import 'package:turqappv2/Models/Education/TestReadinessModel.dart';
import 'package:turqappv2/Models/Education/TestsModel.dart';
import 'package:turqappv2/Modules/Education/Tests/AddTestQuestion/AddTestQuestion.dart';

class CreateTestController extends GetxController {
  final TestsModel? model;
  final aciklama = TextEditingController();
  final selectedDers = <String>[].obs;
  final showBransh = false.obs;
  final showDiller = false.obs;
  final selectedDil = ''.obs;
  final testTuru = 'Lise'.obs;
  final paylasilabilir = true.obs;
  final check = false.obs;
  final imageFile = Rx<File?>(null);
  final foundImage = ''.obs;
  final picker = ImagePicker();
  final appStore = ''.obs;
  final googlePlay = ''.obs;
  final testID = DateTime.now().millisecondsSinceEpoch.obs;
  final showSilButon = false.obs;
  final kopyalandi = false.obs;
  final sorularList =
      <TestReadinessModel>[
        TestReadinessModel(id: 0, img: "", max: 5, dogruCevap: "", docID: "0"),
      ].obs;
  final isLoading = true.obs;

  CreateTestController(this.model);

  @override
  void onInit() {
    super.onInit();
    initializeData();
  }

  void initializeData() async {
    isLoading.value = true;
    if (model != null) {
      testID.value = int.parse(model!.docID);
      selectedDers.assignAll(model!.dersler);
      aciklama.text = model!.aciklama;
      paylasilabilir.value = model!.paylasilabilir;
      foundImage.value = model!.img;
      testTuru.value = model!.testTuru;
      showSilButon.value = !model!.taslak;
      await getSorular();
    }
    await getUygulamaLinks();
    isLoading.value = false;
  }

  Future<void> getUygulamaLinks() async {
    try {
      final doc =
          await FirebaseFirestore.instance
              .collection("Yönetim")
              .doc("Genel")
              .get();
      appStore.value = doc.get("appStore") as String;
      googlePlay.value = doc.get("googlePlay") as String;
    } catch (e) {
      print("Error fetching app links: $e");
    }
  }

  Future<void> getSorular() async {
    if (model == null) return;
    sorularList.clear();
    try {
      final snapshot =
          await FirebaseFirestore.instance
              .collection("Testler")
              .doc(model!.docID)
              .collection("Sorular")
              .get();
      if (snapshot.docs.isEmpty) {
        sorularList.add(
          TestReadinessModel(
            id: 0,
            img: "",
            max: 5,
            dogruCevap: "",
            docID: "0",
          ),
        );
      } else {
        for (var doc in snapshot.docs) {
          final img = doc.get("img") as String;
          final id = doc.get("id") as num;
          final dogruCevap = doc.get("dogruCevap") as String;
          final max = doc.get("max") as num;
          sorularList.add(
            TestReadinessModel(
              id: id.toInt(),
              img: img,
              max: max.toInt(),
              dogruCevap: dogruCevap,
              docID: doc.id,
            ),
          );
        }
      }
    } catch (e) {
      print("Error fetching questions: $e");
    }
  }

  Future<void> pickImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      imageFile.value = File(pickedFile.path);
      await analyzeImage();
    }
  }

  Future<void> analyzeImage() async {
    if (imageFile.value == null) return;
    try {
      final detector = await NsfwDetector.load();
      final result = await detector.detectNSFWFromFile(imageFile.value!);
      print("NSFW detected: ${result?.isNsfw}");
      print("NSFW score: ${result?.score}");
      if (result!.isNsfw) {
        imageFile.value = null;
      }
    } catch (e) {
      print("Error analyzing image: $e");
    }
  }

  Future<void> yukle(File imageFile) async {
    try {
      final fileName = basename(imageFile.path);
      final firebaseStorageRef = FirebaseStorage.instance.ref().child(
        'Testler/${testID.value}/$fileName',
      );
      final uploadTask = firebaseStorageRef.putFile(imageFile);
      final taskSnapshot = await uploadTask.whenComplete(() => null);
      final downloadUrl = await taskSnapshot.ref.getDownloadURL();
      await FirebaseFirestore.instance
          .collection("Testler")
          .doc(testID.value.toString())
          .set({"img": downloadUrl}, SetOptions(merge: true));
      SetOptions(merge: true);
    } catch (e) {
      print("Error uploading image: $e");
    }
  }

  void deleteTest() {
    FirebaseFirestore.instance
        .collection("Testler")
        .doc(testID.value.toString())
        .delete();
    Get.back();
  }

  void saveTest(BuildContext context) async {
    await FirebaseFirestore.instance
        .collection("Testler")
        .doc(testID.value.toString())
        .update({
          "aciklama": aciklama.text,
          "dersler": selectedDers.toList(),
          "paylasilabilir": paylasilabilir.value,
          "testTuru": testTuru.value,
        });
    if (imageFile.value != null) {
      await yukle(imageFile.value!);
    }
    Get.back();
  }

  void prepareTest(BuildContext context) async {
    await FirebaseFirestore.instance
        .collection("Testler")
        .doc(testID.value.toString())
        .set({
          "aciklama": aciklama.text,
          "dersler": selectedDers.toList(),
          "favoriler": [],
          "paylasilabilir": paylasilabilir.value,
          "timeStamp": DateTime.now().millisecondsSinceEpoch.toString(),
          "userID": FirebaseAuth.instance.currentUser!.uid,
          "taslak": true,
          "testTuru": testTuru.value,
        }, SetOptions(merge: true));
    if (imageFile.value != null) {
      await yukle(imageFile.value!);
    }
    Get.to(
      () => AddTestQuestion(
        soruList: sorularList,
        testID: testID.value.toString(),
        update: () => Get.back(),
        testTuru: testTuru.value,
      ),
    );
  }

  List<String> getFilteredDersler() {
    if (testTuru.value == "Ortaokul") {
      return [
        "Türkçe",
        "Matematik",
        "Fen Bilimleri",
        "İnkılap Tarihi",
        "Din Kültürü",
        "Yabancı Dil",
      ];
    }
    return tumDersler;
  }

  IconData getIconForDers(String ders) {
    switch (ders) {
      case "Türkçe":
        return Icons.text_fields;
      case "Matematik":
        return Icons.calculate;
      case "Fizik":
        return Icons.science;
      case "İnkılap Tarihi":
        return Icons.history;
      case "Din Kültürü":
        return Icons.book;
      case "Yabancı Dil":
        return Icons.language;
      default:
        return Icons.help_outline;
    }
  }
}
