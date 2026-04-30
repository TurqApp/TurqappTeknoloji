part of 'booklet_answer_controller.dart';

extension BookletAnswerControllerActionsPart on BookletAnswerController {
  void updateAnswer(int index, String answer) {
    cevaplar[index] = answer;
  }

  Future<void> finishTest() async {
    var correct = 0;
    var wrong = 0;

    for (int i = 0; i < model.dogruCevaplar.length; i++) {
      if (cevaplar[i] == model.dogruCevaplar[i]) {
        correct++;
      } else if (cevaplar[i] != model.dogruCevaplar[i] && cevaplar[i] != '') {
        wrong++;
      }
    }

    final total = model.dogruCevaplar.length;
    final empty = total - (correct + wrong);
    final score = (correct / total) * 100;
    final net = correct - (wrong / 4.0);

    correctCount.value = correct;
    wrongCount.value = wrong;
    emptyCount.value = empty;
    scorePercent.value = score;
    netScore.value = net;

    try {
      await ensureBookletRepository().saveBookletAnswerResult(
        userId: CurrentUserService.instance.effectiveUserId,
        data: {
          'timeStamp': DateTime.now().millisecondsSinceEpoch,
          'kitapcikID': anaModel.docID,
          'baslik': model.baslik,
          'cevaplar': cevaplar,
          'dogruCevaplar': model.dogruCevaplar,
          'dogru': correct,
          'yanlis': wrong,
          'bos': empty,
          'puan': score,
          'net': net,
        },
      );
      completed.value = true;
    } catch (_) {}
  }
}
