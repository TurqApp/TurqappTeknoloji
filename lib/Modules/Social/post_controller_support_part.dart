part of 'post_controller.dart';

_PostControllerState _buildPostControllerState({
  required String postID,
  required PostsModel model,
  required List<String> fetchBegeniler,
  required List<String> fetchBegenmemeler,
  required List<String> fetchKaydedilenler,
  required List<String> fetchYenidenPaylasilanKullanicilar,
}) {
  return _PostControllerState(
    postID: postID,
    model: model,
    fetch_begeniler: fetchBegeniler,
    fetch_begenmemeler: fetchBegenmemeler,
    fetch_kaydedilenler: fetchKaydedilenler,
    fetch_yenidenPaylasilanKullanicilar: fetchYenidenPaylasilanKullanicilar,
  );
}

void _handlePostControllerInit(PostController controller) {
  _initializePostState(controller);
  controller.begeniler.assignAll(controller.fetch_begeniler);
  controller.begenmeme.assignAll(controller.fetch_begenmemeler);
  controller.kaydedilenler.assignAll(controller.fetch_kaydedilenler);
  controller.yenidenPaylasilanKullanicilar.assignAll(
    controller.fetch_yenidenPaylasilanKullanicilar,
  );
  controller.gizlendi.value = controller.model.gizlendi;
  controller.arsivlendi.value = controller.model.arsiv;
}
