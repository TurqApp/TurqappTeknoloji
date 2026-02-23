import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Models/posts_model.dart';
import 'package:uuid/uuid.dart';
import '../../Agenda/AgendaContent/agenda_content_controller.dart';

class ArchiveController extends GetxController {
  final scrollController = ScrollController();

  final RxList<PostsModel> list = <PostsModel>[].obs;
  final Map<int, GlobalKey> _agendaKeys = {};
  int? lastCenteredIndex;
  final centeredIndex = 0.obs;
  StreamSubscription? _sub;
  StreamSubscription<User?>? _authSub;

  @override
  void onInit() {
    super.onInit();
    scrollController.addListener(_onScroll);
    _bindAuth();
    _bindArchive();
  }

  @override
  void onClose() {
    scrollController.removeListener(_onScroll);
    scrollController.dispose();
    _sub?.cancel();
    _authSub?.cancel();
    super.onClose();
  }

  GlobalKey getAgendaKey(int index) {
    return _agendaKeys.putIfAbsent(
        index, () => GlobalObjectKey("archives_${Uuid().v4()}"));
  }

  void _onScroll() {
    if (scrollController.position.pixels >=
        scrollController.position.maxScrollExtent - 300) {
      fetchData();
    }

    final screenHeight = Get.height;
    final screenCenterY = screenHeight / 2;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      for (int i = 0; i < list.length; i++) {
        final key = _agendaKeys[i];
        if (key == null) continue;

        final context = key.currentContext;
        if (context == null) continue;

        final renderBox = context.findRenderObject() as RenderBox?;
        if (renderBox == null || !renderBox.attached) continue;

        final position = renderBox.localToGlobal(Offset.zero);
        final size = renderBox.size;
        final widgetTop = position.dy;
        final widgetBottom = position.dy + size.height;

        if (widgetTop <= screenCenterY && widgetBottom >= screenCenterY) {
          if (centeredIndex.value != i) {
            if (lastCenteredIndex != null && lastCenteredIndex != i) {
              final prevModel = list[lastCenteredIndex!];
              disposeAgendaContentController(prevModel.docID);
            }
            centeredIndex.value = i;
            lastCenteredIndex = i;
          }
          break;
        }
      }
    });
  }

  void disposeAgendaContentController(String docID) {
    if (Get.isRegistered<AgendaContentController>(tag: docID)) {
      Get.delete<AgendaContentController>(tag: docID, force: true);
      print("Disposed AgendaContentController for $docID");
    }
  }

  void _bindAuth() {
    _authSub = FirebaseAuth.instance.userChanges().listen((user) {
      list.clear();
      _sub?.cancel();
      _bindArchive();
    });
  }

  void _bindArchive() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    _sub = FirebaseFirestore.instance
        .collection('Posts')
        .where('userID', isEqualTo: uid)
        .where('arsiv', isEqualTo: true)
        .orderBy('timeStamp', descending: true)
        .snapshots()
        .listen((snap) {
      list.value = snap.docs
          .map(
              (d) => PostsModel.fromMap(d.data(), d.id))
          .toList();
    }, onError: (e) => print('Archive listen error: $e'));
  }

  Future<void> fetchData({bool initial = false}) async {
    // Manual refresh: mevcut binding'i tetiklemek için yeniden kur
    list.clear();
    _sub?.cancel();
    _bindArchive();
  }
}
