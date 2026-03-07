import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:turqappv2/Core/Services/optimized_nsfw_service.dart';
import 'package:turqappv2/Core/Services/webp_upload_service.dart';
import 'package:turqappv2/Models/Education/test_readiness_model.dart';
import 'dart:io';

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
      final snapshot = await FirebaseFirestore.instance
          .collection("Testler")
          .doc(testID)
          .collection("Sorular")
          .orderBy("id", descending: true)
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
        Get.snackbar('Hata', 'NSFW görsel kontrolü başarısız.');
        return;
      }
      if (nsfw.isNSFW) {
        Get.snackbar('Hata', 'Uygunsuz görsel tespit edildi.');
        return;
      }
      final downloadUrl = await WebpUploadService.uploadFileAsWebp(
        storage: FirebaseStorage.instance,
        file: imageFile,
        storagePathWithoutExt:
            'Testler/$testID/${DateTime.now().millisecondsSinceEpoch}',
      );
      print("Download URL: $downloadUrl");

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
        max: testTuru == "Ortaokul" ? 4 : 5,
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
