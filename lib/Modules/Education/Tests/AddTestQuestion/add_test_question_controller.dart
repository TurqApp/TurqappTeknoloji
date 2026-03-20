import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Core/Repositories/test_repository.dart';
import 'package:turqappv2/Core/Services/optimized_nsfw_service.dart';
import 'package:turqappv2/Core/Services/webp_upload_service.dart';
import 'package:turqappv2/Models/Education/test_readiness_model.dart';
import 'dart:io';

const _addQuestionMiddleSchoolType = 'Ortaokul';

class AddTestQuestionController extends GetxController {
  final List<TestReadinessModel> initialSoruList;
  final String testID;
  final String testTuru;
  final Function onUpdate;
  final soruList = <TestReadinessModel>[].obs;
  final selectedImage = Rx<File?>(null);
  final dogruCevap = ''.obs;
  final selection = 5.obs;
  final selections = ['A'].obs;
  final isLoading = true.obs;
  final ImagePicker picker = ImagePicker();
  final TestRepository _testRepository = TestRepository.ensure();

  AddTestQuestionController({
    required this.initialSoruList,
    required this.testID,
    required this.testTuru,
    required this.onUpdate,
  });

  @override
  void onInit() {
    super.onInit();
    soruList.assignAll(initialSoruList);
    getSorular();
  }

  Future<void> getSorular() async {
    isLoading.value = true;
    try {
      final questions = await _testRepository.fetchQuestions(
        testID,
        preferCache: true,
      );
      soruList.assignAll(questions.reversed);
    } catch (e) {
      print("Error fetching questions: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> yukle(File imageFile, int index) async {
    try {
      final nsfw = await OptimizedNSFWService.checkImage(imageFile);
      if (nsfw.errorMessage != null) {
        AppSnackbar('common.error'.tr, 'tests.nsfw_check_failed'.tr);
        return;
      }
      if (nsfw.isNSFW) {
        AppSnackbar('common.error'.tr, 'tests.nsfw_detected'.tr);
        return;
      }
      final downloadUrl = await WebpUploadService.uploadFileAsWebp(
        storage: FirebaseStorage.instance,
        file: imageFile,
        storagePathWithoutExt:
            'Testler/$testID/${DateTime.now().millisecondsSinceEpoch}',
      );

      await FirebaseFirestore.instance
          .collection("Testler")
          .doc(testID)
          .collection("Sorular")
          .doc(soruList[index].docID)
          .set({
        "img": downloadUrl,
        "id": soruList[index].id,
        "dogruCevap": soruList[index].dogruCevap,
        "yanitlayanlar": [],
        "max": 5,
      }, SetOptions(merge: true));

      soruList[index] = TestReadinessModel(
        id: soruList[index].id,
        img: downloadUrl,
        max: soruList[index].max,
        dogruCevap: soruList[index].dogruCevap,
        docID: soruList[index].docID,
      );
    } catch (e) {
      print("Error uploading image: $e");
    }
  }

  void addNewQuestion() {
    final docID = DateTime.now().millisecondsSinceEpoch.toInt();
    soruList.add(
      TestReadinessModel(
        id: docID,
        img: "",
        max: testTuru == _addQuestionMiddleSchoolType ? 4 : 5,
        dogruCevap: "",
        docID: docID.toString(),
      ),
    );
  }

  void deleteQuestion(int index) {
    FirebaseFirestore.instance
        .collection("Testler")
        .doc(testID)
        .collection("Sorular")
        .doc(soruList[index].docID)
        .delete();
    soruList.removeAt(index);
  }

  void publishTest() {
    FirebaseFirestore.instance.collection("Testler").doc(testID).set({
      "taslak": false,
    }, SetOptions(merge: true));
    Get.back();
  }
}
