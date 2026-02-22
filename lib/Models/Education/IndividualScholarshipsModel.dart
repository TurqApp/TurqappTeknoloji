class IndividualScholarshipsModel {
  final String aciklama;
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

  IndividualScholarshipsModel({
    required this.aciklama,
    required this.altEgitimKitlesi,
    required this.aylar,
    required this.basvurular,
    required this.baslangicTarihi,
    required this.baslik,
    required this.basvuruKosullari,
    required this.basvuruURL,
    required this.basvuruYapilacakYer,
    required this.begeniler,
    required this.belgeler,
    required this.bitisTarihi,
    required this.bursVeren,
    required this.egitimKitlesi,
    required this.geriOdemeli,
    required this.goruntuleme,
    required this.hedefKitle,
    required this.ilceler,
    required this.img,
    required this.img2,
    required this.kaydedenler,
    required this.kaydedilenler,
    required this.liseOrtaOkulIlceler,
    required this.liseOrtaOkulSehirler,
    required this.logo,
    required this.mukerrerDurumu,
    required this.ogrenciSayisi,
    required this.sehirler,
    required this.timeStamp,
    required this.tutar,
    required this.universiteler,
    required this.userID,
    required this.website,
    required this.lisansTuru,
    required this.template,
    required this.ulke,
  });

  factory IndividualScholarshipsModel.fromJson(Map<String, dynamic> json) {
    return IndividualScholarshipsModel(
      aciklama: json['aciklama'] ?? '',
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
    return {
      'aciklama': aciklama,
      'altEgitimKitlesi': altEgitimKitlesi,
      'aylar': aylar,
      'basvurular': basvurular,
      'baslangicTarihi': baslangicTarihi,
      'baslik': baslik,
      'basvuruKosullari': basvuruKosullari,
      'basvuruURL': basvuruURL,
      'basvuruYapilacakYer': basvuruYapilacakYer,
      'begeniler': begeniler,
      'belgeler': belgeler,
      'bitisTarihi': bitisTarihi,
      'bursVeren': bursVeren,
      'egitimKitlesi': egitimKitlesi,
      'geriOdemeli': geriOdemeli,
      'goruntuleme': goruntuleme,
      'hedefKitle': hedefKitle,
      'ilceler': ilceler,
      'img': img,
      'img2': img2,
      'kaydedenler': kaydedenler,
      'kaydedilenler': kaydedilenler,
      'liseOrtaOkulIlceler': liseOrtaOkulIlceler,
      'liseOrtaOkulSehirler': liseOrtaOkulSehirler,
      'logo': logo,
      'mukerrerDurumu': mukerrerDurumu,
      'ogrenciSayisi': ogrenciSayisi,
      'sehirler': sehirler,
      'timeStamp': timeStamp,
      'tutar': tutar,
      'universiteler': universiteler,
      'userID': userID,
      'website': website,
      'lisansTuru': lisansTuru,
      'template': template,
      'ulke': ulke,
    };
  }
}
