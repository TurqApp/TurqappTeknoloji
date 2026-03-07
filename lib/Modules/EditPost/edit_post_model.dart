import 'package:cloud_firestore/cloud_firestore.dart';

class EditPostModel {
  bool arsiv;
  num aspectRatio;
  bool debugMode;
  bool deletedPost;
  num deletedPostTime;
  String docID;
  num? editTime;
  bool flood;
  num floodCount;
  bool gizlendi;
  List<String> img;
  bool isAd;
  bool ad;
  num izBirakYayinTarihi;
  List<String> kayitEdenler;
  String konum;
  String mainFlood;
  String metin;
  num paylasGizliligi;
  num scheduledAt;
  bool sikayetEdildi;
  num reportedCount;
  bool stabilized;
  List<String> tags;
  String thumbnail;
  num timeStamp;
  String userID;
  String video;
  bool yorum;

  /// Edit ekranında video oynatma için tekil URL.
  /// Bu modelde HLS alanları olmadığı için mevcut video alanını kullanır.
  String get playbackUrl => video;

  // Reshare/Yeniden Paylaşım bilgileri
  String? originalUserID;
  String? originalPostID;

  EditPostModel({
    required this.arsiv,
    required this.aspectRatio,
    required this.debugMode,
    required this.deletedPost,
    required this.deletedPostTime,
    required this.docID,
    this.editTime,
    required this.flood,
    required this.floodCount,
    required this.gizlendi,
    required this.img,
    required this.isAd,
    required this.ad,
    required this.izBirakYayinTarihi,
    required this.kayitEdenler,
    required this.konum,
    required this.mainFlood,
    required this.metin,
    required this.paylasGizliligi,
    required this.scheduledAt,
    required this.sikayetEdildi,
    required this.reportedCount,
    required this.stabilized,
    required this.tags,
    required this.thumbnail,
    required this.timeStamp,
    required this.userID,
    required this.video,
    required this.yorum,
    this.originalUserID,
    this.originalPostID,
  });

  factory EditPostModel.fromMap(Map<String, dynamic> data, String docID) {
    List<String> parseList(dynamic field) {
      if (field is List) return field.map((e) => e.toString()).toList();
      return <String>[];
    }

    return EditPostModel(
      arsiv: data['arsiv'] ?? false,
      aspectRatio: (data['aspectRatio'] ?? 1) as num,
      debugMode: data['debugMode'] ?? false,
      deletedPost: data['deletedPost'] ?? false,
      deletedPostTime: (data['deletedPostTime'] ?? 0) as num,
      docID: docID,
      editTime: data['editTime'],
      flood: data['flood'] ?? false,
      floodCount: (data['floodCount'] ?? 0) as num,
      gizlendi: data['gizlendi'] ?? false,
      img: parseList(data['img']),
      isAd: (data['isAd'] ?? data['ad'] ?? false) as bool,
      ad: (data['ad'] ?? data['isAd'] ?? false) as bool,
      izBirakYayinTarihi: (data['izBirakYayinTarihi'] ?? 0) as num,
      kayitEdenler: parseList(data['kayitEdenler']),
      konum: data['konum'] ?? '',
      mainFlood: data['mainFlood'] ?? '',
      metin: data['metin'] ?? '',
      paylasGizliligi: (data['paylasGizliligi'] ?? 0) as num,
      scheduledAt: (data['scheduledAt'] ?? 0) as num,
      sikayetEdildi: data['sikayetEdildi'] ?? false,
      reportedCount:
          ((data['stats'] as Map<String, dynamic>?)?['reportedCount'] ??
              data['reportedCount'] ??
              0) as num,
      stabilized: data['stabilized'] ?? false,
      tags: parseList(data['tags']),
      thumbnail: data['thumbnail'] ?? '',
      timeStamp: (data['timeStamp'] ?? 0) as num,
      userID: data['userID'] ?? '',
      video: data['video'] ?? '',
      yorum: data['yorum'] ?? false,
      originalUserID: data['originalUserID'] as String?,
      originalPostID: data['originalPostID'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'arsiv': arsiv,
      'aspectRatio': aspectRatio,
      'debugMode': debugMode,
      'deletedPost': deletedPost,
      'deletedPostTime': deletedPostTime,
      if (editTime != null) 'editTime': editTime,
      'flood': flood,
      'floodCount': floodCount,
      'gizlendi': gizlendi,
      'img': img,
      'isAd': isAd,
      'ad': ad,
      'izBirakYayinTarihi': izBirakYayinTarihi,
      'kayitEdenler': kayitEdenler,
      'konum': konum,
      'mainFlood': mainFlood,
      'metin': metin,
      'paylasGizliligi': paylasGizliligi,
      'scheduledAt': scheduledAt,
      'sikayetEdildi': sikayetEdildi,
      'reportedCount': reportedCount,
      'stabilized': stabilized,
      'tags': tags,
      'thumbnail': thumbnail,
      'timeStamp': timeStamp,
      'userID': userID,
      'video': video,
      'yorum': yorum,
      if (originalUserID != null) 'originalUserID': originalUserID,
      if (originalPostID != null) 'originalPostID': originalPostID,
    };
  }

  factory EditPostModel.empty() {
    return EditPostModel(
      arsiv: false,
      aspectRatio: 1,
      debugMode: false,
      deletedPost: false,
      deletedPostTime: 0,
      docID: '',
      editTime: null,
      flood: false,
      floodCount: 0,
      gizlendi: false,
      img: const [],
      isAd: false,
      ad: false,
      izBirakYayinTarihi: 0,
      kayitEdenler: const [],
      konum: '',
      mainFlood: '',
      metin: '',
      paylasGizliligi: 0,
      scheduledAt: 0,
      sikayetEdildi: false,
      reportedCount: 0,
      stabilized: false,
      tags: const [],
      thumbnail: '',
      timeStamp: 0,
      userID: '',
      video: '',
      yorum: false,
    );
  }

  EditPostModel copyWith({
    bool? arsiv,
    num? aspectRatio,
    bool? debugMode,
    bool? deletedPost,
    num? deletedPostTime,
    String? docID,
    num? editTime,
    bool? flood,
    num? floodCount,
    bool? gizlendi,
    List<String>? img,
    bool? isAd,
    bool? ad,
    num? izBirakYayinTarihi,
    List<String>? kayitEdenler,
    String? konum,
    String? mainFlood,
    String? metin,
    num? paylasGizliligi,
    num? scheduledAt,
    bool? sikayetEdildi,
    num? reportedCount,
    bool? stabilized,
    List<String>? tags,
    String? thumbnail,
    num? timeStamp,
    String? userID,
    String? video,
    bool? yorum,
    String? originalUserID,
    String? originalPostID,
  }) {
    return EditPostModel(
      arsiv: arsiv ?? this.arsiv,
      aspectRatio: aspectRatio ?? this.aspectRatio,
      debugMode: debugMode ?? this.debugMode,
      deletedPost: deletedPost ?? this.deletedPost,
      deletedPostTime: deletedPostTime ?? this.deletedPostTime,
      docID: docID ?? this.docID,
      editTime: editTime ?? this.editTime,
      flood: flood ?? this.flood,
      floodCount: floodCount ?? this.floodCount,
      gizlendi: gizlendi ?? this.gizlendi,
      img: img ?? this.img,
      isAd: isAd ?? this.isAd,
      ad: ad ?? this.ad,
      izBirakYayinTarihi: izBirakYayinTarihi ?? this.izBirakYayinTarihi,
      kayitEdenler: kayitEdenler ?? this.kayitEdenler,
      konum: konum ?? this.konum,
      mainFlood: mainFlood ?? this.mainFlood,
      metin: metin ?? this.metin,
      paylasGizliligi: paylasGizliligi ?? this.paylasGizliligi,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      sikayetEdildi: sikayetEdildi ?? this.sikayetEdildi,
      reportedCount: reportedCount ?? this.reportedCount,
      stabilized: stabilized ?? this.stabilized,
      tags: tags ?? this.tags,
      thumbnail: thumbnail ?? this.thumbnail,
      timeStamp: timeStamp ?? this.timeStamp,
      userID: userID ?? this.userID,
      video: video ?? this.video,
      yorum: yorum ?? this.yorum,
      originalUserID: originalUserID ?? this.originalUserID,
      originalPostID: originalPostID ?? this.originalPostID,
    );
  }

  factory EditPostModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return EditPostModel.fromMap(data, doc.id);
  }
}
