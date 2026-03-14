import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Repositories/config_repository.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nsfw_detector_flutter/nsfw_detector_flutter.dart';
import 'package:turqappv2/Core/external.dart';
import 'package:turqappv2/Core/Repositories/test_repository.dart';
import 'package:turqappv2/Core/Services/app_image_picker_service.dart';
import 'package:turqappv2/Core/Services/webp_upload_service.dart';
import 'package:turqappv2/Models/Education/test_readiness_model.dart';
import 'package:turqappv2/Models/Education/tests_model.dart';
import 'package:turqappv2/Modules/Education/Tests/AddTestQuestion/add_test_question.dart';

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
  final sorularList = <TestReadinessModel>[
    TestReadinessModel(id: 0, img: "", max: 5, dogruCevap: "", docID: "0"),
  ].obs;
  final isLoading = true.obs;
  final TestRepository _testRepository = TestRepository.ensure();

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
      final doc = await ConfigRepository.ensure().getLegacyConfigDoc(
        collection: 'Yönetim',
        docId: 'Genel',
        preferCache: true,
      );
      appStore.value = (doc?["appStore"] ?? "").toString();
      googlePlay.value = (doc?["googlePlay"] ?? "").toString();
    } catch (e) {
      print("Error fetching app links: $e");
    }
  }

  Future<void> getSorular() async {
    if (model == null) return;
    sorularList.clear();
    try {
      final questions = await _testRepository.fetchQuestions(
        model!.docID,
        preferCache: true,
      );
      if (questions.isEmpty) {
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
        for (final question in questions) {
          sorularList.add(
            TestReadinessModel(
              id: question.id.toInt(),
              img: question.img,
              max: question.max.toInt(),
              dogruCevap: question.dogruCevap,
              docID: question.docID,
            ),
          );
        }
      }
    } catch (e) {
      print("Error fetching questions: $e");
    }
  }

  Future<void> pickImage() async {
    final ctx = Get.context;
    if (ctx == null) return;
    final pickedFile = await AppImagePickerService.pickSingleImage(ctx);
    if (pickedFile != null) {
      imageFile.value = pickedFile;
      await analyzeImage();
    }
  }

  Future<void> analyzeImage() async {
    if (imageFile.value == null) return;
    try {
      final detector = await NsfwDetector.load(threshold: 0.3);
      final result = await detector.detectNSFWFromFile(imageFile.value!);
      print("NSFW detected: ${result?.isNsfw}");
      print("NSFW score: ${result?.score}");
      if (result == null || result.isNsfw) {
        imageFile.value = null;
      }
    } catch (e) {
      print("Error analyzing image: $e");
      imageFile.value = null;
    }
  }

  Future<void> yukle(File imageFile) async {
    try {
      final downloadUrl = await WebpUploadService.uploadFileAsWebp(
        storage: FirebaseStorage.instance,
        file: imageFile,
        storagePathWithoutExt:
            'Testler/${testID.value}/${DateTime.now().millisecondsSinceEpoch}',
      );
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
