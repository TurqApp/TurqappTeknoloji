import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Repositories/post_repository.dart';
import 'package:turqappv2/Models/posts_model.dart';
import '../AgendaContent/agenda_content_controller.dart';

part 'flood_listing_controller_runtime_part.dart';
part 'flood_listing_controller_data_part.dart';

class FloodListingController extends GetxController {
  static FloodListingController ensure() {
    final existing = maybeFind();
    if (existing != null) return existing;
    return Get.put(FloodListingController());
  }

  static FloodListingController? maybeFind() {
    final isRegistered = Get.isRegistered<FloodListingController>();
    if (!isRegistered) return null;
    return Get.find<FloodListingController>();
  }

  // Flood gönderiler listesi
  RxList<PostsModel> floods = <PostsModel>[].obs;

  // Scroll kontrolcüsü
  final scrollController = ScrollController();

  // Her flood için benzersiz GlobalKey
  final Map<String, GlobalKey> _floodKeys = {};

  // Ekranda ortalanan içeriğin index'i
  final currentVisibleIndex = RxInt(-1);
  final centeredIndex = 0.obs;
  int? lastCenteredIndex;
  String? _pendingCenteredDocId;
  final PostRepository _postRepository = PostRepository.ensure();

  @override
  void onInit() {
    super.onInit();
    _handleOnInit();
  }

  @override
  void onClose() {
    _handleOnClose();
    super.onClose();
  }
}
