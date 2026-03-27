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

  BookletModel({
    required this.dil,
    required this.sinavTuru,
    required this.cover,
    required this.baslik,
    required this.timeStamp,
    required this.docID,
    required this.kaydet,
    required this.basimTarihi,
    required this.yayinEvi,
    required this.userID,
    required this.viewCount,
    this.shortId = '',
    this.shortUrl = '',
  });

  factory BookletModel.fromMap(Map<String, dynamic> data, String docID) {
    final legacyViews = data["goruntuleme"];
    final fallbackViewCount = legacyViews is List ? legacyViews.length : 0;

    return BookletModel(
      dil: (data["dil"] ?? '').toString(),
      sinavTuru: (data["sinavTuru"] ?? '').toString(),
      cover: (data["cover"] ?? '').toString(),
      baslik: (data["baslik"] ?? '').toString(),
      timeStamp: data["timeStamp"] is num
          ? data["timeStamp"] as num
          : num.tryParse((data["timeStamp"] ?? "0").toString()) ?? 0,
      kaydet: (data["kaydet"] is List)
          ? (data["kaydet"] as List).map((e) => e.toString()).toList()
          : <String>[],
      basimTarihi: (data["basimTarihi"] ?? '').toString(),
      yayinEvi: (data["yayinEvi"] ?? '').toString(),
      docID: docID,
      userID: (data["userID"] ?? '').toString(),
      viewCount: data["viewCount"] is num
          ? (data["viewCount"] as num).toInt()
          : fallbackViewCount,
      shortId: (data["shortId"] ?? '').toString(),
      shortUrl: (data["shortUrl"] ?? '').toString(),
    );
  }
}
