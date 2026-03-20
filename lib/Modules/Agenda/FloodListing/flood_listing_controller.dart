import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Repositories/post_repository.dart';
import 'package:turqappv2/Models/posts_model.dart';
import '../AgendaContent/agenda_content_controller.dart';

class FloodListingController extends GetxController {
  // Flood gönderiler listesi
  RxList<PostsModel> floods = <PostsModel>[].obs;

  // Scroll kontrolcüsü
  final scrollController = ScrollController();

  // Her flood için benzersiz GlobalKey
  final Map<int, GlobalKey> _floodKeys = {};

  // Ekranda ortalanan içeriğin index'i
  final centeredIndex = 0.obs;
  int? lastCenteredIndex;
  final PostRepository _postRepository = PostRepository.ensure();

  @override
  void onInit() {
    super.onInit();
    scrollController.addListener(_onScroll);
  }

  @override
  void onClose() {
    scrollController.removeListener(_onScroll);
    scrollController.dispose();
    super.onClose();
  }

  /// Her flood içeriği için benzersiz GlobalKey üretir
  GlobalKey getFloodKey(int index) {
    return _floodKeys.putIfAbsent(index, () => GlobalObjectKey("flood_$index"));
  }

  /// Scroll sırasında hangi içerik ortadaysa onu tespit eder
  void _onScroll() {
    if (!scrollController.hasClients || floods.isEmpty) return;
    final position = scrollController.position;
    if (position.pixels <= 0) {
      centeredIndex.value = 0;
      lastCenteredIndex = 0;
      return;
    }
    final estimatedItemExtent = (position.viewportDimension * 0.74).clamp(
      320.0,
      680.0,
    );
    final nextIndex = (((position.pixels + position.viewportDimension * 0.25) /
                estimatedItemExtent)
            .floor())
        .clamp(0, floods.length - 1);
    if (centeredIndex.value != nextIndex) {
      if (lastCenteredIndex != null && lastCenteredIndex != nextIndex) {
        final prevModel = floods[lastCenteredIndex!];
        disposeAgendaContentController(prevModel.docID);
      }
      centeredIndex.value = nextIndex;
      lastCenteredIndex = nextIndex;
    }
  }

  /// Belirtilen flood için controller'ı siler
  void disposeAgendaContentController(String docID) {
    if (Get.isRegistered<AgendaContentController>(tag: docID)) {
      Get.delete<AgendaContentController>(tag: docID, force: true);
      print("🎯 Disposed AgendaContentController");
    }
  }

  /// Flood verilerini Firestore’dan çek
  Future<void> getFloods(int floodCount, String anyFloodID) async {
    floods.clear();

    // “foo_17” → baseID = “foo”
    final baseID = anyFloodID.replaceFirst(RegExp(r'_\d+$'), '');
    final ids = List<String>.generate(floodCount, (i) => '${baseID}_$i');
    final fetched = await _postRepository.fetchPostCardsByIds(ids);

    // 1️⃣ Kök flood her zaman "_0"
    final rootID = '${baseID}_0';
    try {
      final rootModel = fetched[rootID];
      if (rootModel != null) {
        final m = rootModel;
        if (m.deletedPost != true) floods.add(m);
      }
    } catch (e) {
      print('🔥 Kök flood alınamadı: $e');
    }

    // 2️⃣ Geri kalanları (suffix 1..floodCount-1) sırayla ekle
    for (var i = 1; i < floodCount; i++) {
      final docID = '${baseID}_$i';
      try {
        final model = fetched[docID];
        if (model != null) {
          final m = model;
          if (m.deletedPost != true) floods.add(m);
        }
      } catch (e) {
        print('🔥 Flood verisi alınamadı: $e');
      }
    }
  }
}
