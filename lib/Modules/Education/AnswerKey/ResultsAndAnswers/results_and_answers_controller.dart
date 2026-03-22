import 'package:get/get.dart';
import 'package:turqappv2/Core/Repositories/optical_form_repository.dart';
import 'package:turqappv2/Models/Education/optical_form_model.dart';
import 'package:turqappv2/Services/current_user_service.dart';

class ResultsAndAnswersController extends GetxController {
  static ResultsAndAnswersController ensure(
    OpticalFormModel model, {
    String? tag,
    bool permanent = false,
  }) {
    final existing = maybeFind(tag: tag);
    if (existing != null) return existing;
    return Get.put(
      ResultsAndAnswersController(model),
      tag: tag,
      permanent: permanent,
    );
  }

  static ResultsAndAnswersController? maybeFind({String? tag}) {
    final isRegistered =
        Get.isRegistered<ResultsAndAnswersController>(tag: tag);
    if (!isRegistered) return null;
    return Get.find<ResultsAndAnswersController>(tag: tag);
  }

  final OpticalFormRepository _opticalFormRepository =
      OpticalFormRepository.ensure();
  final OpticalFormModel model;
  final cevaplar = <String>[].obs;
  final dogruSayisi = 0.obs;
  final yanlisSayisi = 0.obs;
  final bosSayisi = 0.obs;
  final puan = 0.obs;

  ResultsAndAnswersController(this.model) {
    getCevaplarim();
  }

  Future<void> getCevaplarim() async {
    final fetchedCevaplar = await _opticalFormRepository.fetchUserAnswers(
      model.docID,
      CurrentUserService.instance.effectiveUserId,
      preferCache: true,
    );
    cevaplar.assignAll(fetchedCevaplar);
    hesaplaDogruYanlisBos();
  }

  void hesaplaDogruYanlisBos() {
    int dogru = 0;
    int yanlis = 0;
    int bos = 0;

    for (int i = 0; i < model.cevaplar.length; i++) {
      String dogruCevap = model.cevaplar[i];
      String kullaniciCevap = cevaplar.length > i ? cevaplar[i] : "";

      if (kullaniciCevap == "") {
        bos++;
      } else if (kullaniciCevap == dogruCevap) {
        dogru++;
      } else {
        yanlis++;
      }
    }

    dogruSayisi.value = dogru;
    yanlisSayisi.value = yanlis;
    bosSayisi.value = bos;
    puan.value = ((100 / model.cevaplar.length) * dogru).toInt();
  }
}
