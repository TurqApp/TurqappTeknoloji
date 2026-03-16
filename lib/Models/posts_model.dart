import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:turqappv2/Core/Utils/cdn_url_builder.dart';

// Alt koleksiyonlar için model sınıfları
class PostStats {
  num commentCount;
  num likeCount;
  num reportedCount;
  num retryCount;
  num savedCount;
  num statsCount;

  PostStats({
    this.commentCount = 0,
    this.likeCount = 0,
    this.reportedCount = 0,
    this.retryCount = 0,
    this.savedCount = 0,
    this.statsCount = 0,
  });

  factory PostStats.fromMap(Map<String, dynamic> data) {
    return PostStats(
      commentCount: (data['commentCount'] ?? 0) as num,
      likeCount: (data['likeCount'] ?? 0) as num,
      reportedCount: (data['reportedCount'] ?? 0) as num,
      retryCount: (data['retryCount'] ?? 0) as num,
      savedCount: (data['savedCount'] ?? 0) as num,
      statsCount: (data['statsCount'] ?? 0) as num,
    );
  }

  // Firebase'deki post verisinden stats oluşturur - sadece stats map kullanır
  factory PostStats.fromPostData(Map<String, dynamic> postData) {
    // Stats objesi içindeki değerleri al - zorunlu yapı
    final statsData = postData['stats'] as Map<String, dynamic>?;

    if (statsData != null) {
      return PostStats.fromMap(statsData);
    } else {
      // Stats objesi yoksa boş stats döndür
      if (kDebugMode) {
        print(
            '[PostStats] ⚠️ Stats objesi bulunamadı (${postData['userID'] ?? 'unknown'}), default değerler kullanılıyor');
      }
      return PostStats();
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'commentCount': commentCount,
      'likeCount': likeCount,
      'reportedCount': reportedCount,
      'retryCount': retryCount,
      'savedCount': savedCount,
      'statsCount': statsCount,
    };
  }
}

class PostsModel {
  bool ad;
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
  bool isUploading;
  num izBirakYayinTarihi;
  String konum;
  String locationCity;
  String mainFlood;
  String metin;
  String originalPostID;
  String originalUserID;
  bool quotedPost;
  String quotedOriginalText;
  String quotedSourceUserID;
  String quotedSourceDisplayName;
  String quotedSourceUsername;
  String quotedSourceAvatarUrl;
  num paylasGizliligi;
  num scheduledAt;
  bool sikayetEdildi;
  bool stabilized;
  PostStats stats;
  List<String> tags;
  String thumbnail;
  num timeStamp;
  String userID;
  // B10: Denormalize author alanları — her post için ayrı users/{uid} okuması önlenir.
  // Cloud Function (hybridFeed.ts / user profile update trigger) bu alanları senkronize tutar.
  String authorNickname;
  String authorDisplayName;
  String authorAvatarUrl;
  String rozet;
  String video;
  Map<String, dynamic> videoLook;
  String hlsMasterUrl;
  String hlsStatus;
  num hlsUpdatedAt;
  bool yorum;
  Map<String, dynamic> yorumMap;
  Map<String, dynamic> reshareMap;
  Map<String, dynamic> poll;

  PostsModel({
    required this.ad,
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
    this.isUploading = false,
    required this.izBirakYayinTarihi,
    required this.konum,
    this.locationCity = '',
    required this.mainFlood,
    required this.metin,
    required this.originalPostID,
    required this.originalUserID,
    this.quotedPost = false,
    this.quotedOriginalText = '',
    this.quotedSourceUserID = '',
    this.quotedSourceDisplayName = '',
    this.quotedSourceUsername = '',
    this.quotedSourceAvatarUrl = '',
    required this.paylasGizliligi,
    required this.scheduledAt,
    required this.sikayetEdildi,
    required this.stabilized,
    required this.stats,
    required this.tags,
    required this.thumbnail,
    required this.timeStamp,
    required this.userID,
    this.authorNickname = '',
    this.authorDisplayName = '',
    this.authorAvatarUrl = '',
    this.rozet = '',
    required this.video,
    this.videoLook = const {
      'preset': 'original',
      'version': 1,
      'intensity': 1.0,
    },
    this.hlsMasterUrl = '',
    this.hlsStatus = 'none',
    this.hlsUpdatedAt = 0,
    required this.yorum,
    this.yorumMap = const {},
    this.reshareMap = const {},
    this.poll = const {},
  });

  bool get hasHls => hlsMasterUrl.trim().isNotEmpty;

  bool get isHlsReady => hlsStatus == 'ready' && hasHls;

  bool get hasPlayableVideo => playbackUrl.trim().isNotEmpty;

  bool get shouldHideWhileUploading => isUploading;

  int get yorumVisibility {
    final v = yorumMap['visibility'];
    if (v is num) return v.toInt();
    if (v is String) {
      final parsed = int.tryParse(v);
      if (parsed != null) return parsed;
    }
    return yorum ? 0 : 3;
  }

  int get paylasimVisibility {
    final v = reshareMap['visibility'];
    if (v is num) return v.toInt();
    if (v is String) {
      final parsed = int.tryParse(v);
      if (parsed != null) return parsed;
    }
    return paylasGizliligi.toInt();
  }

  String get playbackUrl {
    if (isHlsReady) {
      final resolved = CdnUrlBuilder.toCdnUrl(hlsMasterUrl);
      if (kDebugMode) {
        debugPrint(
          '[PostsModel][$docID] playbackUrl=HLS ready status=$hlsStatus hlsMasterUrl=$hlsMasterUrl resolved=$resolved',
        );
      }
      return resolved;
    }
    final v = video.trim();
    if (hlsStatus == 'ready' && v.toLowerCase().contains('.m3u8')) {
      final resolved = CdnUrlBuilder.toCdnUrl(v);
      if (kDebugMode) {
        debugPrint(
          '[PostsModel][$docID] playbackUrl=legacy HLS status=$hlsStatus video=$v resolved=$resolved',
        );
      }
      return resolved;
    }
    if (kDebugMode && v.isNotEmpty) {
      debugPrint(
        '[PostsModel][$docID] playbackUrl EMPTY status=$hlsStatus hlsMasterUrl=${hlsMasterUrl.trim()} video=$v thumbnail=${thumbnail.trim()}',
      );
    }
    return '';
  }

  String get mp4FallbackUrl {
    return '';
  }

  String get cdnThumbnailUrl => CdnUrlBuilder.toCdnUrl(thumbnail);

  List<String> get cdnImgUrls => img.map(CdnUrlBuilder.toCdnUrl).toList();

  factory PostsModel.fromMap(Map<String, dynamic> data, String docID) {
    List<String> parseList(dynamic field) {
      if (field is List) return field.map((e) => e.toString()).toList();
      return <String>[];
    }

    List<String> parseImageUrls(dynamic field) {
      if (field is! List) return <String>[];
      final out = <String>[];
      for (final item in field) {
        if (item is Map) {
          final url = (item['url'] ?? '').toString().trim();
          if (url.isNotEmpty) out.add(url);
        } else {
          final url = item.toString().trim();
          if (url.isNotEmpty) out.add(url);
        }
      }
      return out;
    }

    num? parseFirstImageAspect(dynamic field) {
      if (field is! List || field.isEmpty) return null;
      final first = field.first;
      if (first is Map) {
        final v = first['aspectRatio'];
        if (v is num) return v;
        if (v is String) return num.tryParse(v);
      }
      return null;
    }

    num parseNum(dynamic value, [num fallback = 0]) {
      if (value is num) return value;
      if (value is Timestamp) return value.millisecondsSinceEpoch;
      if (value is String) return num.tryParse(value) ?? fallback;
      return fallback;
    }

    final parsedImgUrls = parseImageUrls(data['img']);
    final firstImgAspect = parseFirstImageAspect(data['imgMap']) ??
        parseFirstImageAspect(data['img']);
    final authorMap = data['author'] is Map<String, dynamic>
        ? data['author'] as Map<String, dynamic>
        : (data['author'] is Map
            ? Map<String, dynamic>.from(data['author'] as Map)
            : const <String, dynamic>{});
    final resolvedAuthorNickname = (data['authorNickname'] ??
            authorMap['nickname'] ??
            authorMap['username'] ??
            data['nickname'] ??
            '')
        .toString();
    final resolvedAuthorDisplayName = (data['authorDisplayName'] ??
            data['displayName'] ??
            data['fullName'] ??
            authorMap['displayName'] ??
            authorMap['fullName'] ??
            resolvedAuthorNickname)
        .toString();
    final resolvedAuthorAvatarUrl = (data['authorAvatarUrl'] ??
            authorMap['avatarUrl'] ??
            data['avatarUrl'] ??
            '')
        .toString();
    final resolvedRozet = (data['rozet'] ?? authorMap['rozet'] ?? '').toString();
    final resolvedUserId = (data['userID'] ??
            data['userId'] ??
            authorMap['userID'] ??
            authorMap['userId'] ??
            '')
        .toString()
        .trim();

    return PostsModel(
      ad: data['ad'] ?? false,
      arsiv: data['arsiv'] ?? false,
      aspectRatio: firstImgAspect ?? parseNum(data['aspectRatio'], 1.77),
      debugMode: data['debugMode'] ?? false,
      deletedPost: data['deletedPost'] ?? false,
      deletedPostTime: parseNum(data['deletedPostTime']),
      docID: docID,
      editTime: parseNum(data['editTime']),
      flood: data['flood'] ?? false,
      floodCount: parseNum(data['floodCount']),
      gizlendi: data['gizlendi'] ?? false,
      img: parsedImgUrls,
      isAd: data['isAd'] ?? false,
      isUploading: data['isUploading'] == true,
      izBirakYayinTarihi: parseNum(data['izBirakYayinTarihi']),
      konum: data['konum'] ?? '',
      locationCity: (data['locationCity'] ?? '').toString(),
      mainFlood: data['mainFlood'] ?? '',
      metin: data['metin'] ?? '',
      originalPostID: data['originalPostID'] ?? '',
      originalUserID: data['originalUserID'] ?? '',
      quotedPost: data['quotedPost'] ?? false,
      quotedOriginalText: (data['quotedOriginalText'] ?? '').toString(),
      quotedSourceUserID: (data['quotedSourceUserID'] ?? '').toString(),
      quotedSourceDisplayName:
          (data['quotedSourceDisplayName'] ?? '').toString(),
      quotedSourceUsername: (data['quotedSourceUsername'] ?? '').toString(),
      quotedSourceAvatarUrl: (data['quotedSourceAvatarUrl'] ?? '').toString(),
      paylasGizliligi: parseNum(data['paylasGizliligi'], 1),
      scheduledAt: parseNum(data['scheduledAt']),
      sikayetEdildi: data['sikayetEdildi'] ?? false,
      stabilized: data['stabilized'] ?? true,
      stats: PostStats.fromPostData(data),
      tags: parseList(data['tags']),
      thumbnail: data['thumbnail'] ?? '',
      timeStamp: parseNum(data['timeStamp']),
      userID: resolvedUserId,
      authorNickname: resolvedAuthorNickname,
      authorDisplayName: resolvedAuthorDisplayName,
      authorAvatarUrl: resolvedAuthorAvatarUrl,
      rozet: resolvedRozet,
      video: data['video'] ?? '',
      videoLook: data['videoLook'] is Map<String, dynamic>
          ? Map<String, dynamic>.from(data['videoLook'] as Map<String, dynamic>)
          : (data['videoLook'] is Map
              ? Map<String, dynamic>.from(data['videoLook'] as Map)
              : const {
                  'preset': 'original',
                  'version': 1,
                  'intensity': 1.0,
                }),
      hlsMasterUrl: data['hlsMasterUrl'] ?? '',
      hlsStatus: data['hlsStatus'] ?? 'none',
      hlsUpdatedAt: parseNum(data['hlsUpdatedAt']),
      yorum: data['yorum'] ?? true,
      yorumMap: Map<String, dynamic>.from(data['yorumMap'] ?? {}),
      reshareMap: Map<String, dynamic>.from(data['reshareMap'] ?? {}),
      poll: Map<String, dynamic>.from(data['poll'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'ad': ad,
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
      'isUploading': isUploading,
      'izBirakYayinTarihi': izBirakYayinTarihi,
      'konum': konum,
      'locationCity': locationCity,
      'mainFlood': mainFlood,
      'metin': metin,
      'originalPostID': originalPostID,
      'originalUserID': originalUserID,
      'quotedPost': quotedPost,
      'quotedOriginalText': quotedOriginalText,
      'quotedSourceUserID': quotedSourceUserID,
      'quotedSourceDisplayName': quotedSourceDisplayName,
      'quotedSourceUsername': quotedSourceUsername,
      'quotedSourceAvatarUrl': quotedSourceAvatarUrl,
      'paylasGizliligi': paylasGizliligi,
      'scheduledAt': scheduledAt,
      'sikayetEdildi': sikayetEdildi,
      'stabilized': stabilized,
      'stats': stats.toMap(),
      'tags': tags,
      'thumbnail': thumbnail,
      'timeStamp': timeStamp,
      'userID': userID,
      if (authorNickname.isNotEmpty) 'authorNickname': authorNickname,
      if (authorDisplayName.isNotEmpty) 'authorDisplayName': authorDisplayName,
      if (authorAvatarUrl.isNotEmpty) 'authorAvatarUrl': authorAvatarUrl,
      if (rozet.isNotEmpty) 'rozet': rozet,
      'video': video,
      'videoLook': videoLook,
      'hlsMasterUrl': hlsMasterUrl,
      'hlsStatus': hlsStatus,
      'hlsUpdatedAt': hlsUpdatedAt,
      'yorum': yorum,
      'yorumMap': yorumMap,
      'reshareMap': reshareMap,
      'poll': poll,
    };
  }

  factory PostsModel.empty() {
    return PostsModel(
      ad: false,
      arsiv: false,
      aspectRatio: 1.77,
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
      isUploading: false,
      izBirakYayinTarihi: 0,
      konum: '',
      locationCity: '',
      mainFlood: '',
      metin: '',
      originalPostID: '',
      originalUserID: '',
      quotedPost: false,
      quotedOriginalText: '',
      quotedSourceUserID: '',
      paylasGizliligi: 1,
      scheduledAt: 0,
      sikayetEdildi: false,
      stabilized: true,
      stats: PostStats(),
      tags: const [],
      thumbnail: '',
      timeStamp: 0,
      userID: '',
      authorNickname: '',
      authorDisplayName: '',
      authorAvatarUrl: '',
      rozet: '',
      video: '',
      videoLook: const {
        'preset': 'original',
        'version': 1,
        'intensity': 1.0,
      },
      hlsMasterUrl: '',
      hlsStatus: 'none',
      hlsUpdatedAt: 0,
      yorum: true,
      yorumMap: const {},
      reshareMap: const {},
      poll: const {},
    );
  }

  PostsModel copyWith({
    bool? ad,
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
    bool? isUploading,
    num? izBirakYayinTarihi,
    String? konum,
    String? locationCity,
    String? mainFlood,
    String? metin,
    String? originalPostID,
    String? originalUserID,
    bool? quotedPost,
    String? quotedOriginalText,
    String? quotedSourceUserID,
    String? quotedSourceDisplayName,
    String? quotedSourceUsername,
    String? quotedSourceAvatarUrl,
    num? paylasGizliligi,
    num? scheduledAt,
    bool? sikayetEdildi,
    bool? stabilized,
    PostStats? stats,
    List<String>? tags,
    String? thumbnail,
    num? timeStamp,
    String? userID,
    String? authorNickname,
    String? authorDisplayName,
    String? authorAvatarUrl,
    String? rozet,
    String? video,
    Map<String, dynamic>? videoLook,
    String? hlsMasterUrl,
    String? hlsStatus,
    num? hlsUpdatedAt,
    bool? yorum,
    Map<String, dynamic>? yorumMap,
    Map<String, dynamic>? reshareMap,
    Map<String, dynamic>? poll,
  }) {
    return PostsModel(
      ad: ad ?? this.ad,
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
      isUploading: isUploading ?? this.isUploading,
      izBirakYayinTarihi: izBirakYayinTarihi ?? this.izBirakYayinTarihi,
      konum: konum ?? this.konum,
      locationCity: locationCity ?? this.locationCity,
      mainFlood: mainFlood ?? this.mainFlood,
      metin: metin ?? this.metin,
      originalPostID: originalPostID ?? this.originalPostID,
      originalUserID: originalUserID ?? this.originalUserID,
      quotedPost: quotedPost ?? this.quotedPost,
      quotedOriginalText: quotedOriginalText ?? this.quotedOriginalText,
      quotedSourceUserID: quotedSourceUserID ?? this.quotedSourceUserID,
      quotedSourceDisplayName:
          quotedSourceDisplayName ?? this.quotedSourceDisplayName,
      quotedSourceUsername: quotedSourceUsername ?? this.quotedSourceUsername,
      quotedSourceAvatarUrl:
          quotedSourceAvatarUrl ?? this.quotedSourceAvatarUrl,
      paylasGizliligi: paylasGizliligi ?? this.paylasGizliligi,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      sikayetEdildi: sikayetEdildi ?? this.sikayetEdildi,
      stabilized: stabilized ?? this.stabilized,
      stats: stats ?? this.stats,
      tags: tags ?? this.tags,
      thumbnail: thumbnail ?? this.thumbnail,
      timeStamp: timeStamp ?? this.timeStamp,
      userID: userID ?? this.userID,
      authorNickname: authorNickname ?? this.authorNickname,
      authorDisplayName: authorDisplayName ?? this.authorDisplayName,
      authorAvatarUrl: authorAvatarUrl ?? this.authorAvatarUrl,
      rozet: rozet ?? this.rozet,
      video: video ?? this.video,
      videoLook: videoLook ?? this.videoLook,
      hlsMasterUrl: hlsMasterUrl ?? this.hlsMasterUrl,
      hlsStatus: hlsStatus ?? this.hlsStatus,
      hlsUpdatedAt: hlsUpdatedAt ?? this.hlsUpdatedAt,
      yorum: yorum ?? this.yorum,
      yorumMap: yorumMap ?? this.yorumMap,
      reshareMap: reshareMap ?? this.reshareMap,
      poll: poll ?? this.poll,
    );
  }

  factory PostsModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PostsModel.fromMap(data, doc.id);
  }
}
