import 'package:flutter/cupertino.dart';

class PolicyDocument {
  const PolicyDocument({
    required this.id,
    required this.title,
    required this.summary,
    required this.updatedAt,
    required this.icon,
    required this.sections,
  });

  final String id;
  final String title;
  final String summary;
  final String updatedAt;
  final IconData icon;
  final List<PolicySection> sections;
}

class PolicySection {
  const PolicySection({
    required this.title,
    this.body = const [],
    this.bullets = const [],
  });

  final String title;
  final List<String> body;
  final List<String> bullets;
}

const List<PolicyDocument> turqAppPolicies = [
  PolicyDocument(
    id: 'agreement',
    title: 'Uyelik ve Sozlesme',
    summary:
        'TurqApp kullanimi, platformun rolu, kullanici sorumluluklari, telifler ve yaptirim cercevesini belirler.',
    updatedAt: '19 Mart 2026',
    icon: CupertinoIcons.doc_plaintext,
    sections: [
      PolicySection(
        title: 'Sozlesmenin Kapsami',
        body: [
          'Bu sozlesme, TurqApp icindeki sosyal icerik, mesajlasma, egitim, burs, ozel ders, is ilanlari, basvuru surecleri, pazar yeri benzeri alanlar ve bunlarla baglantili tum dijital yuzeylerde gecerlidir.',
          'TurqApp kullanilarak hesap acilmasi, giris yapilmasi veya uygulamadaki ozelliklerin kullanilmasi bu metnin kabul edildigi anlamina gelir.',
        ],
      ),
      PolicySection(
        title: 'Platformun Rolu',
        body: [
          'TurqApp, kullanicilar arasindaki her iletisim, basvuru, is iliskisi, ders iliskisi, burs sureci, urun devri, odeme veya teslimatin dogrudan tarafi degildir.',
          'Platform, teknoloji altyapisi ve topluluk guvenligi saglar; ancak kullanicilarin olusturdugu her icerigin, her ilanin veya her vaadin dogrulugunu garanti etmez.',
        ],
      ),
      PolicySection(
        title: 'Kullanici Taahhutleri',
        bullets: [
          'Dogru, guncel ve yaniltici olmayan bilgi sunmak',
          'Baskasini taklit etmemek',
          'Hukuka aykiri, dolandirici veya istismar niteligindeki kullanimlardan kacinmak',
          'Platformu toplulugu bozacak, manipule edecek veya guvenligi zayiflatacak sekilde kullanmamak',
          'Kendi hesabindan gerceklesen islemlerden sorumlu olmak',
        ],
      ),
      PolicySection(
        title: 'Icerik Sorumlulugu',
        body: [
          'TurqApp icinde paylasilan metin, gorsel, video, belge, yorum, profil alani, ilan ve benzeri tum iceriklerden oncelikle icerigi yukleyen kullanici sorumludur.',
          'TurqApp, gerekli gordugunde bu icerikleri inceleyebilir, indeksleyebilir, teknik olarak isleyebilir, gorunurlugunu sinirlayabilir veya kaldirabilir.',
        ],
      ),
      PolicySection(
        title: 'Telif ve Fikri Mulkiyet',
        body: [
          'Kullanicilar, yukledikleri icerik uzerinde gerekli haklara sahip olduklarini veya bu icerigi paylasmak icin yeterli izne sahip bulunduklarini kabul eder.',
          '5846 sayili Fikir ve Sanat Eserleri Kanunu basta olmak uzere uygulanabilir fikri mulkiyet mevzuatina aykiri icerikler TurqApp\'te barindirilmamalidir.',
          'TurqApp markasi, arayuzu, tasarim unsurlari, yazilim altyapisi, veri organizasyonu, logo, servis akislari ve uygulamaya ait ozgun unsurlar TurqApp\'e veya ilgili hak sahiplerine aittir.',
        ],
        bullets: [
          'Izinsiz kopyalama, cogaltma, yeniden yayimlama veya ticari kullanim yasaktir',
          'Telif ihlali bildirimi alan icerikler gecici veya kalici olarak kaldirilabilir',
          'Tekrarlayan ihlaller hesap kisitlamasina veya kapatmaya yol acabilir',
        ],
      ),
      PolicySection(
        title: 'TurqApp\'e Verilen Lisans',
        body: [
          'Kullanici, TurqApp\'te paylastigi icerigin hizmetin sunulabilmesi icin gerekli oldugu olcude depolanmasina, islenmesine, gosterilmesine, farkli cihaz boyutlarina uyarlanmasina, onizleme veya kisa baglanti sistemlerinde kullanilmasina ve moderasyon amaciyla incelenmesine izin verir.',
          'Bu izin, icerigin sahipligini TurqApp\'e gecirmez; yalnizca hizmetin isleyisi ve guvenligi icin gereken teknik kullanim alanlarini kapsar.',
        ],
      ),
      PolicySection(
        title: 'Yaptirim ve Hak Sakli Tutma',
        bullets: [
          'TurqApp icerigi kaldirabilir veya gizleyebilir',
          'Hesap ozelliklerini kisitlayabilir',
          'Ilgili kullaniciyi gecici veya kalici olarak platformdan uzaklastirabilir',
          'Gerekli durumlarda resmi mercilere bildirim yapabilir',
        ],
      ),
      PolicySection(
        title: 'Sorumlulugun Sinirlandirilmasi',
        body: [
          'TurqApp, mevzuatin izin verdigi en genis olcude; kullanicilar arasi islemlerden, ucuncu taraf davranislarindan, ilanlarin sonucundan, is veya burs kabullerinden, ders iliskilerinden veya platform disi gorusmelerden dogan dogrudan ya da dolayli riskleri tamamen ustlenmez.',
          'Platform, tum riskleri ortadan kaldiracagini garanti etmez; ancak guvenlik, raporlama ve moderasyon araclariyla makul koruma saglamayi hedefler.',
        ],
      ),
    ],
  ),
  PolicyDocument(
    id: 'privacy',
    title: 'Gizlilik',
    summary:
        'TurqApp icinde hangi bilgilerin olusabilecegini ve bunlarin nasil kullanildigini aciklar.',
    updatedAt: '19 Mart 2026',
    icon: CupertinoIcons.lock_shield,
    sections: [
      PolicySection(
        title: 'Genel Bakis',
        body: [
          'TurqApp, gizliligi yalnizca teknik bir konu olarak degil, uygulama deneyiminin temel parcalarindan biri olarak gorur.',
          'Bu politika; sosyal icerik, mesajlasma, egitim, burs, ozel ders, is ilanlari ve pazar yeri yuzeylerinde ortaya cikabilecek bilgilerin genel kullanim cercevesini aciklar.',
        ],
      ),
      PolicySection(
        title: 'Toplanabilecek Bilgiler',
        bullets: [
          'Hesap ve profil bilgileri',
          'Paylasilan post, hikaye, yorum, mesaj ve diger icerikler',
          'Burs, ozel ders, is ilani ve pazar alanlarina girilen bilgiler',
          'Basvurular, degerlendirmeler ve kullanici etkilesimleri',
          'Cihaz, uygulama surumu, hata ve guvenlik kayitlari',
          'Izin verilirse konum, kamera, galeri, bildirim veya rehber verileri',
        ],
      ),
      PolicySection(
        title: 'Bilgileri Neden Kullaniriz',
        bullets: [
          'Uygulamayi calistirmak ve hesap deneyimini yonetmek',
          'Icerikleri gostermek, siralamak ve eslestirmek',
          'Mesajlasma, basvuru ve ilan akislarini yurutmek',
          'Guvenlik risklerini, spam\'i ve kotuye kullanimi azaltmak',
          'Destek taleplerini ve kullanici raporlarini degerlendirmek',
          'Uygulamayi iyilestirmek ve hatalari gidermek',
        ],
      ),
      PolicySection(
        title: 'Mahremiyet',
        body: [
          'TurqApp icinde paylastiginiz bazi icerikler, paylasildiklari yuzeyin dogasi geregi diger kullanicilar tarafindan gorulebilir.',
          'Raporlanan icerikler, guvenlik riski tasiyan olaylar veya hukuki zorunluluk doguran durumlar sinirli incelemeye konu olabilir.',
        ],
      ),
      PolicySection(
        title: 'Secimleriniz',
        bullets: [
          'Profil bilgilerini guncelleme',
          'Belirli izinleri cihaz ayarlarindan yonetme',
          'Bildirim tercihlerini degistirme',
          'Hesap kapatma veya veri taleplerine iliskin basvuru yapma',
        ],
      ),
    ],
  ),
  PolicyDocument(
    id: 'notice',
    title: 'Aydinlatma',
    summary:
        'TurqApp kullanilirken hangi veri turlerinin hangi amaclarla islenebilecegini genel cercevede anlatir.',
    updatedAt: '19 Mart 2026',
    icon: CupertinoIcons.doc_text_search,
    sections: [
      PolicySection(
        title: 'Kapsam',
        body: [
          'TurqApp; sosyal paylasim, egitim icerikleri, burs ilanlari, ozel ders ilanlari, is ilanlari, basvuru akislar ve mesajlasma gibi dijital yuzeyleri kapsar.',
          'Bu hizmetler kullanilirken bazi kisisel veriler islenebilir.',
        ],
      ),
      PolicySection(
        title: 'Islenebilecek Veri Turleri',
        bullets: [
          'Hesap ve profil bilgileri',
          'Iletisim bilgileri',
          'Yuklenen metin, gorsel, video ve belgeler',
          'Yorum, mesaj, kaydetme, begeni ve rapor kayitlari',
          'Ilan, basvuru ve degerlendirme bilgileri',
          'Sehir, ilce ve izin verilirse konum verileri',
          'Cihaz, oturum, hata ve guvenlik loglari',
        ],
      ),
      PolicySection(
        title: 'Isleme Amaclari',
        bullets: [
          'Hesaplari olusturmak ve yonetmek',
          'Icerik, ilan, basvuru ve mesajlasma sureclerini calistirmak',
          'Guvenlik, spam onleme ve kotuye kullanim tespiti yapmak',
          'Rapor ve moderasyon sureclerini yurutmek',
          'Teknik sorunlari gidermek ve performansi iyilestirmek',
          'Hukuki yukumlulukleri yerine getirmek',
        ],
      ),
      PolicySection(
        title: 'Saklama ve Silme',
        body: [
          'Veriler, hizmetin amaci veya uygulanabilir hukuki gereklilikler devam ettigi surece saklanabilir.',
          'Gerek kalmadiginda makul surede silme, yok etme veya anonimlestirme surecleri uygulanir.',
        ],
      ),
    ],
  ),
  PolicyDocument(
    id: 'community',
    title: 'Topluluk',
    summary:
        'TurqApp icindeki davranis standartlarini ve kabul edilmeyecek icerik turlerini aciklar.',
    updatedAt: '19 Mart 2026',
    icon: CupertinoIcons.person_2_fill,
    sections: [
      PolicySection(
        title: 'Saygili Kalin',
        bullets: [
          'Hakaret etmeyin',
          'Tehdit etmeyin',
          'Kisileri asagilamayin',
          'Hedef gosterme yapmayin',
        ],
      ),
      PolicySection(
        title: 'Duzgun ve Gercekci Olun',
        bullets: [
          'Sahte hesap kullanmayin',
          'Baskalarini taklit etmeyin',
          'Yaniltici ilan, sahte profil veya sahte referans paylasmayin',
        ],
      ),
      PolicySection(
        title: 'Guvenligi Tehlikeye Atmayin',
        bullets: [
          'Dolandiricilik yapmayin',
          'Platform disi riskli odemeye zorlamayin',
          'Kullanicilardan hassas bilgi toplamaya calismayin',
          'Ozel bilgileri izinsiz yaymayin',
        ],
      ),
      PolicySection(
        title: 'Cocuk Guvenligi',
        body: [
          'Resit olmayan kullanicilari hedef alan uygunsuz iletisim, manipulasyon, cinsel icerik, bulusma baskisi veya somuru niteligindeki her davranis kesin olarak yasaktir.',
        ],
      ),
    ],
  ),
  PolicyDocument(
    id: 'moderation',
    title: 'Guvenlik ve Moderasyon',
    summary:
        'TurqApp\'in rapor, guvenlik sinyali ve ihlal durumlarinda nasil mudahale edebilecegini aciklar.',
    updatedAt: '19 Mart 2026',
    icon: CupertinoIcons.shield_lefthalf_fill,
    sections: [
      PolicySection(
        title: 'Neleri Inceleyebiliriz',
        bullets: [
          'Postlar ve hikayeler',
          'Yorumlar',
          'Profil alanlari',
          'Burs, ozel ders, is ilani ve pazar yeri icerikleri',
          'Mesajlasma ve basvuru ekleri',
          'Gorseller, videolar ve belgeler',
        ],
      ),
      PolicySection(
        title: 'Moderasyon Kaynaklari',
        bullets: [
          'Kullanici raporlari',
          'Otomatik guvenlik kontrolleri',
          'Spam veya suistimal sinyalleri',
          'Uygunsuz gorsel veya medya tespiti',
          'Tekrar eden ihlal gecmisi',
        ],
      ),
      PolicySection(
        title: 'Hizli Mudahale Alanlari',
        bullets: [
          'Cocuk guvenligi riski',
          'Cinsel istismar veya somuru',
          'Siddet tehdidi',
          'Dolandiricilik ve sahte ilan',
          'Ozel bilgilerin ifsasi',
          'Agir taciz ve toplu hedef gosterme',
        ],
      ),
      PolicySection(
        title: 'Uygulanabilecek Aksiyonlar',
        bullets: [
          'Uyari verilmesi',
          'Icerigin kaldirilmasi',
          'Icerigin gecici olarak gizlenmesi',
          'Hesap ozelliklerinin kisitlanmasi',
          'Gecici aski',
          'Kalici hesap kapatma',
        ],
      ),
    ],
  ),
];
