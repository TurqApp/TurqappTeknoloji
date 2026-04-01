part of 'job_creator_controller.dart';

const List<String> _jobCreatorWorkTypes = <String>[
  'Tam Zamanlı',
  'Yarı Zamanlı',
  'Part-Time',
  'Uzaktan',
  'Hibrit',
];
const List<String> _jobCreatorWorkDays = <String>[
  'Pazartesi',
  'Salı',
  'Çarşamba',
  'Perşembe',
  'Cuma',
  'Cumartesi',
  'Pazar',
];
const List<String> _jobCreatorBenefits = <String>[
  'Yemek',
  'Yol Ücreti',
  'Servis',
  'Prim',
  'Özel Sağlık Sigortası',
  'Bireysel Emeklilik',
  'Esnek Çalışma Saatleri',
  'Uzaktan Çalışma',
];
const String _jobCreatorLoaderTag = 'job_creator_loader';

class _JobCreatorChoiceLists {
  final List<String> calismaTuruList = List<String>.of(_jobCreatorWorkTypes);
  final List<String> calismaGunleriList = List<String>.of(_jobCreatorWorkDays);
  final List<String> yanHaklarList = List<String>.of(_jobCreatorBenefits);
}

class _JobCreatorMediaState {
  final cropController = CropController();
  final picker = ImagePicker();
  final Rx<File?> selectedImage = Rx<File?>(null);
  final Rx<Uint8List?> croppedImage = Rx<Uint8List?>(null);
}

class _JobCreatorRuntimeState {
  bool ownsLoader = false;
}

extension _JobCreatorControllerSupportX on JobCreatorController {
  String get _currentUid => CurrentUserService.instance.effectiveUserId;
  String get loaderTag => _jobCreatorLoaderTag;
  List<String> get calismaTuruList => _choices.calismaTuruList;
  List<String> get calismaGunleriList => _choices.calismaGunleriList;
  List<String> get yanHaklarList => _choices.yanHaklarList;
  CropController get cropController => _mediaState.cropController;
  ImagePicker get picker => _mediaState.picker;
  Rx<File?> get selectedImage => _mediaState.selectedImage;
  bool get _ownsLoader => _runtimeState.ownsLoader;
  set _ownsLoader(bool value) => _runtimeState.ownsLoader = value;

  String localizedWorkTypes(List<String> values) =>
      values.map(localizeJobWorkType).join(', ');

  String localizedWorkDays(List<String> values) =>
      values.map(localizeJobDay).join(', ');

  String localizedBenefits(List<String> values) =>
      values.map(localizeJobBenefit).join(', ');

  int parseMoneyInput(String value) {
    return int.tryParse(value.replaceAll('.', '').trim()) ?? 0;
  }

  String _formatMoneyInput(int value) {
    final raw = value.toString();
    final reversed = raw.split('').reversed.join();
    final chunks = <String>[];
    for (var i = 0; i < reversed.length; i += 3) {
      final end = (i + 3 < reversed.length) ? i + 3 : reversed.length;
      chunks.add(reversed.substring(i, end));
    }
    return chunks
        .map((chunk) => chunk.split('').reversed.join())
        .toList()
        .reversed
        .join('.');
  }

  void handleOnClose() {
    brand.dispose();
    about.dispose();
    isTanimi.dispose();
    maas1.dispose();
    maas2.dispose();
    calismaSaatiBaslangic.dispose();
    calismaSaatiBitis.dispose();
    basvuruSayisi.dispose();
    ilanBasligi.dispose();
    pozisyonSayisi.dispose();
    final currentLoader = GlobalLoaderController.maybeFind(tag: loaderTag);
    if (_ownsLoader && currentLoader != null) {
      Get.delete<GlobalLoaderController>(tag: loaderTag);
    }
  }
}
