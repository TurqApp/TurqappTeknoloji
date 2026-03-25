import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Services/share_action_guard.dart';
import 'package:turqappv2/Core/Services/share_link_service.dart';
import 'package:turqappv2/Core/Repositories/post_repository.dart';
import 'package:turqappv2/Models/posts_model.dart';
import 'package:turqappv2/Core/Services/short_link_service.dart';
import '../../Services/current_user_service.dart';
import 'Comments/post_comments.dart';

part 'post_controller_actions_part.dart';

class PostController extends GetxController {
  String postID;
  List<String> fetch_begeniler;
  List<String> fetch_begenmemeler;
  List<String> fetch_kaydedilenler;
  List<String> fetch_yenidenPaylasilanKullanicilar;
  PostsModel model;

  PostController(
      {required this.postID,
      required this.model,
      required this.fetch_begeniler,
      required this.fetch_begenmemeler,
      required this.fetch_kaydedilenler,
      required this.fetch_yenidenPaylasilanKullanicilar});

  var yorumCount = 0.obs;
  var pageCounter = 0.obs;
  var begeniler = [].obs;
  var begenmeme = [].obs;
  var kaydedilenler = [].obs;
  var yenidenPaylasilanKullanicilar = [].obs;
  var goruntuleme = 0.obs;
  var tekrarPaylasilmaSayisi = 0.obs;
  var gizlendi = false.obs;
  var arsivlendi = false.obs;
  var ilkPaylasanPfImage = "".obs;
  var ilkPaylasanNickname = "".obs;
  var ilkPaylasanUserID = "".obs;
  final PostRepository _postRepository = PostRepository.ensure();

  @override
  void onInit() {
    super.onInit();
    _initializePostState(this);
    begeniler.assignAll(fetch_begeniler);
    begenmeme.assignAll(fetch_begenmemeler);
    kaydedilenler.assignAll(fetch_kaydedilenler);
    yenidenPaylasilanKullanicilar
        .assignAll(fetch_yenidenPaylasilanKullanicilar);
    gizlendi.value = model.gizlendi;
    arsivlendi.value = model.arsiv;
  }
}
