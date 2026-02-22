import 'dart:async';

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
  var busyMarkAllRead = false.obs;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _notificationSub;

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
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      complatedDataFetch.value = true;
      list.clear();
      return;
    }

    _notificationSub?.cancel();
    _notificationSub = FirebaseFirestore.instance
        .collection("users")
        .doc(uid)
        .collection("notifications")
        .orderBy("timeStamp", descending: true)
        .limit(300)
        .snapshots()
        .listen((snapshot) {
      final allNotifications = snapshot.docs
          .where((doc) {
            final data = doc.data();
            final hideByFlag = data["hideInAppInbox"] == true;
            final hideByLegacyPostId =
                (data["postID"] ?? "").toString() == "admin-manual-push";
            return !hideByFlag && !hideByLegacyPostId;
          })
          .map((doc) {
        final data = doc.data();

        // Yeni şema: type/fromUserID/postID/read/timeStamp
        if (data.containsKey("type") || data.containsKey("fromUserID")) {
          final type = (data["type"] ?? "").toString();
          final postType = _postTypeFromType(type);
          final title = (data["title"] ?? "").toString();
          final body = (data["body"] ?? "").toString();

          return NotificationModel(
            docID: doc.id,
            isRead: (data["read"] ?? false) == true,
            postID: (data["postID"] ?? "").toString(),
            postType: postType,
            thumbnail: (data["thumbnail"] ?? "").toString(),
            timeStamp: data["timeStamp"] ?? 0,
            title: title,
            userID: (data["fromUserID"] ?? "").toString(),
            desc: body.isNotEmpty ? body : _descFromType(type, title: title),
          );
        }

        // Eski şema desteği (geriye dönük)
        return NotificationModel.fromJson(data, doc.id);
      }).toList();

      complatedDataFetch.value = true;
      list.value = allNotifications;
    }, onError: (_) {
      complatedDataFetch.value = true;
    });
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

  Future<void> markAsRead(String docID) async {
    final idx = list.indexWhere((n) => n.docID == docID);
    if (idx < 0 || list[idx].isRead) return;

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    list[idx].isRead = true;
    list.refresh();

    try {
      await FirebaseFirestore.instance
          .collection("users")
          .doc(uid)
          .collection("notifications")
          .doc(docID)
          .set({"read": true}, SetOptions(merge: true));
    } catch (_) {
      list[idx].isRead = false;
      list.refresh();
    }
  }

  Future<void> markAllAsRead() async {
    if (busyMarkAllRead.value) return;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    busyMarkAllRead.value = true;
    final unread = list
        .where((n) => !n.isRead)
        .map((n) => n.docID)
        .toList(growable: false);
    if (unread.isEmpty) {
      busyMarkAllRead.value = false;
      return;
    }

    try {
      for (var i = 0; i < unread.length; i += 450) {
        final batch = FirebaseFirestore.instance.batch();
        final chunk = unread.skip(i).take(450);
        for (final docID in chunk) {
          batch.set(
            FirebaseFirestore.instance
                .collection("users")
                .doc(uid)
                .collection("notifications")
                .doc(docID),
            {"read": true},
            SetOptions(merge: true),
          );
        }
        await batch.commit();
      }
      for (final item in list) {
        item.isRead = true;
      }
      list.refresh();
    } finally {
      busyMarkAllRead.value = false;
    }
  }

  int get unreadCount => list.where((n) => !n.isRead).length;

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

  bool isMentionNotification(NotificationModel model) {
    final desc = model.desc.toLowerCase();
    final title = model.title.toLowerCase();
    final isComment = model.postType == "Comment";
    return desc.contains("@") ||
        title.contains("@") ||
        desc.contains("etiket") ||
        title.contains("etiket") ||
        isComment;
  }

  String _descFromType(String type, {String title = ""}) {
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

  @override
  void onClose() {
    _notificationSub?.cancel();
    pageController.dispose();
    super.onClose();
  }
}
