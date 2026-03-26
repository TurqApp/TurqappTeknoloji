part of 'optics_and_books_published_controller_library.dart';

extension _OpticsAndBooksPublishedControllerDataX
    on OpticsAndBooksPublishedController {
  bool _sameBookletEntries(
    List<BookletModel> current,
    List<BookletModel> next,
  ) {
    final currentKeys = current
        .map(
          (item) => [
            item.docID,
            item.baslik,
            item.sinavTuru,
            item.yayinEvi,
            item.basimTarihi,
            item.dil,
            item.timeStamp,
            item.viewCount,
            item.cover,
          ].join('::'),
        )
        .toList(growable: false);
    final nextKeys = next
        .map(
          (item) => [
            item.docID,
            item.baslik,
            item.sinavTuru,
            item.yayinEvi,
            item.basimTarihi,
            item.dil,
            item.timeStamp,
            item.viewCount,
            item.cover,
          ].join('::'),
        )
        .toList(growable: false);
    return listEquals(currentKeys, nextKeys);
  }

  bool _sameOpticalEntries(
    List<OpticalFormModel> current,
    List<OpticalFormModel> next,
  ) {
    final currentKeys = current
        .map(
          (item) => [
            item.docID,
            item.name,
            item.userID,
            item.cevaplar.length,
            item.max,
            item.baslangic,
            item.bitis,
            item.kisitlama,
          ].join('::'),
        )
        .toList(growable: false);
    final nextKeys = next
        .map(
          (item) => [
            item.docID,
            item.name,
            item.userID,
            item.cevaplar.length,
            item.max,
            item.baslangic,
            item.bitis,
            item.kisitlama,
          ].join('::'),
        )
        .toList(growable: false);
    return listEquals(currentKeys, nextKeys);
  }
}
