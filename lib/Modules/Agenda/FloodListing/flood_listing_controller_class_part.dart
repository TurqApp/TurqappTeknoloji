part of 'flood_listing_controller.dart';

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

  RxList<PostsModel> floods = <PostsModel>[].obs;
  final scrollController = ScrollController();
  final Map<String, GlobalKey> _floodKeys = {};
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
