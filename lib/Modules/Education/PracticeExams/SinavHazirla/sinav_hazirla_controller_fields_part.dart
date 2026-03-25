part of 'sinav_hazirla_controller.dart';

class _SinavHazirlaControllerState {
  final sinavIsmi = TextEditingController().obs;
  final aciklama = TextEditingController().obs;
  final startDate = DateTime.now().obs;
  final selectedTime = const TimeOfDay(hour: 15, minute: 0).obs;
  final sinavTuru = 'TYT'.obs;
  final currentDersler = <String>[].obs;
  final kpssSecilenLisans = 'Ortaöğretim'.obs;
  final yanlisDogruyuGotururMu = false.obs;
  final public = true.obs;
  final sure = 140.obs;
  final showCalendar = false.obs;
  final showSureler = false.obs;
  final cover = Rx<File?>(null);
  final isLoadingImage = false.obs;
  final isSaving = false.obs;
  final soruSayisiTextFields = <TextEditingController>[].obs;
  final docID = DateTime.now().millisecondsSinceEpoch.toString().obs;
}

extension SinavHazirlaControllerFieldsPart on SinavHazirlaController {
  Rx<TextEditingController> get sinavIsmi => _state.sinavIsmi;
  Rx<TextEditingController> get aciklama => _state.aciklama;
  Rx<DateTime> get startDate => _state.startDate;
  Rx<TimeOfDay> get selectedTime => _state.selectedTime;
  RxString get sinavTuru => _state.sinavTuru;
  RxList<String> get currentDersler => _state.currentDersler;
  RxString get kpssSecilenLisans => _state.kpssSecilenLisans;
  RxBool get yanlisDogruyuGotururMu => _state.yanlisDogruyuGotururMu;
  RxBool get public => _state.public;
  RxInt get sure => _state.sure;
  RxBool get showCalendar => _state.showCalendar;
  RxBool get showSureler => _state.showSureler;
  Rx<File?> get cover => _state.cover;
  RxBool get isLoadingImage => _state.isLoadingImage;
  RxBool get isSaving => _state.isSaving;
  RxList<TextEditingController> get soruSayisiTextFields =>
      _state.soruSayisiTextFields;
  RxString get docID => _state.docID;
}
