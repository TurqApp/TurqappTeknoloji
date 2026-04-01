part of 'post_controller_library.dart';

class PostController extends _PostControllerBase {
  PostController({
    required super.postID,
    required super.model,
    required List<String> fetch_begeniler,
    required List<String> fetch_begenmemeler,
    required List<String> fetch_kaydedilenler,
    required List<String> fetch_yenidenPaylasilanKullanicilar,
  }) : super(
          fetchBegeniler: fetch_begeniler,
          fetchBegenmemeler: fetch_begenmemeler,
          fetchKaydedilenler: fetch_kaydedilenler,
          fetchYenidenPaylasilanKullanicilar:
              fetch_yenidenPaylasilanKullanicilar,
        );
}
