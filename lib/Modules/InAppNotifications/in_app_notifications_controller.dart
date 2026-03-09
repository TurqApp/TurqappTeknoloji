import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Services/notification_preferences_service.dart';
import 'package:turqappv2/Models/notification_model.dart';

class InAppNotificationsController extends GetxController {
  var selection = 0.obs;
  PageController pageController = PageController(initialPage: 0);
  RxList<NotificationModel> list = <NotificationModel>[].obs;
  var complatedDataFetch = false.obs;
  var busyMarkAllRead = false.obs;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _notificationSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
      _newNotificationHeadSub;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _settingsSub;
  final List<NotificationModel> _allNotifications = <NotificationModel>[];
  Map<String, dynamic> _preferences = NotificationPreferencesService.defaults();
  final RxInt unreadTotal = 0.obs;

  @override
  void onInit() {
    super.onInit();
    _bindPreferences();
    getData();
  }

  void _bindPreferences() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    _settingsSub?.cancel();
    _settingsSub = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('settings')
        .doc('notifications')
        .snapshots()
        .listen((snapshot) {
      _preferences =
          NotificationPreferencesService.mergeWithDefaults(snapshot.data());
      _applyFilters();
    });
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
    _newNotificationHeadSub?.cancel();

    await _loadInitialNotificationsFromCache(uid);
    _bindNotificationsCacheStream(uid);
    _bindNewNotificationHeadStream(uid);
  }

  Future<void> _loadInitialNotificationsFromCache(String uid) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection("users")
          .doc(uid)
          .collection("notifications")
          .orderBy("timeStamp", descending: true)
          .limit(300)
          .get(const GetOptions(source: Source.cache));
      _applyNotificationDocs(snapshot.docs, replace: true);
    } catch (_) {
      complatedDataFetch.value = true;
    }
  }

  void _bindNotificationsCacheStream(String uid) {
    _notificationSub = FirebaseFirestore.instance
        .collection("users")
        .doc(uid)
        .collection("notifications")
        .orderBy("timeStamp", descending: true)
        .limit(300)
        .snapshots(source: ListenSource.cache)
        .listen((snapshot) {
      _applyNotificationDocs(snapshot.docs, replace: true);
    }, onError: (error) {
      complatedDataFetch.value = true;
      debugPrint("🔔 InApp notifications listener error: $error");
    });
  }

  void _bindNewNotificationHeadStream(String uid) {
    _newNotificationHeadSub = FirebaseFirestore.instance
        .collection("users")
        .doc(uid)
        .collection("notifications")
        .orderBy("timeStamp", descending: true)
        .limit(1)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.docs.isEmpty) return;
      final headData = snapshot.docs.first.data();
      final headTs = _asInt(headData["timeStamp"]);
      if (headTs > _latestLoadedNotificationTs()) {
        unawaited(_fetchOnlyNewNotifications(uid));
      }
    }, onError: (_) {});
  }

  Future<void> _fetchOnlyNewNotifications(String uid) async {
    try {
      final latestTs = _latestLoadedNotificationTs();
      Query<Map<String, dynamic>> query = FirebaseFirestore.instance
          .collection("users")
          .doc(uid)
          .collection("notifications")
          .orderBy("timeStamp", descending: false)
          .limit(120);
      if (latestTs > 0) {
        query = query.where("timeStamp", isGreaterThan: latestTs);
      }
      final snapshot = await query.get(const GetOptions(source: Source.server));
      _applyNotificationDocs(snapshot.docs, replace: false);
    } catch (_) {}
  }

  int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse("$value") ?? 0;
  }

  int _latestLoadedNotificationTs() {
    var latest = 0;
    for (final n in _allNotifications) {
      final ts = _asInt(n.timeStamp);
      if (ts > latest) latest = ts;
    }
    return latest;
  }

  List<NotificationModel> _mapNotificationDocs(
      List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    return docs.where((doc) {
      final data = doc.data();
      final hideByFlag = data["hideInAppInbox"] == true;
      final hideByLegacyPostId =
          (data["postID"] ?? "").toString() == "admin-manual-push";
      return !hideByFlag && !hideByLegacyPostId;
    }).map((doc) {
      final data = doc.data();

      if (data.containsKey("type") || data.containsKey("fromUserID")) {
        final type = (data["type"] ?? "").toString();
        final postType = _postTypeFromType(type);
        final title = (data["title"] ?? "").toString();
        final body = (data["body"] ?? "").toString();

        return NotificationModel(
          docID: doc.id,
          isRead: (data["read"] ?? false) == true,
          type: type,
          postID: (data["postID"] ?? "").toString(),
          postType: postType,
          thumbnail: (data["thumbnail"] ?? "").toString(),
          timeStamp: _asInt(data["timeStamp"]),
          title: title,
          userID: (data["fromUserID"] ?? "").toString(),
          desc: body.isNotEmpty ? body : _descFromType(type, title: title),
        );
      }

      return NotificationModel.fromJson(data, doc.id);
    }).toList();
  }

  void _applyNotificationDocs(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs, {
    required bool replace,
  }) {
    final mapped = _mapNotificationDocs(docs);
    if (replace) {
      _allNotifications
        ..clear()
        ..addAll(mapped);
    } else {
      final merged = <String, NotificationModel>{
        for (final item in _allNotifications) item.docID: item,
      };
      for (final item in mapped) {
        merged[item.docID] = item;
      }
      final next = merged.values.toList(growable: false)
        ..sort((a, b) => _asInt(b.timeStamp).compareTo(_asInt(a.timeStamp)));
      _allNotifications
        ..clear()
        ..addAll(next);
    }
    complatedDataFetch.value = true;
    _applyFilters();
    _refreshUnreadTotal();
  }

  void _applyFilters() {
    list.value = _allNotifications
        .where((notification) => NotificationPreferencesService.isTypeEnabled(
              notification.type.isEmpty
                  ? notification.postType
                  : notification.type,
              _preferences,
            ))
        .toList(growable: false);
    _refreshUnreadTotal();
  }

  void _refreshUnreadTotal() {
    unreadTotal.value = _allNotifications.where((n) => !n.isRead).length;
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

  Future<void> deleteMany(List<String> docIDs) async {
    if (docIDs.isEmpty) return;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final uniqueIds = docIDs.toSet().toList(growable: false);

    for (var i = 0; i < uniqueIds.length; i += 450) {
      final batch = FirebaseFirestore.instance.batch();
      final chunk = uniqueIds.skip(i).take(450);
      for (final docID in chunk) {
        batch.delete(
          FirebaseFirestore.instance
              .collection("users")
              .doc(uid)
              .collection("notifications")
              .doc(docID),
        );
      }
      await batch.commit();
    }
    list.removeWhere((n) => uniqueIds.contains(n.docID));
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
      _refreshUnreadTotal();
    } catch (_) {
      list[idx].isRead = false;
      list.refresh();
      _refreshUnreadTotal();
    }
  }

  Future<void> markManyAsRead(List<String> docIDs) async {
    if (docIDs.isEmpty) return;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final uniqueIds = docIDs.toSet().toList(growable: false);

    final changed = <int>[];
    for (var i = 0; i < list.length; i++) {
      if (!uniqueIds.contains(list[i].docID) || list[i].isRead) continue;
      list[i].isRead = true;
      changed.add(i);
    }
    if (changed.isNotEmpty) {
      list.refresh();
      _refreshUnreadTotal();
    }

    try {
      for (var i = 0; i < uniqueIds.length; i += 450) {
        final batch = FirebaseFirestore.instance.batch();
        final chunk = uniqueIds.skip(i).take(450);
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
    } catch (_) {
      for (final idx in changed) {
        list[idx].isRead = false;
      }
      if (changed.isNotEmpty) {
        list.refresh();
        _refreshUnreadTotal();
      }
    }
  }

  // Firestore read yapmadan, belirli bir sohbetin bildirimlerini localde okunduya çeker.
  void markChatNotificationsReadLocal({required String chatId}) {
    final targetChatId = chatId.trim();
    if (targetChatId.isEmpty) return;

    final toMarkIds = <String>[];
    for (final item in _allNotifications) {
      if (item.isRead) continue;
      final normalizedType =
          (item.type.isNotEmpty ? item.type : item.postType).toLowerCase();
      final isChatType =
          normalizedType == "chat" || normalizedType == "message";
      if (!isChatType) continue;
      if (item.postID != targetChatId) continue;
      item.isRead = true;
      toMarkIds.add(item.docID);
    }

    if (toMarkIds.isEmpty) return;
    list.refresh();
    _refreshUnreadTotal();
    unawaited(markManyAsRead(toMarkIds));
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
      _refreshUnreadTotal();
    } finally {
      busyMarkAllRead.value = false;
    }
  }

  int get unreadCount => unreadTotal.value;

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
      case "job_application":
        return "JobApplication";
      case "tutoring_application":
      case "tutoring_status":
        return "TutoringApplication";
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
      case "job_application":
        return "ilanına başvuru yaptı";
      case "tutoring_application":
        return "özel ders ilanına başvuru yaptı";
      case "tutoring_status":
        return "özel ders başvuru durumunu güncelledi";
      default:
        return "";
    }
  }

  @override
  void onClose() {
    _notificationSub?.cancel();
    _newNotificationHeadSub?.cancel();
    _settingsSub?.cancel();
    pageController.dispose();
    super.onClose();
  }
}
