class TutoringModel {
  final String docID;
  final String aciklama;
  final String baslik;
  final String brans;
  final String cinsiyet;
  final List<String> dersYeri;
  final num end;
  final List<String> favorites;
  final num fiyat;
  final List<String>? imgs;
  final String ilce;
  final bool onayVerildi;
  final String sehir;
  final bool telefon;
  final num timeStamp;
  final String userID;
  final bool whatsapp;

  TutoringModel({
    required this.docID,
    required this.aciklama,
    required this.baslik,
    required this.brans,
    required this.cinsiyet,
    required this.dersYeri,
    required this.end,
    required this.favorites,
    required this.fiyat,
    required this.imgs,
    required this.ilce,
    required this.onayVerildi,
    required this.sehir,
    required this.telefon,
    required this.timeStamp,
    required this.userID,
    required this.whatsapp,
  });

  factory TutoringModel.fromJson(Map<String, dynamic> json, String documentId) {
    return TutoringModel(
      docID: documentId,
      aciklama: json['aciklama'] as String? ?? '',
      baslik: json['baslik'] as String? ?? '',
      brans: json['brans'] as String? ?? '',
      cinsiyet: json['cinsiyet'] as String? ?? '',
      dersYeri: (json['dersYeri'] as List<dynamic>?)?.cast<String>() ?? [],
      end: json['end'] as num? ?? 0,
      favorites: (json['favorites'] as List<dynamic>?)?.cast<String>() ?? [],
      fiyat: json['fiyat'] as num? ?? 0,
      imgs: (json['imgs'] as List<dynamic>?)?.cast<String>(),
      ilce: json['ilce'] as String? ?? '',
      onayVerildi: json['onayVerildi'] as bool? ?? false,
      sehir: json['sehir'] as String? ?? '',
      telefon: json['telefon'] as bool? ?? false,
      timeStamp: json['timeStamp'] as num? ?? 0,
      userID: json['userID'] as String? ?? '',
      whatsapp: json['whatsapp'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'aciklama': aciklama,
      'baslik': baslik,
      'brans': brans,
      'cinsiyet': cinsiyet,
      'dersYeri': dersYeri,
      'end': end,
      'favorites': favorites,
      'fiyat': fiyat,
      'imgs': imgs,
      'ilce': ilce,
      'onayVerildi': onayVerildi,
      'sehir': sehir,
      'telefon': telefon,
      'timeStamp': timeStamp,
      'userID': userID,
      'whatsapp': whatsapp,
    };
  }
}
