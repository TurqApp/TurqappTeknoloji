import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Modules/Education/PracticeExams/sinav_model.dart';

class DenemeSinaviPreviewController extends GetxController {
  var nickname = "".obs;
  var avatarUrl = "".obs;
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
      final data = doc.data() as Map<String, dynamic>? ?? {};
      nickname.value =
          (data["nickname"] ?? data["username"] ?? data["displayName"] ?? "")
              .toString();
      avatarUrl.value = (data["avatarUrl"] ??
              data["avatarUrl"] ??
              data["avatarUrl"] ??
              data["avatarUrl"] ??
              "")
          .toString();
    } catch (error) {
      AppSnackbar("Hata", "Kullanıcı bilgileri yüklenemedi.");
    } finally {
      isLoading.value = false;
      isInitialized.value = true;
    }
  }

  Future<void> getGecersizlikDurumu() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection("practiceExams")
          .doc(model.docID)
          .get();
      final data = doc.data();

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
    } catch (error) {
      AppSnackbar("Hata", "Geçersizlik durumu yüklenemedi.");
      sinavaGirebilir.value = true;
    }
  }

  Future<Map<String, num>?> _getLatestExamSummary() async {
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final yanitlar = await FirebaseFirestore.instance
          .collection("practiceExams")
          .doc(model.docID)
          .collection("Yanitlar")
          .where("userID", isEqualTo: uid)
          .get();

      if (yanitlar.docs.isEmpty) return null;

      QueryDocumentSnapshot<Map<String, dynamic>> latest = yanitlar.docs.first;
      for (final doc in yanitlar.docs) {
        final currentTs = (doc.data()["timeStamp"] ?? 0) as num;
        final latestTs = (latest.data()["timeStamp"] ?? 0) as num;
        if (currentTs > latestTs) {
          latest = doc;
        }
      }

      num dogru = 0;
      num yanlis = 0;
      num bos = 0;
      num net = 0;

      for (final ders in model.dersler) {
        final sonucDoc = await FirebaseFirestore.instance
            .collection("practiceExams")
            .doc(model.docID)
            .collection("Yanitlar")
            .doc(latest.id)
            .collection(ders)
            .doc(latest.id)
            .get();

        if (!sonucDoc.exists) continue;
        final data = sonucDoc.data() ?? {};
        dogru += (data["dogru"] ?? 0) as num;
        yanlis += (data["yanlis"] ?? 0) as num;
        bos += (data["bos"] ?? 0) as num;
        net += (data["net"] ?? 0) as num;
      }

      return {
        "dogru": dogru,
        "yanlis": yanlis,
        "bos": bos,
        "net": net,
      };
    } catch (_) {
      return null;
    }
  }

  Future<void> sinaviBitirAlert() async {
    FirebaseFirestore.instance
        .collection("practiceExams")
        .doc(model.docID)
        .collection("SinaviBitenler")
        .doc(DateTime.now().millisecondsSinceEpoch.toString())
        .set({
      "userID": FirebaseAuth.instance.currentUser!.uid,
      "timeStamp": DateTime.now().millisecondsSinceEpoch,
    });
    SetOptions(merge: true);

    final summary = await _getLatestExamSummary();
    final resultText = summary == null
        ? "Sonuç hesaplanamadı."
        : "Doğru: ${summary["dogru"]?.toInt() ?? 0}   •   "
            "Yanlış: ${summary["yanlis"]?.toInt() ?? 0}   •   "
            "Boş: ${summary["bos"]?.toInt() ?? 0}   •   "
            "Net: ${(summary["net"] ?? 0).toStringAsFixed(2)}";

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
            Text(
              resultText,
              textAlign: TextAlign.center,
              style: const TextStyle(
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
          .collection("practiceExams")
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
            .collection("practiceExams")
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
          .collection("practiceExams")
          .doc(model.docID)
          .collection("Basvurular")
          .get();

      basvuranSayisi.value = querySnapshot.docs.length;

      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection("practiceExams")
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
