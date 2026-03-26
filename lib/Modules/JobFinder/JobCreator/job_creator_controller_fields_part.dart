part of 'job_creator_controller.dart';

class _JobCreatorShellState {
  final cityDirectoryService = CityDirectoryService.ensure();
  final selection = 0.obs;
  final isSubmitting = false.obs;
  final brand = TextEditingController();
  final about = TextEditingController();
  final isTanimi = TextEditingController();
  final maas1 = TextEditingController();
  final maas2 = TextEditingController();
  final calismaSaatiBaslangic = TextEditingController();
  final calismaSaatiBitis = TextEditingController();
  final basvuruSayisi = TextEditingController(text: '0');
  final selectedCalismaTuruList = <String>[].obs;
  final selectedCalismaGunleri = <String>[].obs;
  final selectedYanHaklar = <String>[].obs;
  final choices = _JobCreatorChoiceLists();
  final sehirlerVeIlcelerData = <CitiesModel>[].obs;
  final meslek = ''.obs;
  final ilanBasligi = TextEditingController();
  final pozisyonSayisi = TextEditingController(text: '1');
  final sehir = ''.obs;
  final ilce = ''.obs;
  final adres = ''.obs;
  final lat = 0.0.obs;
  final long = 0.0.obs;
  final maasOpen = true.obs;
  final sehirler = <String>[].obs;
  final mediaState = _JobCreatorMediaState();
  final runtimeState = _JobCreatorRuntimeState();
}

extension JobCreatorControllerFieldsPart on JobCreatorController {
  CityDirectoryService get _cityDirectoryService =>
      _shellState.cityDirectoryService;
  RxInt get selection => _shellState.selection;
  RxBool get isSubmitting => _shellState.isSubmitting;
  TextEditingController get brand => _shellState.brand;
  TextEditingController get about => _shellState.about;
  TextEditingController get isTanimi => _shellState.isTanimi;
  TextEditingController get maas1 => _shellState.maas1;
  TextEditingController get maas2 => _shellState.maas2;
  TextEditingController get calismaSaatiBaslangic =>
      _shellState.calismaSaatiBaslangic;
  TextEditingController get calismaSaatiBitis => _shellState.calismaSaatiBitis;
  TextEditingController get basvuruSayisi => _shellState.basvuruSayisi;
  RxList<String> get selectedCalismaTuruList =>
      _shellState.selectedCalismaTuruList;
  RxList<String> get selectedCalismaGunleri =>
      _shellState.selectedCalismaGunleri;
  RxList<String> get selectedYanHaklar => _shellState.selectedYanHaklar;
  _JobCreatorChoiceLists get _choices => _shellState.choices;
  RxList<CitiesModel> get sehirlerVeIlcelerData =>
      _shellState.sehirlerVeIlcelerData;
  RxString get meslek => _shellState.meslek;
  TextEditingController get ilanBasligi => _shellState.ilanBasligi;
  TextEditingController get pozisyonSayisi => _shellState.pozisyonSayisi;
  RxString get sehir => _shellState.sehir;
  RxString get ilce => _shellState.ilce;
  RxString get adres => _shellState.adres;
  RxDouble get lat => _shellState.lat;
  RxDouble get long => _shellState.long;
  RxBool get maasOpen => _shellState.maasOpen;
  RxList<String> get sehirler => _shellState.sehirler;
  _JobCreatorMediaState get _mediaState => _shellState.mediaState;
  _JobCreatorRuntimeState get _runtimeState => _shellState.runtimeState;
  Rx<Uint8List?> get croppedImage => _mediaState.croppedImage;
}
