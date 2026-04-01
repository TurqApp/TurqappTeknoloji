part of 'create_book_controller.dart';

extension CreateBookControllerFormPart on CreateBookController {
  void _handleControllerInit() {
    unawaited(_prefillIfEditing());
  }

  void addItem() {
    list.add(
      CevapAnahtariHazirlikModel(
        baslik: 'Deneme ${list.length + 1}',
        dogruCevaplar: [],
        sira: list.length + 1,
      ),
    );
  }

  void removeLastItem() {
    if (list.isNotEmpty) {
      list.removeLast();
    }
  }

  void navigateToCevapAnahtari(
    BuildContext context,
    CevapAnahtariHazirlikModel model,
  ) {
    Get.to(
      () => CreateBookAnswerKey(
        model: model,
        onBack: () {
          list.refresh();
        },
      ),
    );
  }

  bool isFormValid() {
    return imageFile.value != null &&
        baslikController.text.isNotEmpty &&
        yayinEviController.text.isNotEmpty &&
        basimTarihiController.text.isNotEmpty &&
        sinavTuru.value.isNotEmpty;
  }

  Future<void> _prefillIfEditing() async {
    final book = existingBook;
    if (book == null) return;
    baslikController.text = book.baslik;
    yayinEviController.text = book.yayinEvi;
    basimTarihiController.text = book.basimTarihi;
    sinavTuru.value = book.sinavTuru;

    final answers = await _bookletRepository.fetchAnswerKeys(
      book.docID,
      preferCache: true,
    );
    final items = answers.map((item) {
      final data = Map<String, dynamic>.from(
        item['data'] ?? const <String, dynamic>{},
      );
      return CevapAnahtariHazirlikModel(
        baslik: (data['baslik'] ?? '').toString(),
        dogruCevaplar: List<String>.from(data['dogruCevaplar'] ?? const []),
        sira: (data['sira'] as num?)?.toInt() ?? 0,
      );
    }).toList()
      ..sort((a, b) => a.sira.compareTo(b.sira));
    list.assignAll(items);
  }
}
