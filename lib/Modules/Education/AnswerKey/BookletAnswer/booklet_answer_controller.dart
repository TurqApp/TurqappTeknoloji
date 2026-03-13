import 'dart:developer';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Repositories/config_repository.dart';
import 'package:turqappv2/Models/Education/answer_key_sub_model.dart';
import 'package:turqappv2/Models/Education/booklet_model.dart';

class BookletAnswerController extends GetxController {
  final ConfigRepository _configRepository = ConfigRepository.ensure();
  final AnswerKeySubModel model;
  final BookletModel anaModel;

  final cevaplar = <String>[].obs;
  final completed = false.obs;
  final correctCount = 0.obs;
  final wrongCount = 0.obs;
  final emptyCount = 0.obs;
  final scorePercent = 0.0.obs;
  final netScore = 0.0.obs;
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
      final doc = await _configRepository.getLegacyConfigDoc(
        collection: 'Yönetim',
        docId: 'Genel',
      );
      iosList.value = (doc?["iosFullReklamlar"] ?? '').toString();
      androidList.value = (doc?["androidFullReklamlar"] ?? '').toString();
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

    final total = model.dogruCevaplar.length;
    final empty = total - (correct + wrong);
    final score = (correct / total) * 100;
    final net = correct - (wrong / 4.0);

    correctCount.value = correct;
    wrongCount.value = wrong;
    emptyCount.value = empty;
    scorePercent.value = score;
    netScore.value = net;

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
        "bos": empty,
        "puan": score,
        "net": net,
      });
      completed.value = true;
    } catch (e) {
      log("Test sonucu kaydetme hatası: $e");
    }
  }
}
