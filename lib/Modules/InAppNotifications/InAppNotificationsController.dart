import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Models/NotificationModel.dart';

class InAppNotificationsController extends GetxController {
  var selection = 0.obs;
  PageController pageController = PageController(initialPage: 0);
  RxList<NotificationModel> list = <NotificationModel>[].obs;
  var complatedDataFetch = false.obs;

  @override
  void onInit() {
    super.onInit();
    getData();
  }

  void goToPage(int index) {
    pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> getData() async {
    final snapshot = await FirebaseFirestore.instance
        .collection("users")
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .collection("notifications")
        .orderBy("timeStamp", descending: true)
        .get();

    final allNotifications = snapshot.docs.map((doc) {
      final data = doc.data();

      // Yeni şema: type/fromUserID/postID/read/timeStamp
      if (data.containsKey("type") || data.containsKey("fromUserID")) {
        final type = (data["type"] ?? "").toString();
        final postType = _postTypeFromType(type);

        return NotificationModel(
          docID: doc.id,
          isRead: (data["read"] ?? false) == true,
          postID: (data["postID"] ?? "").toString(),
          postType: postType,
          thumbnail: "",
          timeStamp: data["timeStamp"] ?? 0,
          title: "",
          userID: (data["fromUserID"] ?? "").toString(),
          desc: (data["body"] ?? "").toString().isNotEmpty
              ? (data["body"] ?? "").toString()
              : _descFromType(type),
        );
      }

      // Eski şema desteği (geriye dönük)
      return NotificationModel.fromJson(data, doc.id);
    }).toList();

    // İşlem bittiğini işaretleyip tüm bildirimleri tek listede tutuyoruz
    complatedDataFetch.value = true;
    list.value = allNotifications;
  }

  Future<void> delete(String docID) async {
    // Firestore’dan sil
    await FirebaseFirestore.instance
        .collection("users")
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .collection("notifications")
        .doc(docID)
        .delete();

    // Arayüz listesinden de kaldır
    list.removeWhere((n) => n.docID == docID);
  }

  Future<void> bildirimleriTopluSil() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final bildirimlerRef = FirebaseFirestore.instance
        .collection("users")
        .doc(uid)
        .collection("notifications");

    while (true) {
      final snapshot = await bildirimlerRef.limit(500).get();
      if (snapshot.docs.isEmpty) {
        break; // Silinecek doküman kalmadı
      }
      WriteBatch batch = FirebaseFirestore.instance.batch();
      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
      // Firestore batch işlemi sonrası kısa bir bekleme, overload'u önler
      await Future.delayed(const Duration(milliseconds: 100));
    }
    print("Tüm bildirimler toplu olarak silindi!");
  }

  String _postTypeFromType(String type) {
    switch (type) {
      case "follow":
      case "User":
        return "User";
      case "comment":
      case "Comment":
        return "Comment";
      case "message":
      case "Chat":
        return "Chat";
      case "like":
      case "reshared_posts":
      case "shared_as_posts":
      case "Posts":
      default:
        return "Posts";
    }
  }

  String _descFromType(String type) {
    switch (type) {
      case "like":
        return "gönderini beğendi";
      case "comment":
        return "gönderine yorum yaptı";
      case "reshared_posts":
        return "gönderini yeniden paylaştı";
      case "shared_as_posts":
        return "gönderini paylaştı";
      case "follow":
      case "User":
        return "seni takip etmeye başladı";
      case "message":
      case "Chat":
        return "sana mesaj gönderdi";
      default:
        return "";
    }
  }

}
