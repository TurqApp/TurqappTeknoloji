part of 'external.dart';

List<String> bursKosullari = [
  "T.C. vatandaşı olmak.",
  "En az lise düzeyinde öğrenim görüyor olmak.",
  "Herhangi bir disiplin cezası almamış olmak.",
  "Ailesinin aylık toplam gelirinin belirli bir seviyenin altında olması.",
  "Başka bir kurumdan karşılıksız burs almıyor olmak.",
  "Örgün öğretim programında kayıtlı öğrenci olmak.",
  "Akademik not ortalamasının en az 2.50/4.00 olması.",
  "Adli sicil kaydının temiz olması.",
  "İlan edilen son başvuru tarihine kadar başvuru yapılmış olması.",
  "Belirtilen belgelerin eksiksiz şekilde teslim edilmiş olması.",
  "Burs başvuru formunun eksiksiz doldurulması.",
  "Burs verilen il/ilçede ikamet ediyor olmak (gerekiyorsa).",
  "Eğitim süresi boyunca düzenli olarak başarı göstereceğini taahhüt etmek.",
  "Başvuru sırasında gerçeğe aykırı beyanda bulunmamak.",
  "Bursu sağlayan kurumun düzenlediği mülakat veya değerlendirme süreçlerine katılmak.",
];

void bildirimGonderiliyor(
  String gonderilecekUserID,
  String postID,
  String thumb,
  String postType,
  String desc,
) {
  final currentUserId = CurrentUserService.instance.effectiveUserId;
  if (currentUserId.isEmpty) return;
  if (gonderilecekUserID != currentUserId) {
    FirebaseFirestore.instance
        .collection("users")
        .doc(gonderilecekUserID)
        .collection("Bildirimler")
        .add({
      "desc": desc,
      "title": "",
      "userID": currentUserId,
      "postID": postID,
      "timeStamp": DateTime.now().millisecondsSinceEpoch,
      "thumbnail": thumb,
      "postType": postType,
      "isRead": false,
    });

    FirebaseFirestore.instance
        .collection("users")
        .doc(gonderilecekUserID)
        .update({"bildirim": true});
  }
}

final emailOtpHTML = '''<!DOCTYPE html>
<html lang="en">
<head>
    <style>
        body {
            font-family: Arial, sans-serif;
            background-color: #f4f4f4;
            margin: 0;
            padding: 0;
        }
        .email-container {
            max-width: 600px;
            margin: 50px auto;
            background-color: #ffffff;
            border-radius: 8px;
            overflow: hidden;
            box-shadow: 0 4px 8px rgba(0, 0, 0, 0.1);
        }
        .header {
            background-color: #000000;
            color: white;
            text-align: center;
            padding: 20px 0;
            font-size: 24px;
            font-weight: bold;
        }
        .content {
            padding: 20px;
            text-align: center;
            color: #333333;
            font-size: 16px;
        }
        .code {
            margin: 20px 0;
            display: inline-block;
            padding: 10px 20px;
            font-size: 30px;
            font-weight: bold;
            letter-spacing: 4px;
            background-color: #000000;
            color: #ffffff;
        }
        .logo-container {
            display: flex;
            align-items: center;
            justify-content: center;
            margin-top: 20px;
        }
        .logo-container img {
            width: 50px;
            height: 50px;
        }
        .logo-marka span {
            font-size: 25px;
            font-weight: bold;
            color: #333333;
        }
        .footer {
            background-color: #f4f4f4;
            color: #666666;
            text-align: center;
            padding: 10px 20px;
            font-size: 14px;
        }
        .footer a {
            color: #4CAF50;
            text-decoration: none;
        }
    </style>
</head>
<body>
    <div class="email-container">
        <div class="content">
            <div class="logo-container">
                <img src="https://firebasestorage.googleapis.com/v0/b/turqappteknoloji.firebasestorage.app/o/logoblack.png?alt=media&token=23085c34-c823-48d9-a650-2342ec801d23" alt="TurqApp">
            </div>
            <div class="logo-container"></div>
            
            <div class="logo-marka">
                <span>TurqApp</span>
            </div>
            
            <p>Aşağıdaki doğrulama kodunu kullanarak işleminizi tamamlayabilirsiniz:</p>
            
            <div class="code">1234</div>
            
            <p>Eğer şifre sıfırlama talebinde bulunmadıysanız, bu e-postayı dikkate almayınız.</p>
        </div>
        <div class="footer">
            <p>© 2025 TurqApp. Tüm hakları saklıdır.</p>
        </div>
    </div>
</body>
</html>
''';

final List<String> siralamaList = [
  "Fiyat: Düşükten Yükseğe",
  "Fiyat: Yüksekten Düşüğe",
  "Tarih: Eskiden Yeniye",
  "Tarih: Yeniden Eskiye",
];

List<String> dersYerleri = [
  "Öğrencinin Evi",
  "Öğretmenin Evi",
  "Öğrencinin veya Öğretmenin Evi",
  "Uzaktan Eğitim",
  "Ders Verme Alanı",
];

List<String> categories = [
  "Kadın",
  "Erkek",
  "Çocuk",
  "Mobilya",
  "Elektronik",
  "Koleksiyon",
  "El Sanatları",
  "Bebek",
  "Kitaplar",
  "Sağlık",
  "Mutfak",
  "Yapı Malz.",
  "Züccaciye",
  "Çanta",
  "Enstrümanları",
  "Evcil Hayvan",
  "Spor",
  "Oyun",
  "Araç Gereç",
  "Dış Mekan",
  "Büro",
  "Ev Eşyaları",
  "Eğlence",
  "Hobiler",
];

List<Color> renkler2 = [
  Colors.blueGrey,
  Colors.teal,
  Colors.deepOrange,
  Colors.indigo,
  Colors.orange,
  Colors.green,
  Colors.purple,
  Colors.pink,
  Colors.blue,
];

List<IconData> bursikonlar = [
  Icons.school_outlined,
  Icons.add,
  Icons.people_outline,
  Icons.person_outline,
  Icons.home_outlined,
  Icons.account_balance_outlined,
  Icons.assignment_outlined,
  CupertinoIcons.bookmark,
  Icons.insert_drive_file_outlined,
];

List<String> renkler = [
  "Kırmızı",
  "Mavi",
  "Yeşil",
  "Sarı",
  "Turuncu",
  "Mor",
  "Pembe",
  "Lacivert",
  "Beyaz",
  "Siyah",
  "Gri",
  "Kahverengi",
  "Açık Mavi",
  "Koyu Yeşil",
  "Fuşya",
  "Bej",
  "Krem",
  "Altın Sarısı",
  "Gümüş",
  "Turkuaz",
];

List<ReportModel> reportSelections = [
  ReportModel(
    key: "impersonation",
    title: "Taklit / Sahte Hesap / Kimlik Kullanımı",
    description:
        "Bu hesap veya içerik, kimlik taklidi, sahte hesap kullanımı ya da başka bir kişiyi izinsiz temsil etme şüphesi taşıyor.",
  ),
  ReportModel(
    key: "copyright",
    title: "Telif / İzinsiz İçerik Kullanımı",
    description:
        "Bu içerik telif hakkıyla korunan materyalleri izinsiz kullanıyor veya fikri mülkiyet ihlali içeriyor olabilir.",
  ),
  ReportModel(
    key: "harassment",
    title: "Taciz / Hedef Gösterme / Zorbalık",
    description:
        "Bu içerik bir kişiyi rahatsız etme, aşağılamaya çalışma, hedef gösterme ya da sistematik zorbalık içeriği taşıyor.",
  ),
  ReportModel(
    key: "hate_speech",
    title: "Nefret Söylemi",
    description:
        "Bu içerik bir gruba veya kişiye karşı nefret, ayrımcılık ya da aşağılayıcı söylem içeriyor.",
  ),
  ReportModel(
    key: "nudity",
    title: "Çıplaklık / Cinsel İçerik",
    description:
        "Bu içerik çıplaklık, müstehcenlik ya da açık cinsel içerik barındırıyor olabilir.",
  ),
  ReportModel(
    key: "violence",
    title: "Şiddet / Tehdit",
    description:
        "Bu içerik fiziksel şiddet, tehdit, korkutma ya da zarar verme çağrısı içeriyor olabilir.",
  ),
  ReportModel(
    key: "spam",
    title: "Spam / Alakasız Tekrar İçerik",
    description:
        "Bu içerik tekrar eden, alakasız, yanıltıcı ya da rahatsız edici biçimde spam niteliği taşıyor.",
  ),
  ReportModel(
    key: "scam",
    title: "Dolandırıcılık / Yanıltma",
    description:
        "Bu içerik para, bilgi ya da güven istismarı amacıyla yanıltıcı veya dolandırıcılık içerikli olabilir.",
  ),
  ReportModel(
    key: "misinformation",
    title: "Yanlış Bilgi / Manipülasyon",
    description:
        "Bu içerik gerçeği çarpıtan, yanlış bilgi yayan ya da manipülatif yönlendirme yapan unsurlar içeriyor olabilir.",
  ),
  ReportModel(
    key: "illegal_content",
    title: "Yasa Dışı İçerik",
    description:
        "Bu içerik yasa dışı faaliyet, suç teşviki ya da hukuka aykırı materyal içeriyor olabilir.",
  ),
  ReportModel(
    key: "child_safety",
    title: "Çocuk Güvenliği İhlali",
    description:
        "Bu içerik çocuk güvenliğini tehlikeye atıyor ya da çocuklara uygun olmayan zararlı unsurlar taşıyor olabilir.",
  ),
  ReportModel(
    key: "self_harm",
    title: "Kendine Zarar Verme / İntihar Teşviki",
    description:
        "Bu içerik kendine zarar verme, intihar teşviki ya da bu yönde yönlendirme içeriyor olabilir.",
  ),
  ReportModel(
    key: "privacy_violation",
    title: "Gizlilik İhlali",
    description:
        "Bu içerik kişisel verilerin izinsiz paylaşımı, doxxing ya da mahremiyet ihlali içeriyor olabilir.",
  ),
  ReportModel(
    key: "fake_engagement",
    title: "Sahte Etkileşim / Bot / Manipülatif Büyütme",
    description:
        "Bu içerik sahte beğeni, bot etkileşimi ya da yapay büyütme amaçlı manipülatif davranış içeriyor olabilir.",
  ),
  ReportModel(
    key: "other",
    title: "Diğer",
    description:
        "Yukarıdaki seçeneklerin dışında kalan, ayrıca incelenmesini istediğiniz başka bir ihlal nedeni bulunuyor.",
  ),
];

String kacGunKaldi(int timestampMillis) {
  final hedefTarih = DateTime.fromMillisecondsSinceEpoch(timestampMillis);
  final simdi = DateTime.now();
  final fark = hedefTarih.difference(simdi).inDays;

  if (fark > 0) {
    return 'common.days_left'.trParams({'count': '$fark'});
  } else if (fark == 0) {
    return 'common.today'.tr;
  } else {
    return 'common.days_ago'.trParams({'count': '${fark.abs()}'});
  }
}

List<String> biVideoTags = [
  "Ayrılığım",
  "Başarım",
  "Beklentim",
  "Deneyimim",
  "Dileğim",
  "Emanetim",
  "Hatırlatmam",
  "Hayalim",
  "Hedefim",
  "İtirafım",
  "Kutlamam",
  "Mektubum",
  "Müjdem",
  "Öğüdüm",
  "Özlemim",
  "Özürüm",
  "Sesim",
  "Sözüm",
  "Sürprizim",
  "Tahminim",
  "Tavsiyem",
  "Teşekkürüm",
  "Umarım",
  "Unutma",
  "Uyarım",
  "Vasiyetim",
  "Vedam",
  "Vizyonum",
  "Zaferim",
];

List<String> postKategoriler = [
  "Bilim, Eğitim, Teknoloji",
  "Yapay Zeka, Mühendislik",
  "Dijital Pazarlama, Finans",
  "İş, Kariyer, Girişimcilik",
  "Ekonomi, Hukuk, Tavsiye",
  "Motivasyon, Kişisel Gelişim",
  "Spor, Fitness, Sağlık",
  "Beslenme, Yaşam Tarzı",
  "Gezi, Seyahat, Doğa",
  "Çevre, Hayvanlar, Bitkiler",
  "Dekorasyon, Ev, Bahçe, Hobi",
  "Otomobil, Araçlar, Oyun",
  "Makine, İnşaat, Yapılar",
  "Eğlence, Ünlüler, Komedi",
  "Müzik, Sinema",
  "Haber, Siyaset, Tarih",
  "Psikoloji, Felsefe",
  "İnanç, Aile, İlişki, İpuçları",
  "Fotoğraf, Moda",
  "Sanat, Kitap, Kültür",
  "Yemek, İçecek, Tüketim",
  "Günlük Yaşam, Alışveriş",
];
