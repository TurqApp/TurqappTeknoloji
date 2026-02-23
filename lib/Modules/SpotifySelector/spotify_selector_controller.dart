import 'package:audioplayers/audioplayers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../Models/music_model.dart';

class SpotifySelectorController extends GetxController {
  RxList<MusicModel> list = <MusicModel>[].obs;
  final pageController = PageController();
  final currentPlayingUrl = ''.obs;

  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void onInit() {
    super.onInit();

    // dinleyici: şarkı bitince dur
    _audioPlayer.onPlayerComplete.listen((event) {
      currentPlayingUrl.value = '';
    });

    // veriyi çek
    FirebaseFirestore.instance
        .collection("Yönetim")
        .doc("Musics")
        .collection("List")
        .get()
        .then((snap) {
      for (var doc in snap.docs) {
        list.add(MusicModel(
          docID: doc.id,
          counter: doc.get("counter"),
          url: doc.get("url"),
        ));
      }
    });
  }

  Future<void> playMusic(String url) async {
    if (currentPlayingUrl.value == url) {
      await _audioPlayer.pause();
      currentPlayingUrl.value = '';
      return;
    }

    await _audioPlayer.stop();
    await _audioPlayer.play(UrlSource(url));
    currentPlayingUrl.value = url;
  }

  void goToPage(int index) {
    pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  void onClose() {
    _audioPlayer.dispose();
    super.onClose();
  }
}
