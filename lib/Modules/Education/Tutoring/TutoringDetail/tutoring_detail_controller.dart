import 'dart:async';
import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Models/Education/tutoring_model.dart';

class TutoringDetailController extends GetxController {
  var isLoading = true.obs;
  var tutoring = TutoringModel(
    docID: '',
    aciklama: '',
    baslik: '',
    brans: '',
    cinsiyet: '',
    dersYeri: [],
    end: 0,
    favorites: [],
    fiyat: 0,
    ilce: '',
    onayVerildi: false,
    sehir: '',
    telefon: false,
    timeStamp: 0,
    userID: '',
    whatsapp: false,
    imgs: null,
  ).obs;
  var users = <String, Map<String, dynamic>>{}.obs;
  var carouselCurrentIndex = 0.obs;

  StreamSubscription<DocumentSnapshot>? _tutoringSubscription;

  @override
  void onInit() {
    super.onInit();
    final tutoringData = Get.arguments as TutoringModel?;
    if (tutoringData != null) {
      listenToTutoringDetail(tutoringData.docID);
      fetchUserData(tutoringData.userID);
    }
  }

  @override
  void onClose() {
    _tutoringSubscription?.cancel();
    super.onClose();
  }

  Future<void> fetchUserData(String userID) async {
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userID)
          .get();
      if (userDoc.exists) {
        users[userID] = userDoc.data() as Map<String, dynamic>;
      }
    } catch (e) {
      log("Error fetching user data: $e");
    }
  }

  void listenToTutoringDetail(String docID) {
    isLoading.value = true;
    _tutoringSubscription = FirebaseFirestore.instance
        .collection('OzelDersVerenler')
        .doc(docID)
        .snapshots()
        .listen((DocumentSnapshot document) {
      try {
        if (document.exists) {
          tutoring.value = TutoringModel.fromJson(
              document.data() as Map<String, dynamic>, docID);
        } else {
          log("Tutoring document does not exist");
        }
      } catch (e) {
        log("Error processing tutoring stream: $e");
      } finally {
        isLoading.value = false;
      }
    }, onError: (e) {
      log("Error listening to tutoring detail: $e");
      isLoading.value = false;
    });
  }
}
