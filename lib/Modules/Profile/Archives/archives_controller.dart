import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Models/posts_model.dart';
import 'package:turqappv2/Core/Repositories/profile_repository.dart';
import 'package:turqappv2/Core/Services/silent_refresh_gate.dart';
import 'package:uuid/uuid.dart';
import '../../Agenda/AgendaContent/agenda_content_controller.dart';

class ArchiveController extends GetxController {
  static const Duration _silentRefreshInterval = Duration(minutes: 5);

  final ProfileRepository _profileRepository = ProfileRepository.ensure();
  final scrollController = ScrollController();

  final RxList<PostsModel> list = <PostsModel>[].obs;
  final RxBool isLoading = true.obs;
  final Map<int, GlobalKey> _agendaKeys = {};
  int? lastCenteredIndex;
  final centeredIndex = 0.obs;
  String? _pendingCenteredDocId;
  StreamSubscription<User?>? _authSub;
  String? _currentUserId;

  @override
  void onInit() {
    super.onInit();
    scrollController.addListener(_onScroll);
    _bindAuth();
  }

  @override
  void onClose() {
    scrollController.removeListener(_onScroll);
    scrollController.dispose();
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
    }
  }

  int _resolveRestoreIndex() {
    if (list.isEmpty) return -1;
    final pendingDocId = _pendingCenteredDocId;
    if (pendingDocId != null && pendingDocId.isNotEmpty) {
      final mapped = list.indexWhere((post) => post.docID == pendingDocId);
      if (mapped >= 0) return mapped;
    }
    if (lastCenteredIndex != null &&
        lastCenteredIndex! >= 0 &&
        lastCenteredIndex! < list.length) {
      return lastCenteredIndex!;
    }
    if (centeredIndex.value >= 0 && centeredIndex.value < list.length) {
      return centeredIndex.value;
    }
    return 0;
  }

  void _restoreCenteredPost() {
    final target = _resolveRestoreIndex();
    if (target < 0 || target >= list.length) return;
    centeredIndex.value = target;
    lastCenteredIndex = target;
    _pendingCenteredDocId = null;
  }

  void _bindAuth() {
    _authSub = FirebaseAuth.instance.userChanges().listen((user) {
      final nextUserId = user?.uid;
      if (_currentUserId != nextUserId) {
        _currentUserId = nextUserId;
        list.clear();
      }
      if (nextUserId == null) {
        isLoading.value = false;
        return;
      }
      unawaited(_bootstrapArchive(nextUserId));
    });
  }

  Future<void> _bootstrapArchive(String uid) async {
    final cached = await _profileRepository.readCachedArchive(uid);
    if (cached.isNotEmpty) {
      list.assignAll(cached);
      isLoading.value = false;
      if (SilentRefreshGate.shouldRefresh(
        'archive:$uid',
        minInterval: _silentRefreshInterval,
      )) {
        unawaited(fetchData(silent: true));
      }
      return;
    }
    await fetchData();
  }

  Future<void> fetchData({bool silent = false}) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    if (!silent) {
      isLoading.value = true;
    }
    final currentCentered = centeredIndex.value;
    if (currentCentered >= 0 && currentCentered < list.length) {
      _pendingCenteredDocId = list[currentCentered].docID;
    } else if (lastCenteredIndex != null &&
        lastCenteredIndex! >= 0 &&
        lastCenteredIndex! < list.length) {
      _pendingCenteredDocId = list[lastCenteredIndex!].docID;
    }
    try {
      final posts = await _profileRepository.fetchArchive(uid);
      list.assignAll(posts);
      _restoreCenteredPost();
      SilentRefreshGate.markRefreshed('archive:$uid');
    } finally {
      isLoading.value = false;
    }
  }
}
