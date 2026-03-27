import 'package:cloud_firestore/cloud_firestore.dart';

class ScholarshipsModel {
  final String aciklama;
  final String baslik;
  final List<String> basvuranlar;
  final List<String> begeniler;
  final String cinsiyet;
  final int endTimeStamp;
  final List<String> favoriler;
  final String firma;
  final List<String> goruntulemeler;
  final String hedefKitleSecimi;
  final List<String> ikametIlceler;
  final List<String> ikametSehirler;
  final String img;
  final String kategori;
  final List<String> kazananlar;
  final int limit;
  final String link;
  final List<String> liseSehirler;
  final List<String> liseler;
  final int miktar;
  final List<String> nufusIlceler;
  final List<String> nufusSehirler;
  final String okulBilgisi;
  final String okulTipi;
  final List<String> ortaOkul;
  final List<String> ortaOkulSehirler;
  final int secim;
  final int sonDegisiklik;
  final int timeStamp;
  final List<String> universiteIlceler;
  final List<String> universiteSehirler;
  final List<String> universiteler;
  final List<String> kaydedenler;
  final String docID;
  final String shortId;
  final String shortUrl;

  ScholarshipsModel({
    required this.aciklama,
    required this.baslik,
    required this.basvuranlar,
    required this.begeniler,
    required this.cinsiyet,
    required this.endTimeStamp,
    required this.favoriler,
    required this.firma,
    required this.goruntulemeler,
    required this.hedefKitleSecimi,
    required this.ikametIlceler,
    required this.ikametSehirler,
    required this.img,
    required this.kategori,
    required this.kazananlar,
    required this.limit,
    required this.link,
    required this.liseSehirler,
    required this.liseler,
    required this.miktar,
    required this.nufusIlceler,
    required this.nufusSehirler,
    required this.okulBilgisi,
    required this.okulTipi,
    required this.ortaOkul,
    required this.ortaOkulSehirler,
    required this.secim,
    required this.sonDegisiklik,
    required this.timeStamp,
    required this.universiteIlceler,
    required this.universiteSehirler,
    required this.universiteler,
    required this.kaydedenler,
    required this.docID,
    this.shortId = '',
    this.shortUrl = '',
  });

  factory ScholarshipsModel.fromSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ScholarshipsModel(
      aciklama: data['aciklama'] ?? '',
      baslik: data['baslik'] ?? '',
      basvuranlar: List<String>.from(data['basvuranlar'] ?? []),
      begeniler: List<String>.from(data['begeniler'] ?? []),
      cinsiyet: data['cinsiyet'] ?? '',
      endTimeStamp: data['endTimeStamp'] ?? 0,
      favoriler: List<String>.from(data['favoriler'] ?? []),
      firma: data['firma'] ?? '',
      goruntulemeler: List<String>.from(data['goruntulemeler'] ?? []),
      hedefKitleSecimi: data['hedefKitleSecimi'] ?? '',
      ikametIlceler: List<String>.from(data['ikametIlceler'] ?? []),
      ikametSehirler: List<String>.from(data['ikametSehirler'] ?? []),
      img: data['img'] ?? '',
      kategori: data['kategori'] ?? '',
      kazananlar: List<String>.from(data['kazananlar'] ?? []),
      limit: data['limit'] ?? 0,
      link: data['link'] ?? '',
      liseSehirler: List<String>.from(data['liseSehirler'] ?? []),
      liseler: List<String>.from(data['liseler'] ?? []),
      miktar: data['miktar'] ?? 0,
      nufusIlceler: List<String>.from(data['nufusIlceler'] ?? []),
      nufusSehirler: List<String>.from(data['nufusSehirler'] ?? []),
      okulBilgisi: data['okulBilgisi'] ?? '',
      okulTipi: data['okulTipi'] ?? '',
      ortaOkul: List<String>.from(data['ortaOkul'] ?? []),
      ortaOkulSehirler: List<String>.from(data['ortaOkulSehirler'] ?? []),
      secim: data['secim'] ?? 0,
      sonDegisiklik: data['sonDegisiklik'] ?? 0,
      timeStamp: data['timeStamp'] ?? 0,
      universiteIlceler: List<String>.from(data['universiteIlceler'] ?? []),
      universiteSehirler: List<String>.from(data['universiteSehirler'] ?? []),
      universiteler: List<String>.from(data['universiteler'] ?? []),
      kaydedenler: List<String>.from(data['kaydedenler'] ?? []),
      docID: doc.id,
      shortId: data['shortId'] ?? '',
      shortUrl: data['shortUrl'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'aciklama': aciklama,
      'baslik': baslik,
      'basvuranlar': basvuranlar,
      'begeniler': begeniler,
      'cinsiyet': cinsiyet,
      'endTimeStamp': endTimeStamp,
      'favoriler': favoriler,
      'firma': firma,
      'goruntulemeler': goruntulemeler,
      'hedefKitleSecimi': hedefKitleSecimi,
      'ikametIlceler': ikametIlceler,
      'ikametSehirler': ikametSehirler,
      'img': img,
      'kategori': kategori,
      'kazananlar': kazananlar,
      'limit': limit,
      'link': link,
      'liseSehirler': liseSehirler,
      'liseler': liseler,
      'miktar': miktar,
      'nufusIlceler': nufusIlceler,
      'nufusSehirler': nufusSehirler,
      'okulBilgisi': okulBilgisi,
      'okulTipi': okulTipi,
      'ortaOkul': ortaOkul,
      'ortaOkulSehirler': ortaOkulSehirler,
      'secim': secim,
      'sonDegisiklik': sonDegisiklik,
      'timeStamp': timeStamp,
      'universiteIlceler': universiteIlceler,
      'universiteSehirler': universiteSehirler,
      'universiteler': universiteler,
      'kaydedenler': kaydedenler,
      'shortId': shortId,
      'shortUrl': shortUrl,
    };
  }
}
