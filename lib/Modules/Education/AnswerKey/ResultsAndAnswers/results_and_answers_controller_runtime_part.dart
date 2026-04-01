part of 'results_and_answers_controller.dart';

Future<void> _getResultsAndAnswers(
    ResultsAndAnswersController controller) async {
  final fetchedCevaplar =
      await controller._opticalFormRepository.fetchUserAnswers(
    controller.model.docID,
    CurrentUserService.instance.effectiveUserId,
    preferCache: true,
  );
  controller.cevaplar.assignAll(fetchedCevaplar);
  _calculateResultsAndAnswers(controller);
}

void _calculateResultsAndAnswers(ResultsAndAnswersController controller) {
  int dogru = 0;
  int yanlis = 0;
  int bos = 0;

  for (int i = 0; i < controller.model.cevaplar.length; i++) {
    final dogruCevap = controller.model.cevaplar[i];
    final kullaniciCevap =
        controller.cevaplar.length > i ? controller.cevaplar[i] : "";

    if (kullaniciCevap.isEmpty) {
      bos++;
    } else if (kullaniciCevap == dogruCevap) {
      dogru++;
    } else {
      yanlis++;
    }
  }

  controller.dogruSayisi.value = dogru;
  controller.yanlisSayisi.value = yanlis;
  controller.bosSayisi.value = bos;
  controller.puan.value =
      ((100 / controller.model.cevaplar.length) * dogru).toInt();
}
