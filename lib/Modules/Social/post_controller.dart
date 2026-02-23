import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';
import 'package:turqappv2/Models/posts_model.dart';
import '../../Services/firebase_my_store.dart';
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
    await FirebaseFirestore.instance
        .collection("Posts")
        .doc(postID)
        .collection("Yorumlar")
        .get()
        .then((snap) {
      yorumCount.value = snap.docs.length.toInt();
    });
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
    //     ilkPaylasanPfImage.value = doc.get("pfImage");
    //   });
    // }
  }

  Future<void> begen(String postID) async {
    final user = Get.find<FirebaseMyStore>();
    final userID = user.userID.value;

    final docRef = FirebaseFirestore.instance.collection("Posts").doc(postID);
    final docSnapshot = await docRef.get();

    if (docSnapshot.exists) {
      final data = docSnapshot.data() as Map<String, dynamic>;
      final List<dynamic> currentLikes = data["begeniler"] ?? [];
      final List<dynamic> currentDislikes = data["begenmeme"] ?? [];

      // Eğer kullanıcı beğenmişse beğeniyi kaldır
      if (currentLikes.contains(userID)) {
        await docRef.update({
          "begeniler": FieldValue.arrayRemove([userID])
        });
        begeniler.remove(userID);
      } else {
        // Daha önce beğenmeme yaptıysa onu kaldır
        if (currentDislikes.contains(userID)) {
          await docRef.update({
            "begenmeme": FieldValue.arrayRemove([userID])
          });
          begenmeme.remove(userID);
        }

        // Beğeni ekle
        await docRef.update({
          "begeniler": FieldValue.arrayUnion([userID])
        });
        begeniler.add(userID);
      }
    }
  }

  Future<void> begenme(String postID) async {
    final user = Get.find<FirebaseMyStore>();
    final userID = user.userID.value;

    final docRef = FirebaseFirestore.instance.collection("Posts").doc(postID);
    final docSnapshot = await docRef.get();

    if (docSnapshot.exists) {
      final data = docSnapshot.data() as Map<String, dynamic>;
      final List<dynamic> currentDislikes = data["begenmeme"] ?? [];
      final List<dynamic> currentLikes = data["begeniler"] ?? [];

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
  }

  Future<void> kayitEt(String postID) async {
    final user = Get.find<FirebaseMyStore>();
    final userID = user.userID.value;

    final docRef = FirebaseFirestore.instance.collection("Posts").doc(postID);
    final docSnapshot = await docRef.get();

    if (docSnapshot.exists) {
      final data = docSnapshot.data() as Map<String, dynamic>;
      final List<dynamic> currentLikes = data["kayitEdenler"] ?? [];

      // Eğer kullanıcı beğenmişse beğeniyi kaldır
      if (currentLikes.contains(userID)) {
        await docRef.update({
          "kayitEdenler": FieldValue.arrayRemove([userID])
        });
        kaydedilenler.remove(userID);
      } else {
        await docRef.update({
          "kayitEdenler": FieldValue.arrayUnion([userID])
        });
        kaydedilenler.add(userID);
      }
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
    final String text = 'https://www.turqapp.com/post/${model.docID}';

    try {
      // Share the downloaded file
      SharePlus.instance.share(ShareParams(text: text));
    } catch (e) {
      print('Error downloading or sharing the image: $e');
    }
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
