import 'dart:developer';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Models/Education/answer_key_sub_model.dart';
import 'package:turqappv2/Models/Education/booklet_model.dart';

class BookletAnswerController extends GetxController {
  final AnswerKeySubModel model;
  final BookletModel anaModel;

  final cevaplar = <String>[].obs;
  final completed = false.obs;
  final isInterstitialAdReady = false.obs;
  final iosList = ''.obs;
  final androidList = ''.obs;

  BookletAnswerController(this.model, this.anaModel);

  @override
  void onInit() {
    super.onInit();
    cevaplar.assignAll(List.filled(model.dogruCevaplar.length, ""));
    fetchAds();
  }


  Future<void> fetchAds() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection("Yönetim")
          .doc("Genel")
          .get();
      iosList.value = doc.get("iosFullReklamlar") ?? '';
      androidList.value = doc.get("androidFullReklamlar") ?? '';
      runAds();
    } catch (e) {
      log("Reklam verisi çekme hatası: $e");
    }
  }

  void runAds() {
    final adUnitId = Platform.isIOS ? iosList.value : androidList.value;
    log("GOOGLE ADMOB RANDOM ID: $adUnitId");
    if (adUnitId.isNotEmpty) {}
  }

  void updateAnswer(int index, String answer) {
    cevaplar[index] = answer;
  }

  Future<void> finishTest() async {
    int correct = 0;
    int wrong = 0;

    for (int i = 0; i < model.dogruCevaplar.length; i++) {
      if (cevaplar[i] == model.dogruCevaplar[i]) {
        correct++;
      } else if (cevaplar[i] != model.dogruCevaplar[i] && cevaplar[i] != "") {
        wrong++;
      }
    }

    double score = (correct / model.dogruCevaplar.length) * 100;

    log("Doğru: $correct, Yanlış: $wrong, Puan: $score");

    try {
      await FirebaseFirestore.instance
          .collection("users")
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .collection("KitapcikCevaplari")
          .add({
        "timeStamp": DateTime.now().millisecondsSinceEpoch,
        "kitapcikID": anaModel.docID,
        "baslik": model.baslik,
        "cevaplar": cevaplar,
        "dogruCevaplar": model.dogruCevaplar,
        "dogru": correct,
        "yanlis": wrong,
        "bos": model.dogruCevaplar.length - (correct + wrong),
        "puan": score,
      });
      completed.value = true;
    } catch (e) {
      log("Test sonucu kaydetme hatası: $e");
    }
  }
}
