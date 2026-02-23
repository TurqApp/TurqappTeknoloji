import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:get/get.dart';
import 'package:path/path.dart';
import 'package:turqappv2/Core/Services/app_image_picker_service.dart';
import 'package:turqappv2/Core/Services/optimized_nsfw_service.dart';
import 'package:turqappv2/Models/Education/test_readiness_model.dart';

class CreateTestQuestionContentController extends GetxController {
  final TestReadinessModel model;
  final String testID;
  final int index;
  final selectedImage = Rx<File?>(null);
  final focunImage = ''.obs;
  final selection = 5.obs;
  final dogruCevap = ''.obs;
  final selections = ['A'].obs;
  final isLoading = false.obs;
  final isInvalid = false.obs;

  CreateTestQuestionContentController({
    required this.model,
    required this.testID,
    required this.index,
  }) {
    if (model.docID.isEmpty) {
      isInvalid.value = true;
    }
  }

  void setCorrectAnswer(String choice) {
    model.dogruCevap = choice;
    fastSetData(choice);
    update();
  }

  void fastSetData(String dogruCvp) {
    FirebaseFirestore.instance
        .collection("Testler")
        .doc(testID)
        .collection("Sorular")
        .doc(model.docID)
        .set({"dogruCevap": dogruCvp}, SetOptions(merge: true));
  }

  Future<void> pickImageFromGallery() async {
    final ctx = Get.context;
    if (ctx == null) return;
    final pickedFile = await AppImagePickerService.pickSingleImage(ctx);
    if (pickedFile != null) {
      selectedImage.value = pickedFile;
      await yukle(pickedFile);
    }
  }

  Future<void> yukle(File imageFile) async {
    isLoading.value = true;
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
      final fileName = basename(imageFile.path);
      final firebaseStorageRef = FirebaseStorage.instance.ref().child(
        'Testler/$testID/$fileName',
      );
      final uploadTask = firebaseStorageRef.putFile(imageFile);
      final taskSnapshot = await uploadTask.whenComplete(() => null);
      final downloadUrl = await taskSnapshot.ref.getDownloadURL();
      print("Download URL: $downloadUrl");

      await FirebaseFirestore.instance
          .collection("Testler")
          .doc(testID)
          .collection("Sorular")
          .doc(model.docID)
          .set({
            "img": downloadUrl,
            "id": model.id,
            "dogruCevap": model.dogruCevap,
            "yanitlayanlar": [],
            "max": model.max,
          }, SetOptions(merge: true));

      model.img = downloadUrl;
      selectedImage.value = null;
    } catch (e) {
      print("Error uploading image: $e");
    } finally {
      isLoading.value = false;
    }
  }
}
