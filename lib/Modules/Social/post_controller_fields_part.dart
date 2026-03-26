part of 'post_controller.dart';

class _PostControllerState {
  _PostControllerState({
    required this.postID,
    required this.model,
    required this.fetch_begeniler,
    required this.fetch_begenmemeler,
    required this.fetch_kaydedilenler,
    required this.fetch_yenidenPaylasilanKullanicilar,
  });

  final String postID;
  final PostsModel model;
  final List<String> fetch_begeniler;
  final List<String> fetch_begenmemeler;
  final List<String> fetch_kaydedilenler;
  final List<String> fetch_yenidenPaylasilanKullanicilar;
  final RxInt yorumCount = 0.obs;
  final RxInt pageCounter = 0.obs;
  final RxList<String> begeniler = <String>[].obs;
  final RxList<String> begenmeme = <String>[].obs;
  final RxList<String> kaydedilenler = <String>[].obs;
  final RxList<String> yenidenPaylasilanKullanicilar = <String>[].obs;
  final RxInt goruntuleme = 0.obs;
  final RxInt tekrarPaylasilmaSayisi = 0.obs;
  final RxBool gizlendi = false.obs;
  final RxBool arsivlendi = false.obs;
  final RxString ilkPaylasanPfImage = ''.obs;
  final RxString ilkPaylasanNickname = ''.obs;
  final RxString ilkPaylasanUserID = ''.obs;
  final PostRepository postRepository = PostRepository.ensure();
}

extension PostControllerFieldsPart on PostController {
  String get postID => _state.postID;
  PostsModel get model => _state.model;
  List<String> get fetch_begeniler => _state.fetch_begeniler;
  List<String> get fetch_begenmemeler => _state.fetch_begenmemeler;
  List<String> get fetch_kaydedilenler => _state.fetch_kaydedilenler;
  List<String> get fetch_yenidenPaylasilanKullanicilar =>
      _state.fetch_yenidenPaylasilanKullanicilar;
  RxInt get yorumCount => _state.yorumCount;
  RxInt get pageCounter => _state.pageCounter;
  RxList<String> get begeniler => _state.begeniler;
  RxList<String> get begenmeme => _state.begenmeme;
  RxList<String> get kaydedilenler => _state.kaydedilenler;
  RxList<String> get yenidenPaylasilanKullanicilar =>
      _state.yenidenPaylasilanKullanicilar;
  RxInt get goruntuleme => _state.goruntuleme;
  RxInt get tekrarPaylasilmaSayisi => _state.tekrarPaylasilmaSayisi;
  RxBool get gizlendi => _state.gizlendi;
  RxBool get arsivlendi => _state.arsivlendi;
  RxString get ilkPaylasanPfImage => _state.ilkPaylasanPfImage;
  RxString get ilkPaylasanNickname => _state.ilkPaylasanNickname;
  RxString get ilkPaylasanUserID => _state.ilkPaylasanUserID;
  PostRepository get _postRepository => _state.postRepository;
}
