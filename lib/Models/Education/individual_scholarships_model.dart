class IndividualScholarshipsModel {
  final String aciklama;
  final String shortDescription;
  final List<String> altEgitimKitlesi;
  final List<String> aylar;
  final List<String> basvurular;
  final String baslangicTarihi;
  final String baslik;
  final String basvuruKosullari;
  final String basvuruURL;
  final String basvuruYapilacakYer;
  final List<String> begeniler;
  final List<String> belgeler;
  final String bitisTarihi;
  final String bursVeren;
  final String egitimKitlesi;
  final String geriOdemeli;
  final List<String> goruntuleme;
  final String hedefKitle;
  final List<String> ilceler;
  final String img;
  final String img2;
  final List<String> kaydedenler;
  final List<String> kaydedilenler;
  final List<String> liseOrtaOkulIlceler;
  final List<String> liseOrtaOkulSehirler;
  final String logo;
  final String mukerrerDurumu;
  final String ogrenciSayisi;
  final List<String> sehirler;
  final int timeStamp;
  final String tutar;
  final List<String> universiteler;
  final String userID;
  final String website;
  final String lisansTuru;
  final String template;
  final String ulke;

  static List<String> _cloneStringList(List<String> source) =>
      List<String>.from(source, growable: false);

  IndividualScholarshipsModel({
    required this.aciklama,
    required this.shortDescription,
    required List<String> altEgitimKitlesi,
    required List<String> aylar,
    required List<String> basvurular,
    required this.baslangicTarihi,
    required this.baslik,
    required this.basvuruKosullari,
    required this.basvuruURL,
    required this.basvuruYapilacakYer,
    required List<String> begeniler,
    required List<String> belgeler,
    required this.bitisTarihi,
    required this.bursVeren,
    required this.egitimKitlesi,
    required this.geriOdemeli,
    required List<String> goruntuleme,
    required this.hedefKitle,
    required List<String> ilceler,
    required this.img,
    required this.img2,
    required List<String> kaydedenler,
    required List<String> kaydedilenler,
    required List<String> liseOrtaOkulIlceler,
    required List<String> liseOrtaOkulSehirler,
    required this.logo,
    required this.mukerrerDurumu,
    required this.ogrenciSayisi,
    required List<String> sehirler,
    required this.timeStamp,
    required this.tutar,
    required List<String> universiteler,
    required this.userID,
    required this.website,
    required this.lisansTuru,
    required this.template,
    required this.ulke,
  }) : altEgitimKitlesi = _cloneStringList(altEgitimKitlesi),
       aylar = _cloneStringList(aylar),
       basvurular = _cloneStringList(basvurular),
       begeniler = _cloneStringList(begeniler),
       belgeler = _cloneStringList(belgeler),
       goruntuleme = _cloneStringList(goruntuleme),
       ilceler = _cloneStringList(ilceler),
       kaydedenler = _cloneStringList(kaydedenler),
       kaydedilenler = _cloneStringList(kaydedilenler),
       liseOrtaOkulIlceler = _cloneStringList(liseOrtaOkulIlceler),
       liseOrtaOkulSehirler = _cloneStringList(liseOrtaOkulSehirler),
       sehirler = _cloneStringList(sehirler),
       universiteler = _cloneStringList(universiteler);

  factory IndividualScholarshipsModel.fromJson(Map<String, dynamic> json) {
    return IndividualScholarshipsModel(
      aciklama: json['aciklama'] ?? '',
      shortDescription: json['shortDescription'] ??
          json['kisaAciklama'] ??
          json['ozet'] ??
          '',
      altEgitimKitlesi: List<String>.from(json['altEgitimKitlesi'] ?? []),
      aylar: List<String>.from(json['aylar'] ?? []),
      basvurular: List<String>.from(json['basvurular'] ?? []),
      baslangicTarihi: json['baslangicTarihi'] ?? '',
      baslik: json['baslik'] ?? '',
      basvuruKosullari: json['basvuruKosullari'] ?? '',
      basvuruURL: json['basvuruURL'] ?? '',
      basvuruYapilacakYer: json['basvuruYapilacakYer'] ?? '',
      begeniler: List<String>.from(json['begeniler'] ?? []),
      belgeler: List<String>.from(json['belgeler'] ?? []),
      bitisTarihi: json['bitisTarihi'] ?? '',
      bursVeren: json['bursVeren'] ?? '',
      egitimKitlesi: json['egitimKitlesi'] ?? '',
      geriOdemeli: json['geriOdemeli'] ?? '',
      goruntuleme: List<String>.from(json['goruntuleme'] ?? []),
      hedefKitle: json['hedefKitle'] ?? '',
      ilceler: List<String>.from(json['ilceler'] ?? []),
      img: json['img'] ?? '',
      img2: json['img2'] ?? '',
      kaydedenler: List<String>.from(json['kaydedenler'] ?? []),
      kaydedilenler: List<String>.from(json['kaydedilenler'] ?? []),
      liseOrtaOkulIlceler: List<String>.from(json['liseOrtaOkulIlceler'] ?? []),
      liseOrtaOkulSehirler: List<String>.from(
        json['liseOrtaOkulSehirler'] ?? [],
      ),
      logo: json['logo'] ?? '',
      mukerrerDurumu: json['mukerrerDurumu'] ?? '',
      ogrenciSayisi: json['ogrenciSayisi'] ?? '',
      sehirler: List<String>.from(json['sehirler'] ?? []),
      timeStamp: json['timeStamp'] ?? 0,
      tutar: json['tutar'] ?? '',
      universiteler: List<String>.from(json['universiteler'] ?? []),
      userID: json['userID'] ?? '',
      website: json['website'] ?? '',
      lisansTuru: json['lisansTuru'] ?? '',
      template: json['template'] ?? '',
      ulke: json['ulke'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'aciklama': aciklama,
      'altEgitimKitlesi': _cloneStringList(altEgitimKitlesi),
      'aylar': _cloneStringList(aylar),
      'basvurular': _cloneStringList(basvurular),
      'baslangicTarihi': baslangicTarihi,
      'baslik': baslik,
      'basvuruKosullari': basvuruKosullari,
      'basvuruURL': basvuruURL,
      'basvuruYapilacakYer': basvuruYapilacakYer,
      'begeniler': _cloneStringList(begeniler),
      'belgeler': _cloneStringList(belgeler),
      'bitisTarihi': bitisTarihi,
      'bursVeren': bursVeren,
      'egitimKitlesi': egitimKitlesi,
      'geriOdemeli': geriOdemeli,
      'goruntuleme': _cloneStringList(goruntuleme),
      'hedefKitle': hedefKitle,
      'ilceler': _cloneStringList(ilceler),
      'img': img,
      'img2': img2,
      'kaydedenler': _cloneStringList(kaydedenler),
      'kaydedilenler': _cloneStringList(kaydedilenler),
      'liseOrtaOkulIlceler': _cloneStringList(liseOrtaOkulIlceler),
      'liseOrtaOkulSehirler': _cloneStringList(liseOrtaOkulSehirler),
      'logo': logo,
      'mukerrerDurumu': mukerrerDurumu,
      'ogrenciSayisi': ogrenciSayisi,
      'sehirler': _cloneStringList(sehirler),
      'timeStamp': timeStamp,
      'tutar': tutar,
      'universiteler': _cloneStringList(universiteler),
      'userID': userID,
      'website': website,
      'lisansTuru': lisansTuru,
      'template': template,
      'ulke': ulke,
    };
    if (shortDescription.isNotEmpty) {
      map['shortDescription'] = shortDescription;
    }
    return map;
  }
}
