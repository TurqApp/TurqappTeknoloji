part of 'cikmis_sorular_preview.dart';

extension CikmisSorularPreviewDataPart on _CikmisSorularPreviewState {
  String _formatTime(int hours, int minutes, int seconds) {
    return "${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}";
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateViewState(() {
        _seconds++;
        if (_seconds >= 60) {
          _seconds = 0;
          _minutes++;
          if (_minutes >= 60) {
            _minutes = 0;
            _hours++;
          }
        }
      });
    });
  }

  Future<void> _fetchData() async {
    final docId = await _repository.findQuestionDocId(
      anaBaslik: widget.anaBaslik,
      sinavTuru: widget.sinavTuru,
      yil: widget.yil,
      baslik2: widget.baslik2,
      baslik3: widget.baslik3,
    );
    if (docId != null && docId.isNotEmpty) {
      await _getData(docId);
    }
  }

  Future<void> _getData(String docID) async {
    final questions = await _repository.fetchQuestionItems(docID);
    if (!mounted) return;
    final localDersler = <String>[];
    final answers = <String>[];
    final selected = <String>[];
    for (final question in questions) {
      answers.add(question.dogruCevap);
      selected.add('');
      if (!localDersler.contains(question.ders)) {
        localDersler.add(question.ders);
      }
    }
    _updateViewState(() {
      list = questions;
      dogruCevaplarList = answers;
      selectedAnswers = selected;
      dersler = localDersler;
      docIDCopy = docID;
    });
  }
}
