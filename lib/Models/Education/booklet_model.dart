class BookletModel {
  String basimTarihi;
  String baslik;
  String cover;
  String dil;
  List<String> kaydet;
  String sinavTuru;
  num timeStamp;
  String yayinEvi;
  String docID;
  String userID;
  int viewCount;
  String shortId;
  String shortUrl;

  static List<String> _cloneStringList(List<String> source) =>
      List<String>.from(source, growable: false);

  static List<String> _asStringList(dynamic value) {
    if (value is! List) return const <String>[];
    return value
        .map((item) => item?.toString().trim() ?? '')
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
  }

  static num _asNum(dynamic value, {num fallback = 0}) {
    if (value is num) return value;
    if (value is String) {
      final parsed = num.tryParse(value.trim());
      if (parsed != null) return parsed;
    }
    return fallback;
  }

  BookletModel({
    required this.dil,
    required this.sinavTuru,
    required this.cover,
    required this.baslik,
    required this.timeStamp,
    required this.docID,
    required List<String> kaydet,
    required this.basimTarihi,
    required this.yayinEvi,
    required this.userID,
    required this.viewCount,
    this.shortId = '',
    this.shortUrl = '',
  }) : kaydet = _cloneStringList(kaydet);

  factory BookletModel.fromMap(Map<String, dynamic> data, String docID) {
    final legacyViews = data["goruntuleme"];
    final fallbackViewCount = legacyViews is List ? legacyViews.length : 0;

    return BookletModel(
      dil: (data["dil"] ?? '').toString(),
      sinavTuru: (data["sinavTuru"] ?? '').toString(),
      cover: (data["cover"] ?? '').toString(),
      baslik: (data["baslik"] ?? '').toString(),
      timeStamp: _asNum(data["timeStamp"]),
      kaydet: _asStringList(data["kaydet"]),
      basimTarihi: (data["basimTarihi"] ?? '').toString(),
      yayinEvi: (data["yayinEvi"] ?? '').toString(),
      docID: docID,
      userID: (data["userID"] ?? '').toString(),
      viewCount: _asNum(data["viewCount"], fallback: fallbackViewCount).toInt(),
      shortId: (data["shortId"] ?? '').toString(),
      shortUrl: (data["shortUrl"] ?? '').toString(),
    );
  }
}
