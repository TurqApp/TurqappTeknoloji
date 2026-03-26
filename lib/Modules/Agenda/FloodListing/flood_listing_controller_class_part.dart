part of 'flood_listing_controller.dart';

class FloodListingController extends GetxController {
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
