part of 'post_controller_library.dart';

abstract class _PostControllerBase extends GetxController {
  _PostControllerBase({
    required String postID,
    required PostsModel model,
    required List<String> fetchBegeniler,
    required List<String> fetchBegenmemeler,
    required List<String> fetchKaydedilenler,
    required List<String> fetchYenidenPaylasilanKullanicilar,
  }) : _state = _buildPostControllerState(
          postID: postID,
          model: model,
          fetchBegeniler: fetchBegeniler,
          fetchBegenmemeler: fetchBegenmemeler,
          fetchKaydedilenler: fetchKaydedilenler,
          fetchYenidenPaylasilanKullanicilar:
              fetchYenidenPaylasilanKullanicilar,
        );

  final _PostControllerState _state;

  @override
  void onInit() {
    super.onInit();
    _handlePostControllerInit(this as PostController);
  }
}
