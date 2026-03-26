part of 'post_controller.dart';

class PostController extends GetxController {
  final _PostControllerState _state;

  PostController({
    required String postID,
    required PostsModel model,
    required List<String> fetch_begeniler,
    required List<String> fetch_begenmemeler,
    required List<String> fetch_kaydedilenler,
    required List<String> fetch_yenidenPaylasilanKullanicilar,
  }) : _state = _buildPostControllerState(
          postID: postID,
          model: model,
          fetchBegeniler: fetch_begeniler,
          fetchBegenmemeler: fetch_begenmemeler,
          fetchKaydedilenler: fetch_kaydedilenler,
          fetchYenidenPaylasilanKullanicilar:
              fetch_yenidenPaylasilanKullanicilar,
        );

  @override
  void onInit() {
    super.onInit();
    _handlePostControllerInit(this);
  }
}
