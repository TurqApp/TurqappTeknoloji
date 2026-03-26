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
  }) : _state = _PostControllerState(
          postID: postID,
          model: model,
          fetch_begeniler: fetch_begeniler,
          fetch_begenmemeler: fetch_begenmemeler,
          fetch_kaydedilenler: fetch_kaydedilenler,
          fetch_yenidenPaylasilanKullanicilar:
              fetch_yenidenPaylasilanKullanicilar,
        );

  @override
  void onInit() {
    super.onInit();
    _initializePostState(this);
    begeniler.assignAll(fetch_begeniler);
    begenmeme.assignAll(fetch_begenmemeler);
    kaydedilenler.assignAll(fetch_kaydedilenler);
    yenidenPaylasilanKullanicilar
        .assignAll(fetch_yenidenPaylasilanKullanicilar);
    gizlendi.value = model.gizlendi;
    arsivlendi.value = model.arsiv;
  }
}
