import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/follow_service.dart';
import 'package:intl/intl.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Models/Education/individual_scholarships_model.dart';
import 'package:turqappv2/Modules/Education/Scholarships/scholarships_controller.dart';

class ScholarshipDetailController extends GetxController {
  var showAllUniversities = false.obs;
  var hiddenUniversityCount = 0.obs;
  var isLoading = false.obs;
  var isFollowing = false.obs;
  var currentPageIndex = 0.obs;
  final RxBool applyReady = false.obs;
  final RxBool allreadyApplied = false.obs;
  final Rxn<IndividualScholarshipsModel> resolvedModel =
      Rxn<IndividualScholarshipsModel>();
  final RxBool detailLoading = false.obs;
  String? _followInitForId;

  @override
  void onInit() {
    super.onInit();
    checkUserApplicationReadiness();
    final scholarshipData = Get.arguments as Map<String, dynamic>?;
    if (scholarshipData != null) {
      checkIfUserAlreadyApplied(scholarshipData);
      _incrementViewCount(scholarshipData);
    }
  }

  void _incrementViewCount(Map<String, dynamic> scholarshipData) {
    final docId =
        scholarshipData['docId'] ?? scholarshipData['scholarshipId'] ?? '';
    if (docId.isEmpty) return;
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;
    final model = scholarshipData['model'];
    if (model is IndividualScholarshipsModel &&
        model.userID == currentUser.uid) {
      return;
    }
    FirebaseFirestore.instance
        .collection('scholarships')
        .doc(docId)
        .update({
      'goruntuleme': FieldValue.arrayUnion([currentUser.uid]),
    }).catchError((_) {});
  }

  Future<void> checkUserApplicationReadiness() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      applyReady.value = false;
      AppSnackbar("Hata", "Lütfen oturum açın.");
      return;
    }

    try {
      isLoading.value = true;
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();

      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>;

        bool isPersonalInfoComplete = data['ulke']?.isNotEmpty == true &&
            data['nufusSehir']?.isNotEmpty == true &&
            data['nufusIlce']?.isNotEmpty == true &&
            data['dogumTarihi']?.isNotEmpty == true &&
            data['medeniHal']?.isNotEmpty == true &&
            data['cinsiyet'] != "Seçim Yap" &&
            data['engelliRaporu']?.isNotEmpty == true &&
            data['calismaDurumu']?.isNotEmpty == true;

        bool isEducationInfoComplete =
            data['educationLevel']?.isNotEmpty == true &&
                data['ulke']?.isNotEmpty == true &&
                (data['educationLevel'] == 'Ortaokul'
                    ? (data['ortaOkul']?.isNotEmpty == true &&
                        data['sinif']?.isNotEmpty == true &&
                        data['il']?.isNotEmpty == true &&
                        data['ilce']?.isNotEmpty == true)
                    : data['educationLevel'] == 'Lise'
                        ? (data['lise']?.isNotEmpty == true &&
                            data['sinif']?.isNotEmpty == true &&
                            data['il']?.isNotEmpty == true &&
                            data['ilce']?.isNotEmpty == true)
                        : (data['universite']?.isNotEmpty == true &&
                            data['fakulte']?.isNotEmpty == true &&
                            data['bolum']?.isNotEmpty == true &&
                            data['il']?.isNotEmpty == true));

        bool isFamilyInfoComplete = data['fatherLiving'] != "Seçiniz" &&
            data['motherLiving'] != "Seçiniz" &&
            data['totalLiving'] != null &&
            data['totalLiving'] is int &&
            data['totalLiving'] > 0 &&
            data['evMulkiyeti'] != "Seçim Yap" &&
            data['ikametSehir']?.isNotEmpty == true &&
            data['ikametIlce']?.isNotEmpty == true;

        if (data['fatherLiving'] == "Evet") {
          isFamilyInfoComplete = isFamilyInfoComplete &&
              data['fatherName']?.isNotEmpty == true &&
              data['fatherSurname']?.isNotEmpty == true &&
              data['fatherJob'] != "Meslek Seç" &&
              data['fatherSalary']?.isNotEmpty == true &&
              data['fatherPhone']?.isNotEmpty == true;
        }

        if (data['motherLiving'] == "Evet") {
          isFamilyInfoComplete = isFamilyInfoComplete &&
              data['motherName']?.isNotEmpty == true &&
              data['motherSurname']?.isNotEmpty == true &&
              data['motherJob'] != "Meslek Seç" &&
              data['motherSalary']?.isNotEmpty == true &&
              data['motherPhone']?.isNotEmpty == true;
        }

        applyReady.value = isPersonalInfoComplete &&
            isEducationInfoComplete &&
            isFamilyInfoComplete;
      } else {
        applyReady.value = false;
        AppSnackbar("Hata",
            "Kullanıcı verisi bulunamadı. Lütfen bilgilerinizi doldurun.");
      }
    } catch (e) {
      print('Kullanıcı hazırlık kontrolü hatası: $e');
      AppSnackbar("Hata", "Bilgiler kontrol edilirken hata oluştu.");
      applyReady.value = false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> checkIfUserAlreadyApplied(
      Map<String, dynamic> scholarshipData) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      allreadyApplied.value = false;
      return;
    }

    try {
      print('Başvuru durumu kontrol ediliyor: ${currentUser.uid}');
      final String scholarshipId =
          scholarshipData['docId'] ?? scholarshipData['scholarshipId'] ?? '';
      final String type = 'bireysel';

      print('Burs ID: $scholarshipId, Tür: $type');

      if (scholarshipId.isNotEmpty) {
        final collection = 'scholarships';
        final field = 'basvurular';

        print('Koleksiyon kontrol ediliyor: $collection');

        final doc = await FirebaseFirestore.instance
            .collection(collection)
            .doc(scholarshipId)
            .collection('Basvurular')
            .doc(currentUser.uid)
            .get();

        allreadyApplied.value = doc.exists;
        if (!allreadyApplied.value) {
          final parentDoc = await FirebaseFirestore.instance
              .collection(collection)
              .doc(scholarshipId)
              .get();
          final applicants = List<String>.from(parentDoc.data()?[field] ?? []);
          allreadyApplied.value = applicants.contains(currentUser.uid);
          print('Başvurular dizisi kontrolü: ${allreadyApplied.value}');
        }

        print('Son başvuru durumu: ${allreadyApplied.value}');
      } else {
        print('Geçersiz burs ID');
        allreadyApplied.value = false;
      }
    } catch (e) {
      print('Başvuru durumu kontrol edilirken hata: $e');
      AppSnackbar("Hata", "Başvuru durumu kontrol edilirken hata oluştu.");
      allreadyApplied.value = false;
    }
  }

  Future<void> applyForScholarship(String scholarshipId, String type) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      AppSnackbar("Hata", "Lütfen oturum açın.");
      return;
    }

    try {
      isLoading.value = true;
      await checkUserApplicationReadiness();

      if (!applyReady.value) {
        return;
      }

      final collection = 'scholarships';
      final field = 'basvurular';

      await FirebaseFirestore.instance
          .collection(collection)
          .doc(scholarshipId)
          .collection('Basvurular')
          .doc(currentUser.uid)
          .set({
        'timeStamp': DateTime.now().millisecondsSinceEpoch,
      });

      await FirebaseFirestore.instance
          .collection(collection)
          .doc(scholarshipId)
          .update({
        field: FieldValue.arrayUnion([currentUser.uid]),
      });

      allreadyApplied.value = true;
      AppSnackbar("Başarılı", "Burs başvurunuz alınmıştır.");
    } catch (e) {
      print('Başvuru kaydedilirken hata: $e');
      AppSnackbar("Hata", "Başvuru kaydedilemedi.");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> initializeFollowState(String followedId) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      isFollowing.value = false;
      return;
    }
    if (followedId.isEmpty) return;
    if (_followInitForId == followedId) return;
    _followInitForId = followedId;
    final followerId = currentUser.uid;
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(followedId)
        .collection('Takipciler')
        .doc(followerId)
        .get();
    isFollowing.value = doc.exists;
  }

  void updatePageIndex(int pageIndex) {
    currentPageIndex.value = pageIndex;
    print('Güncellenen sayfa indeksi: $pageIndex');
  }

  void toggleUniversityList() {
    showAllUniversities.value = !showAllUniversities.value;
  }

  String formatTimestamp(int? timestamp) {
    if (timestamp == null) return 'Belirtilmemiş';
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return DateFormat('dd.MM.yyyy').format(date);
  }

  final RxBool isFollowLoading = false.obs;

  Future<void> toggleFollowStatus(String userID) async {
    if (isFollowLoading.value) return;
    final wasFollowing = isFollowing.value;
    isFollowing.value = !wasFollowing; // optimistic
    isFollowLoading.value = true;
    try {
      final outcome = await FollowService.toggleFollow(userID);
      isFollowing.value = outcome.nowFollowing; // reconcile
      if (outcome.limitReached) {
        AppSnackbar('Takip Limiti', 'Günlük daha fazla kişi takip edilemiyor.');
      }
    } catch (e) {
      isFollowing.value = wasFollowing; // revert
      print("Takip işlemi hatası: $e");
      AppSnackbar("Hata", "Takip işlemi başarısız.");
    } finally {
      isFollowLoading.value = false;
    }
  }

  Future<void> deleteScholarship(String scholarshipId, String type) async {
    if (scholarshipId.isEmpty) {
      AppSnackbar("Hata", "Geçersiz burs!.");
      return;
    }

    try {
      isLoading.value = true;
      await FirebaseFirestore.instance
          .collection('scholarships')
          .doc(scholarshipId)
          .delete();
      Get.back();
      final scholarshipsController = Get.find<ScholarshipsController>();
      await scholarshipsController.fetchScholarships();
      AppSnackbar("Başarılı", "Burs başarıyla silindi.");
    } catch (e) {
      AppSnackbar("Hata", "Burs silinirken bir hata oluştu: $e");
      print("deleteScholarship hatası.");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> cancelApplication(String scholarshipId, String type) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      AppSnackbar("Hata", "Lütfen oturum açın.");
      return;
    }

    try {
      isLoading.value = true;
      final collection = 'scholarships';
      final field = 'basvurular';

      await FirebaseFirestore.instance
          .collection(collection)
          .doc(scholarshipId)
          .collection('Basvurular')
          .doc(currentUser.uid)
          .delete();

      await FirebaseFirestore.instance
          .collection(collection)
          .doc(scholarshipId)
          .update({
        field: FieldValue.arrayRemove([currentUser.uid]),
      });

      allreadyApplied.value = false;
      await checkUserApplicationReadiness();
      AppSnackbar("Başarılı", "Burs başvurunuz iptal edildi.");
    } catch (e) {
      print('Başvuru iptal edilirken hata: $e');
      AppSnackbar("Hata", "Başvuru iptal edilemedi.");
    } finally {
      isLoading.value = false;
    }
  }
}
