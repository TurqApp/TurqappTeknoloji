part of 'tutoring_detail_controller_library.dart';

TutoringModel buildEmptyTutoringModel() {
  return TutoringModel(
    docID: '',
    aciklama: '',
    baslik: '',
    brans: '',
    cinsiyet: '',
    dersYeri: [],
    end: 0,
    favorites: [],
    fiyat: 0,
    ilce: '',
    onayVerildi: false,
    sehir: '',
    telefon: false,
    timeStamp: 0,
    userID: '',
    whatsapp: false,
    imgs: null,
  );
}
