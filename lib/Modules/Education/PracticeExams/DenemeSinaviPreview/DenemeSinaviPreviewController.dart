import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/AppSnackbar.dart';
import 'package:turqappv2/Modules/Education/PracticeExams/SinavModel.dart';

class DenemeSinaviPreviewController extends GetxController {
  var nickname = "".obs;
  var pfImage = "".obs;
  var dahaOnceBasvurdu = false.obs;
  var basvuranSayisi = 0.obs;
  var currentTime = DateTime.now().millisecondsSinceEpoch.obs;
  var showSucces = false.obs;
  var sinavaGirebilir = false.obs;
  var examTime = 0.obs;
  var isLoading = true.obs;
  var isInitialized = false.obs;
  final int fifteenMinutes = 15 * 60 * 1000;

  final SinavModel model;

  DenemeSinaviPreviewController({required this.model});

  @override
  void onInit() {
    super.onInit();
    examTime.value = model.timeStamp.toInt();
    fetchUserData();
    basvuruKontrol();
    getGecersizlikDurumu();
  }

  Future<void> fetchUserData() async {
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection("users")
          .doc(model.userID)
          .get();
      nickname.value = doc.get("nickname");
      pfImage.value = doc.get("pfImage");
    } catch (error) {
      AppSnackbar("Hata", "Kullanıcı bilgileri yüklenemedi.");
    } finally {
      isLoading.value = false;
      isInitialized.value = true;
    }
  }

  void getGecersizlikDurumu() {
    FirebaseFirestore.instance
        .collection("Sinavlar")
        .doc(model.docID)
        .snapshots()
        .listen(
      (DocumentSnapshot doc) {
        final data = doc.data() as Map<String, dynamic>?;

        if (data == null || !data.containsKey('gecersizSayilanlar')) {
          sinavaGirebilir.value = true;
          return;
        }

        List<String> gecersizSayilanlar = List<String>.from(
          data['gecersizSayilanlar'] ?? [],
        );
        sinavaGirebilir.value = !gecersizSayilanlar.contains(
          FirebaseAuth.instance.currentUser!.uid,
        );
      },
      onError: (error) {
        AppSnackbar("Hata", "Geçersizlik durumu yüklenemedi.");
        sinavaGirebilir.value = true;
      },
    );
  }

  void sinaviBitirAlert() {
    FirebaseFirestore.instance
        .collection("Sinavlar")
        .doc(model.docID)
        .collection("SinaviBitenler")
        .doc(DateTime.now().millisecondsSinceEpoch.toString())
        .set({
      "userID": FirebaseAuth.instance.currentUser!.uid,
      "timeStamp": DateTime.now().millisecondsSinceEpoch,
    });
    SetOptions(merge: true);

    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              "Tebrikler!",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.black,
                fontSize: 18,
                fontFamily: "MontserratBold",
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              "Sınavı tamamladın.\n'Sonuçlar' ekranında sonuçlarını görüntüleyebilirsin.",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.black,
                fontSize: 15,
                fontFamily: "MontserratMedium",
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Get.back(); // Close bottom sheet
                      Get.back(); // Close screen
                    },
                    child: Container(
                      height: 50,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                      ),
                      child: const Text(
                        "Tamam",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontFamily: "MontserratBold",
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
    );
  }

  void showGecersizAlert() {
    AppSnackbar(
      "Sınavdan Atıldınız!",
      "Bir çok kez seni uyardık! Maalesef sınav kurallarına uymadığınız için sınavdan atıldınız ve sınavınız geçersiz sayıldı",
    );
  }

  Future<void> addBasvuru() async {
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection("Sinavlar")
          .doc(model.docID)
          .collection("Basvurular")
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .get();

      if (doc.exists) {
        AppSnackbar(
          "Başvurunuz Alınmıştır!",
          "Başvurunuz başarıyla alınmıştır. Şu anda yapılacak başka bir işlem bulunmamaktadır",
        );
      } else {
        await FirebaseFirestore.instance
            .collection("Sinavlar")
            .doc(model.docID)
            .collection("Basvurular")
            .doc(FirebaseAuth.instance.currentUser!.uid)
            .set({"timeStamp": DateTime.now().microsecondsSinceEpoch});
        SetOptions(merge: true);

        showSucces.value = true;
        dahaOnceBasvurdu.value = true;
      }
    } catch (error) {
      AppSnackbar("Hata", "Başvuru işlemi başarısız.");
    }
  }

  Future<void> basvuruKontrol() async {
    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection("Sinavlar")
          .doc(model.docID)
          .collection("Basvurular")
          .get();

      basvuranSayisi.value = querySnapshot.docs.length;

      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection("Sinavlar")
          .doc(model.docID)
          .collection("Basvurular")
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .get();

      dahaOnceBasvurdu.value = doc.exists;
    } catch (error) {
      AppSnackbar("Hata", "Başvuru kontrolü başarısız.");
    }
  }

  Future<void> refreshData() async {
    currentTime.value = DateTime.now().millisecondsSinceEpoch;
    await fetchUserData();
    await basvuruKontrol();
  }
}
