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
    final screenHeight = Get.height;
    final screenCenterY = screenHeight / 2;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      for (int i = 0; i < floods.length; i++) {
        final key = _floodKeys[i];
        if (key == null) continue;

        final context = key.currentContext;
        if (context == null) continue;

        final renderBox = context.findRenderObject() as RenderBox?;
        if (renderBox == null || !renderBox.attached) continue;

        final position = renderBox.localToGlobal(Offset.zero);
        final size = renderBox.size;
        final widgetTop = position.dy;
        final widgetBottom = position.dy + size.height;

        // Ekranın ortasında mı?
        if (widgetTop <= screenCenterY && widgetBottom >= screenCenterY) {
          if (centeredIndex.value != i) {
            // Önceki controller'ı temizle
            if (lastCenteredIndex != null && lastCenteredIndex != i) {
              final prevModel = floods[lastCenteredIndex!];
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
