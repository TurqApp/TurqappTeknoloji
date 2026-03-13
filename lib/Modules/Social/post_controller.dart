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
    // TODO: implement onInit
    super.onInit();
    getYorumCount(postID);
    getIlkPaylasan();
    begeniler.assignAll(fetch_begeniler);
    begenmeme.assignAll(fetch_begenmemeler);
    kaydedilenler.assignAll(fetch_kaydedilenler);
    yenidenPaylasilanKullanicilar
        .assignAll(fetch_yenidenPaylasilanKullanicilar);
    gizlendi.value = model.gizlendi;
    arsivlendi.value = model.arsiv;
  }

  Future<void> getYorumCount(String postID) async {
    final cached = await _postRepository.fetchPostById(postID);
    yorumCount.value = cached?.stats.commentCount.toInt() ?? yorumCount.value;
  }

  Future<void> getIlkPaylasan() async {
    // if (model.mainUserID != "") {
    //   FirebaseFirestore.instance
    //       .collection("users")
    //       .doc(model.mainUserID)
    //       .get()
    //       .then((DocumentSnapshot doc) {
    //     ilkPaylasanUserID.value = model.mainUserID;
    //     ilkPaylasanNickname.value = doc.get("nickname");
    //     ilkPaylasanPfImage.value = doc.get("avatarUrl");
    //   });
    // }
  }

  Future<void> begen(String postID) async {
    final userID = CurrentUserService.instance.userId;
    if (userID.isEmpty) return;
    final nextLiked = await _postRepository.toggleLike(model);
    if (nextLiked) {
      if (!begeniler.contains(userID)) begeniler.add(userID);
    } else {
      begeniler.remove(userID);
    }
  }

  Future<void> begenme(String postID) async {
    final userID = CurrentUserService.instance.userId;
    if (userID.isEmpty) return;

    final cached = await _postRepository.fetchPostRawById(postID);
    if (cached == null) return;
    final docRef = FirebaseFirestore.instance.collection("Posts").doc(postID);

    final currentDislikes =
        List<String>.from((cached["begenmeme"] as List?) ?? const []);
    final currentLikes =
        List<String>.from((cached["begeniler"] as List?) ?? const []);

    // Eğer daha önce beğenmişse beğeni kaldırılır
    if (currentLikes.contains(userID)) {
      await docRef.update({
        "begeniler": FieldValue.arrayRemove([userID])
      });
      begeniler.remove(userID);
    }

    // Beğenmeme kontrolü
    if (currentDislikes.contains(userID)) {
      await docRef.update({
        "begenmeme": FieldValue.arrayRemove([userID])
      });
      begenmeme.remove(userID);
    } else {
      await docRef.update({
        "begenmeme": FieldValue.arrayUnion([userID])
      });
      begenmeme.add(userID);
    }
  }

  Future<void> kayitEt(String postID) async {
    final userID = CurrentUserService.instance.userId;
    if (userID.isEmpty) return;
    final nextSaved = await _postRepository.toggleSave(model);
    if (nextSaved) {
      if (!kaydedilenler.contains(userID)) kaydedilenler.add(userID);
    } else {
      kaydedilenler.remove(userID);
    }
  }

  Future<void> yenidenPaylas() async {
    // final docID = const Uuid().v4();
    // final times = DateTime.now().millisecondsSinceEpoch;
    // FirebaseFirestore.instance.collection("Posts").doc(docID).set({
    //   "arsiv": false,
    //   "begeniler": [],
    //   "hedefKitle": model.hedefKitle,
    //   "img": model.img,
    //   "kategori": [],
    //   "kayitEdenler": [],
    //   "muzik": model.muzik,
    //   "tekrarPaylas": model.tekrarPaylas,
    //   "timeStamp": times,
    //   "userID": FirebaseAuth.instance.currentUser!.uid,
    //   "konum": model.konum,
    //   "metin": model.metin,
    //   "video": model.video,
    //   "yasKilidi": model.yasKilidi,
    //   "yorumlar": model.yorumlar,
    //   "yenidenPaylasilanPostlar": [],
    //   "yenidenPaylasilanKullanicilar": [],
    //   "anaPaylasimPostID": model.anaPaylasimPostID != "" ? model.anaPaylasimPostID : model.docID,
    //   "begenmeme": [],
    //   "goruntuleme": [],
    //   "izBirakYayinTarihi": model.izBirakYayinTarihi,
    //   "thumbnailOfVideo": model.thumbnailOfVideo,
    //   "mainUserID": model.mainUserID
    // });
    //
    // FirebaseFirestore.instance.collection("Posts").doc(model.docID).update({
    //   "yenidenPaylasilanPostlar": FieldValue.arrayUnion([docID]),
    //   "yenidenPaylasilanKullanicilar":
    //   FieldValue.arrayUnion([FirebaseAuth.instance.currentUser!.uid])
    // });
    //
    // yenidenPaylasilanKullanicilar
    //     .add(FirebaseAuth.instance.currentUser!.uid);
  }

  Future<void> yorumYap(BuildContext context, {VoidCallback? onClosed}) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.95,
        child: PostComments(
          postID: postID,
          userID: model.userID,
          collection: 'Sosyal',
        ),
      ),
    );

    // Modal kapandıktan sonra çalışacak callback
    if (onClosed != null) {
      onClosed();
    }
  }

  Future<void> openShareSheet(BuildContext context) async {
    await ShareActionGuard.run(() async {
      try {
        final previewImage = model.thumbnail.trim().isNotEmpty
            ? model.thumbnail.trim()
            : (model.img.isNotEmpty ? model.img.first.trim() : null);
        final shortUrl = await ShortLinkService().getPostPublicUrl(
          postId: model.docID,
          desc: model.metin,
          imageUrl: previewImage,
        );
        await ShareLinkService.shareUrl(
          url: shortUrl,
          title: 'TurqApp Gönderisi',
          subject: 'TurqApp Gönderisi',
        );
      } catch (e) {
        print('Error downloading or sharing the image: $e');
      }
    });
  }

  Future<void> gizle(bool gizle) async {
    gizlendi.value = gizle;
  }

  Future<void> arsivle(bool arsivle) async {
    arsivlendi.value = arsivle;
  }

  Future<void> changePage(int index) async {
    pageCounter.value = index;
  }
}
