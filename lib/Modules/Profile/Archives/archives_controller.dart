import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Models/posts_model.dart';
import 'package:turqappv2/Core/Repositories/profile_repository.dart';
import 'package:turqappv2/Core/Services/silent_refresh_gate.dart';
import 'package:turqappv2/Services/current_user_service.dart';
import '../../Agenda/AgendaContent/agenda_content_controller.dart';

class ArchiveController extends GetxController {
  static ArchiveController ensure() {
    final existing = maybeFind();
    if (existing != null) return existing;
    return Get.put(ArchiveController());
  }

  static ArchiveController? maybeFind() {
    final isRegistered = Get.isRegistered<ArchiveController>();
    if (!isRegistered) return null;
    return Get.find<ArchiveController>();
  }

  static const Duration _silentRefreshInterval = Duration(minutes: 5);

  final ProfileRepository _profileRepository = ProfileRepository.ensure();
  final scrollController = ScrollController();

  final RxList<PostsModel> list = <PostsModel>[].obs;
  final RxBool isLoading = true.obs;
  final Map<String, GlobalKey> _agendaKeys = {};
  final currentVisibleIndex = RxInt(-1);
  int? lastCenteredIndex;
  final centeredIndex = 0.obs;
  String? _pendingCenteredDocId;
  StreamSubscription<User?>? _authSub;
  String? _currentUserId;

  String get _resolvedCurrentUid => CurrentUserService.instance.effectiveUserId;

  Future<void> _bootstrapArchive(String uid) async {
    final cached = await _profileRepository.readCachedArchive(uid);
    if (cached.isNotEmpty) {
      list.assignAll(cached);
      isLoading.value = false;
      if (SilentRefreshGate.shouldRefresh(
        'archive:$uid',
        minInterval: ArchiveController._silentRefreshInterval,
      )) {
        unawaited(fetchData(silent: true));
      }
      return;
    }
    await fetchData();
  }

  Future<void> fetchData({bool silent = false}) async {
    final uid = _resolvedCurrentUid;
    if (uid.isEmpty) return;
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

  @override
  void onInit() {
    super.onInit();
    _onInitArchiveController();
  }

  @override
  void onClose() {
    _onCloseArchiveController();
    super.onClose();
  }

  String agendaInstanceTag(String docId) => 'archives_$docId';

  GlobalKey getAgendaKey({required String docId}) {
    return _agendaKeys.putIfAbsent(
      docId,
      () => GlobalObjectKey(agendaInstanceTag(docId)),
    );
  }

  void disposeAgendaContentController(String docID) {
    final tag = agendaInstanceTag(docID);
    if (AgendaContentController.maybeFind(tag: tag) != null) {
      Get.delete<AgendaContentController>(tag: tag, force: true);
    }
  }

  void removeArchivedPost(String docId) {
    final normalizedDocId = docId.trim();
    if (normalizedDocId.isEmpty) return;
    final removedIndex = list.indexWhere(
      (post) => post.docID.trim() == normalizedDocId,
    );
    if (removedIndex < 0) return;

    disposeAgendaContentController(normalizedDocId);
    list.removeAt(removedIndex);

    if (list.isEmpty) {
      centeredIndex.value = -1;
      currentVisibleIndex.value = -1;
      lastCenteredIndex = null;
      _pendingCenteredDocId = null;
      return;
    }

    final nextIndex = removedIndex.clamp(0, list.length - 1);
    centeredIndex.value = nextIndex;
    currentVisibleIndex.value = nextIndex;
    lastCenteredIndex = nextIndex;
    capturePendingCenteredEntry(preferredIndex: nextIndex);
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
    currentVisibleIndex.value = target;
    lastCenteredIndex = target;
    _pendingCenteredDocId = null;
  }

  void capturePendingCenteredEntry({int? preferredIndex, PostsModel? model}) {
    if (model != null) {
      final docId = model.docID.trim();
      _pendingCenteredDocId = docId.isEmpty ? null : docId;
      return;
    }
    final candidateIndex = preferredIndex ??
        (currentVisibleIndex.value >= 0
            ? currentVisibleIndex.value
            : lastCenteredIndex);
    if (candidateIndex == null ||
        candidateIndex < 0 ||
        candidateIndex >= list.length) {
      _pendingCenteredDocId = null;
      return;
    }
    final docId = list[candidateIndex].docID.trim();
    _pendingCenteredDocId = docId.isEmpty ? null : docId;
  }

  void _onInitArchiveController() {
    scrollController.addListener(_onScroll);
    _bindAuth();
  }

  void _onCloseArchiveController() {
    scrollController.removeListener(_onScroll);
    scrollController.dispose();
    _authSub?.cancel();
  }

  void _onScroll() {
    if (!scrollController.hasClients) return;
    final position = scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 300) {
      fetchData();
    }
    if (list.isEmpty) return;
    if (position.pixels <= 0) {
      centeredIndex.value = 0;
      currentVisibleIndex.value = 0;
      lastCenteredIndex = 0;
      capturePendingCenteredEntry(preferredIndex: 0);
      return;
    }
    final estimatedItemExtent = (position.viewportDimension * 0.74).clamp(
      320.0,
      680.0,
    );
    final nextIndex = (((position.pixels + position.viewportDimension * 0.25) /
                estimatedItemExtent)
            .floor())
        .clamp(0, list.length - 1);
    if (centeredIndex.value != nextIndex) {
      if (lastCenteredIndex != null && lastCenteredIndex != nextIndex) {
        final prevModel = list[lastCenteredIndex!];
        disposeAgendaContentController(prevModel.docID);
      }
      centeredIndex.value = nextIndex;
      currentVisibleIndex.value = nextIndex;
      lastCenteredIndex = nextIndex;
      capturePendingCenteredEntry(preferredIndex: nextIndex);
    }
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
}
