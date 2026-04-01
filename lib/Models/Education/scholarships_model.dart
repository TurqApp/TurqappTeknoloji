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

  static int _asInt(Object? value) {
    if (value is num) return value.toInt();
    return int.tryParse((value ?? '').toString()) ?? 0;
  }

  static String _asString(Object? value) => (value ?? '').toString();

  static List<String> _cloneStringList(List<String> source) =>
      List<String>.from(source, growable: false);

  static List<String> _asStringList(Object? value) {
    if (value is Iterable) {
      return value.map((item) => item.toString()).toList(growable: false);
    }
    return const <String>[];
  }

  ScholarshipsModel({
    required this.aciklama,
    required this.baslik,
    required List<String> basvuranlar,
    required List<String> begeniler,
    required this.cinsiyet,
    required this.endTimeStamp,
    required List<String> favoriler,
    required this.firma,
    required List<String> goruntulemeler,
    required this.hedefKitleSecimi,
    required List<String> ikametIlceler,
    required List<String> ikametSehirler,
    required this.img,
    required this.kategori,
    required List<String> kazananlar,
    required this.limit,
    required this.link,
    required List<String> liseSehirler,
    required List<String> liseler,
    required this.miktar,
    required List<String> nufusIlceler,
    required List<String> nufusSehirler,
    required this.okulBilgisi,
    required this.okulTipi,
    required List<String> ortaOkul,
    required List<String> ortaOkulSehirler,
    required this.secim,
    required this.sonDegisiklik,
    required this.timeStamp,
    required List<String> universiteIlceler,
    required List<String> universiteSehirler,
    required List<String> universiteler,
    required List<String> kaydedenler,
    required this.docID,
    this.shortId = '',
    this.shortUrl = '',
  })  : basvuranlar = _cloneStringList(basvuranlar),
        begeniler = _cloneStringList(begeniler),
        favoriler = _cloneStringList(favoriler),
        goruntulemeler = _cloneStringList(goruntulemeler),
        ikametIlceler = _cloneStringList(ikametIlceler),
        ikametSehirler = _cloneStringList(ikametSehirler),
        kazananlar = _cloneStringList(kazananlar),
        liseSehirler = _cloneStringList(liseSehirler),
        liseler = _cloneStringList(liseler),
        nufusIlceler = _cloneStringList(nufusIlceler),
        nufusSehirler = _cloneStringList(nufusSehirler),
        ortaOkul = _cloneStringList(ortaOkul),
        ortaOkulSehirler = _cloneStringList(ortaOkulSehirler),
        universiteIlceler = _cloneStringList(universiteIlceler),
        universiteSehirler = _cloneStringList(universiteSehirler),
        universiteler = _cloneStringList(universiteler),
        kaydedenler = _cloneStringList(kaydedenler);

  factory ScholarshipsModel.fromSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ScholarshipsModel(
      aciklama: _asString(data['aciklama']),
      baslik: _asString(data['baslik']),
      basvuranlar: _asStringList(data['basvuranlar']),
      begeniler: _asStringList(data['begeniler']),
      cinsiyet: _asString(data['cinsiyet']),
      endTimeStamp: _asInt(data['endTimeStamp']),
      favoriler: _asStringList(data['favoriler']),
      firma: _asString(data['firma']),
      goruntulemeler: _asStringList(data['goruntulemeler']),
      hedefKitleSecimi: _asString(data['hedefKitleSecimi']),
      ikametIlceler: _asStringList(data['ikametIlceler']),
      ikametSehirler: _asStringList(data['ikametSehirler']),
      img: _asString(data['img']),
      kategori: _asString(data['kategori']),
      kazananlar: _asStringList(data['kazananlar']),
      limit: _asInt(data['limit']),
      link: _asString(data['link']),
      liseSehirler: _asStringList(data['liseSehirler']),
      liseler: _asStringList(data['liseler']),
      miktar: _asInt(data['miktar']),
      nufusIlceler: _asStringList(data['nufusIlceler']),
      nufusSehirler: _asStringList(data['nufusSehirler']),
      okulBilgisi: _asString(data['okulBilgisi']),
      okulTipi: _asString(data['okulTipi']),
      ortaOkul: _asStringList(data['ortaOkul']),
      ortaOkulSehirler: _asStringList(data['ortaOkulSehirler']),
      secim: _asInt(data['secim']),
      sonDegisiklik: _asInt(data['sonDegisiklik']),
      timeStamp: _asInt(data['timeStamp']),
      universiteIlceler: _asStringList(data['universiteIlceler']),
      universiteSehirler: _asStringList(data['universiteSehirler']),
      universiteler: _asStringList(data['universiteler']),
      kaydedenler: _asStringList(data['kaydedenler']),
      docID: doc.id,
      shortId: _asString(data['shortId']),
      shortUrl: _asString(data['shortUrl']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'aciklama': aciklama,
      'baslik': baslik,
      'basvuranlar': _cloneStringList(basvuranlar),
      'begeniler': _cloneStringList(begeniler),
      'cinsiyet': cinsiyet,
      'endTimeStamp': endTimeStamp,
      'favoriler': _cloneStringList(favoriler),
      'firma': firma,
      'goruntulemeler': _cloneStringList(goruntulemeler),
      'hedefKitleSecimi': hedefKitleSecimi,
      'ikametIlceler': _cloneStringList(ikametIlceler),
      'ikametSehirler': _cloneStringList(ikametSehirler),
      'img': img,
      'kategori': kategori,
      'kazananlar': _cloneStringList(kazananlar),
      'limit': limit,
      'link': link,
      'liseSehirler': _cloneStringList(liseSehirler),
      'liseler': _cloneStringList(liseler),
      'miktar': miktar,
      'nufusIlceler': _cloneStringList(nufusIlceler),
      'nufusSehirler': _cloneStringList(nufusSehirler),
      'okulBilgisi': okulBilgisi,
      'okulTipi': okulTipi,
      'ortaOkul': _cloneStringList(ortaOkul),
      'ortaOkulSehirler': _cloneStringList(ortaOkulSehirler),
      'secim': secim,
      'sonDegisiklik': sonDegisiklik,
      'timeStamp': timeStamp,
      'universiteIlceler': _cloneStringList(universiteIlceler),
      'universiteSehirler': _cloneStringList(universiteSehirler),
      'universiteler': _cloneStringList(universiteler),
      'kaydedenler': _cloneStringList(kaydedenler),
      'shortId': shortId,
      'shortUrl': shortUrl,
    };
  }
}
