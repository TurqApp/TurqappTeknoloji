part of 'external.dart';

final sinavTurleriList2 = [
  "LGS",
  "TYT",
  "AYT",
  "YDT",
  "ALES",
  "DGS",
  "YDS",
  "TUS",
  "DUS",
  "KPSS Ortaöğretim",
  "KPSS Ön Lisans",
  "KPSS GY-GK",
  "KPSS Eğitim Bilimleri",
  "KPSS Alan Bilgisi",
  "KPSS A Grubu 1",
  "KPSS A Grubu 2",
];
final sinavTurleriList = ["LGS", "TYT", "AYT", "KPSS", "ALES", "DGS"];

List<String> kpssOrtaOgretimVeOnLisansGYGK = ["Genel Yetenek", "Genel Kültür"];

List<String> kpssEgitimBilimleri = ["Eğitim Bilimleri"];

List<String> coverColors = [
  "#FF5733",
  "#33FF57",
  "#3357FF",
  "#FF33A5",
  "#33FFF3",
  "#8D33FF",
  "#FFD133",
  "#FF8C33",
  "#33A5FF",
  "#FF5733",
  "#33FF57",
  "#C70039",
  "#581845",
  "#DAF7A6",
  "#FFC300",
  "#FF5733",
  "#28B463",
  "#1F618D",
  "#AF7AC5",
  "#34495E",
];

List<int> sinavSureleri = [30, 45, 60, 75, 90, 100, 120, 150, 180];

List<int> sinavSureleri2 = [
  90,
  100,
  105,
  120,
  135,
  140,
  150,
  160,
  165,
  180,
  185,
  190,
];

String formatTimestamp(int timestamp) {
  final DateTime dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
  final DateFormat formatter = DateFormat('dd.MM.yyyy - HH:mm');
  return formatter.format(dateTime);
}

List<String> dersler = [
  "Ortaokul",
  "Lise",
  "Hazırlık",
  "Dil",
  "Branş",
];

List<IconData> derslerIconsOutlined = [
  Icons.man,
  Icons.chair_alt,
  Icons.create,
  Icons.language,
  Icons.mic_external_on_outlined,
  Icons.computer,
  Icons.credit_card,
  Icons.all_inclusive,
];

List<String> dersler1 = [
  "LGS",
  "TYT",
  "AYT",
  "YDT",
  "YDS",
  "ALES",
  "DGS",
  "KPSS",
  "DUS",
  "TUS",
  "Dil",
  "Yazılım",
  "Spor",
  "Tasarım",
];

List<IconData> dersler1icons = [
  Icons.psychology,
  Icons.school,
  Icons.library_books,
  Icons.translate,
  Icons.language,
  Icons.book_online,
  Icons.calculate,
  Icons.assignment,
  Icons.health_and_safety,
  Icons.medical_services,
  Icons.translate,
  Icons.code,
  Icons.sports_basketball,
  Icons.design_services,
];

List<String> tumDersler = [
  "Türkçe",
  "Edebiyat",
  "Matematik",
  "Geometri",
  "Fizik",
  "Kimya",
  "Biyoloji",
  "Tarih",
  "Coğrafya",
  "Felsefe",
  "Psikoloji",
  "Sosyoloji",
  "Mantık",
  "Din Kültürü",
  "Dil",
];

bool containsEmoji(String text) {
  final RegExp emojiRegExp = RegExp(
    r'[\u{1F300}-\u{1F5FF}]|'
    r'[\u{1F600}-\u{1F64F}]|'
    r'[\u{1F680}-\u{1F6FF}]|'
    r'[\u{1F700}-\u{1F77F}]|'
    r'[\u{1F780}-\u{1F7FF}]|'
    r'[\u{1F800}-\u{1F8FF}]|'
    r'[\u{1F900}-\u{1F9FF}]|'
    r'[\u{1FA00}-\u{1FA6F}]|'
    r'[\u{2600}-\u{26FF}]|'
    r'[\u{2700}-\u{27BF}]',
    unicode: true,
  );

  return emojiRegExp.hasMatch(text);
}

List<String> hazirlikDersler = ["YDS", "YÖKDİL", "YKSDİL", "TOEFL", "IELTS"];

List<Color> tumderslerColors = [
  Colors.lightBlue.shade700,
  Colors.pink.shade600,
  Colors.green.shade700,
  Colors.orange.shade700,
  Colors.red.shade800,
  Colors.indigo.shade800,
  Colors.lime.shade700,
  Colors.brown.shade800,
  Colors.blue.shade800,
  Colors.cyan.shade800,
  Colors.purple.shade700,
  Colors.teal.shade700,
  Colors.red.shade700,
  Colors.deepOrange.shade700,
];

List<IconData> tumDerslerIconlar = [
  Icons.menu_book,
  Icons.calculate,
  Icons.science,
  Icons.class_outlined,
  Icons.biotech,
  Icons.history_edu,
  Icons.terrain,
  Icons.psychology,
  Icons.self_improvement,
  Icons.square_foot,
  Icons.book,
  Icons.groups,
  Icons.science_outlined,
  Icons.flag,
  Icons.handshake,
  Icons.language,
];

List<String> bransDersleri = [
  "Türkçe",
  "İlköğretim Matematik",
  "Fen Bilimleri",
  "Sosyal Bilgiler",
  "Türk Dili ve Edebiyatı",
  "Tarih",
  "Coğrafya",
  "Lise Matematik",
  "Fizik",
  "Kimya",
  "Biyoloji",
  "Din Kültürü ve Ahlak Bilgisi",
  "İngilizce",
  "Rehberlik",
  "Sınıf Öğretmenliği",
  "Okul Öncesi",
  "Beden Eğitimi",
  "Kamu Yönetimi",
  "Uluslararası İlişkiler",
  "Çalışma Ekonomisi",
  "Hukuk",
  "İktisat",
  "Maliye",
  "İşletme",
  "Muhasebe",
  "İstatistik",
];

List<String> kpssAlanBilgisi = [
  "Almanca Öğretmenliği",
  "Beden Eğitimi",
  "Biyoloji Öğretmenliği",
  "Coğrafya Öğretmenliği",
  "Din Kültürü Öğretmenliği",
  "Edebiyat Öğretmenliği",
  "Fen Bilimleri Öğretmenliği",
  "Fizik Öğretmenliği",
  "Matematik Öğretmenliği",
  "İmam Hatip Öğretmenliği",
  "İngilizce Öğretmenliği",
  "Kimya Öğretmenliği",
  "Lise Matematik Öğretmenliği",
  "Okul Öncesi Öğretmenliği",
  "Rehberlik",
  "Sınıf Öğretmenliği",
  "Sosyal Bilgiler Öğretmenliği",
  "Tarih Öğretmenliği",
  "Türkçe Öğretmenliği",
];

List<String> yabanciDiller = [
  "İngilizce",
  "Almanca",
  "Arapça",
  "Fransızca",
  "Rusça",
];

List<String> lgsDersler = [
  "Matematik",
  "Fen Bilimleri",
  "Türkçe",
  "İnkilap Tarihi",
  "Din Kültürü",
  "Yabancı Dil",
];

List<String> tytDersler = [
  "Temel Matematik",
  "Fen Bilimleri",
  "Türkçe",
  "Sosyal Bilimler",
];

List<String> aytDersler = [
  "Matematik",
  "Fen Bilimleri",
  "Edebiyat - Sosyal Bilimler 1",
  "Sosyal Bilimler 2",
];

List<String> kpssDerslerOrtaVeOnLisans = ["Genel Yetenek", "Genel Kültür"];

List<String> kpssDerslerAgrubu1 = [
  "Çalışma Ekonomisi",
  "İstatistik",
  "Uluslararası İlişkiler",
  "Kamu Yönetimi",
];

List<String> kpssDerslerAgrubu2 = [
  "Hukuk",
  "İktisat",
  "İşletme",
  "Maliye",
  "Muhasebe",
];

List<String> kpssDerslerEgitimbirimleri = ["Eğitim Birimleri"];

List<String> tusDersler = ["KTBT", "TTBT"];

List<String> dusDersler = ["Temel Bilimler", "Klinik Bilimler"];

List<String> alesVeDgsDersler = ["Sayısal", "Sözel"];

List<String> ydsDersler = [
  "İngilizce",
  "Almanca",
  "Arapça",
  "Fransızca",
  "Rusça",
];

List<String> kpssOgretimTipleri = [
  "Ortaöğretim",
  "Ön Lisans",
  "Lisans",
  "Eğitim Birimleri",
  "A Grubu 1",
  "A Grubu 2",
];

List<String> kpssOgretimTipleri2 = [
  "Ortaöğretim",
  "Ön Lisans",
  "Lisans GK-GY",
  "Eğitim Birimleri",
  "A Grubu 1",
  "A Grubu 2",
];

List<String> aGrubu1Dersler = [
  "Çalışma Ekonomisi",
  "Ekonometri",
  "İstatistik",
  "Kamu Yönetimi",
  "Uluslararası İlişkiler",
];

List<String> aGrubu2Dersler = [
  "Hukuk",
  "İktisat",
  "İşletme",
  "Maliye",
  "Muhasebe",
];

Map<String, Color> sinavTuruRenkleri = {
  "TYT": Colors.blue,
  "YKS": Colors.purple,
  "AYT": Colors.orange,
  "YDT": Colors.deepPurple,
  "LGS": Colors.green,
  "DUS": Colors.cyan,
  "DGS": Colors.teal,
  "ALES": Colors.amber.shade900,
  "TUS": Colors.red,
  "KPSS Ortaöğretim": Colors.indigo,
  "KPSS Ön Lisans": Colors.blueGrey,
  "KPSS GY-GK": Colors.lightBlue,
  "KPSS Eğitim Bilimleri": Colors.deepOrange,
  "KPSS Alan Bilgisi": Colors.lime,
  "KPSS A Grubu 1": Colors.brown,
  "KPSS A Grubu 2": Colors.grey,
  "YDS": Colors.pink,
};

List<Color> dersRenkleri = [
  Color(0xFF1A237E),
  Color(0xFF512DA8),
  Color(0xFF388E3C),
  Color(0xFFC62828),
  Color(0xFFEF6C00),
  Color(0xFF3E2723),
  Color(0xFF212121),
  Color(0xFF546E7A),
  Color(0xFF0D47A1),
  Color(0xFF3B3D33),
];

List<String> calismaTurleri = [
  'Tam Zamanlı',
  'Yarı Zamanlı',
  'Freelance',
  'Stajyer',
  'Çırak',
  'Geçici',
  'Uzaktan Çalışma',
];

List<String> yanHaklar = [
  'Yemek Servisi',
  'Özel Sağlık Sigortası',
  'Ulaşım Yardımı',
  'Esnek Çalışma Saatleri',
  'Bonus / Prim',
  'Eğitim ve Gelişim Fırsatları',
  'Telefon ve İnternet Desteği',
  'Fleksible Çalışma Seçenekleri',
  'Çalışma Alanı Desteği (Ofis / Ev)',
];

List<Color> softColors = [
  Colors.green[400]!,
  Colors.red[300]!,
  Colors.blueAccent[200]!,
  Colors.purple[300]!,
  Colors.teal[300]!,
  Colors.indigo[500]!,
  Colors.lightBlue[300]!,
  Colors.brown[300]!,
  Colors.cyan[300]!,
  Colors.indigo[300]!,
  Colors.amber[300]!,
  Colors.lime[300]!,
  Colors.deepOrange[300]!,
  Colors.blueGrey[300]!,
  Colors.greenAccent[200]!,
  Colors.deepPurple[300]!,
  Colors.redAccent[200]!,
  Colors.tealAccent[400]!,
  Colors.lightBlueAccent[200]!,
  Colors.green[200]!,
  Colors.brown[300]!,
  Colors.pink[300]!,
  Colors.indigo[300]!,
];
