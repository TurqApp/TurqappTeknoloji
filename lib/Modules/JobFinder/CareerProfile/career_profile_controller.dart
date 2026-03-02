import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Models/CVModels/school_model.dart';

class CareerProfileController extends GetxController {
  var cvVar = false.obs;
  var isFindingJob = false.obs;
  var isLoading = false.obs;

  // CV summary fields
  var fullName = ''.obs;
  var about = ''.obs;
  var meslek = ''.obs;
  RxList<CVLanguegeModel> languages = <CVLanguegeModel>[].obs;
  RxList<CVExperinceModel> experiences = <CVExperinceModel>[].obs;
  RxList<CvSchoolModel> schools = <CvSchoolModel>[].obs;
  RxList<String> skills = <String>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadCvData();
  }

  Future<void> loadCvData() async {
    isLoading.value = true;
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;
      final doc = await FirebaseFirestore.instance
          .collection('CV')
          .doc(uid)
          .get();

      if (doc.exists && doc.data() != null) {
        cvVar.value = true;
        final data = doc.data()!;
        fullName.value =
            '${data['firstName'] ?? ''} ${data['lastName'] ?? ''}'.trim();
        about.value = data['about'] ?? '';
        isFindingJob.value = data['findingJob'] ?? false;

        schools.value = (data['okullar'] as List<dynamic>? ?? [])
            .map((e) => CvSchoolModel.fromMap(e as Map<String, dynamic>))
            .toList();

        languages.value = (data['diller'] as List<dynamic>? ?? [])
            .map((e) => CVLanguegeModel.fromMap(e as Map<String, dynamic>))
            .toList();

        experiences.value = (data['deneyim'] as List<dynamic>? ?? [])
            .map((e) => CVExperinceModel.fromMap(e as Map<String, dynamic>))
            .toList();

        skills.value = (data['skills'] as List<dynamic>? ?? [])
            .map((e) => e.toString())
            .toList();
      } else {
        cvVar.value = false;
      }
    } catch (e) {
      print("CV yükleme hatası: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> toggleFindingJob() async {
    try {
      isFindingJob.value = !isFindingJob.value;
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;
      await FirebaseFirestore.instance
          .collection('CV')
          .doc(uid)
          .update({'findingJob': isFindingJob.value});
    } catch (e) {
      print("findingJob toggle hatası: $e");
      isFindingJob.value = !isFindingJob.value;
    }
  }
}
