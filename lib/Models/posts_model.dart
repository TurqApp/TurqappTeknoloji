import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:turqappv2/Core/Utils/cdn_url_builder.dart';
import 'package:turqappv2/Core/Utils/url_utils.dart';

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

  static num _asNum(dynamic value, {num fallback = 0}) {
    if (value is num) return value;
    if (value is Timestamp) {
      return value.millisecondsSinceEpoch;
    }
    if (value is String) {
      final parsed = num.tryParse(value.trim());
      if (parsed != null) return parsed;
    }
    return fallback;
  }

  factory PostStats.fromMap(Map<String, dynamic> data) {
    return PostStats(
      commentCount: _asNum(data['commentCount']),
      likeCount: _asNum(data['likeCount']),
      reportedCount: _asNum(data['reportedCount']),
      retryCount: _asNum(data['retryCount']),
      savedCount: _asNum(data['savedCount']),
      statsCount: _asNum(data['statsCount']),
    );
  }

  // Firebase'deki post verisinden stats oluşturur - sadece stats map kullanır
  factory PostStats.fromPostData(Map<String, dynamic> postData) {
    // Stats objesi içindeki değerleri al - zorunlu yapı
    final rawStats = postData['stats'];
    final statsData = rawStats is Map ? rawStats.cast<String, dynamic>() : null;

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

List<String> _clonePostsStringList(List<String> values) =>
    List<String>.from(values);

dynamic _clonePostsDynamicValue(dynamic value) {
  if (value is Map<String, dynamic>) {
    return _clonePostsDynamicMap(value);
  }
  if (value is Map) {
    return value.map(
      (key, nestedValue) =>
          MapEntry(key.toString(), _clonePostsDynamicValue(nestedValue)),
    );
  }
  if (value is List) {
    return value.map(_clonePostsDynamicValue).toList();
  }
  return value;
}

Map<String, dynamic> _clonePostsDynamicMap(Map<String, dynamic> value) =>
    value.map(
      (key, nestedValue) => MapEntry(key, _clonePostsDynamicValue(nestedValue)),
    );

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
  String shortId;
  String shortUrl;
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
    this.shortId = '',
    this.shortUrl = '',
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
  }) {
    img = _clonePostsStringList(img);
    tags = _clonePostsStringList(tags);
    videoLook = _clonePostsDynamicMap(videoLook);
    yorumMap = _clonePostsDynamicMap(yorumMap);
    reshareMap = _clonePostsDynamicMap(reshareMap);
    poll = _clonePostsDynamicMap(poll);
  }

  bool get hasHls => hlsMasterUrl.trim().isNotEmpty;

  bool get isHlsReady => hlsStatus == 'ready' && hasHls;

  bool get hasPlayableVideo => playbackUrl.trim().isNotEmpty;

  bool get hasVideoSignal =>
      video.trim().isNotEmpty || hlsMasterUrl.trim().isNotEmpty;

  bool get hasRenderableVideoCard =>
      hasPlayableVideo || (thumbnail.trim().isNotEmpty && hasVideoSignal);

  bool get hasTextContent => metin.trim().isNotEmpty;

  bool get hasImageContent =>
      img.isNotEmpty || thumbnail.trim().isNotEmpty;

  bool get hasQuoteContent =>
      quotedPost || quotedOriginalText.trim().isNotEmpty;

  bool get hasPollContent => poll.isNotEmpty;

  bool get isCompletelyEmptyPost =>
      !hasTextContent &&
      !hasImageContent &&
      !hasVideoSignal &&
      !hasQuoteContent &&
      !hasPollContent;

  bool get shouldHideWhileUploading =>
      isUploading || isCompletelyEmptyPost;

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
      return CdnUrlBuilder.toCdnUrl(hlsMasterUrl);
    }
    final v = video.trim();
    if (hlsStatus == 'ready' && isHlsPlaylistUrl(v)) {
      return CdnUrlBuilder.toCdnUrl(v);
    }
    return '';
  }

  String get mp4FallbackUrl {
    return '';
  }

  String get cdnThumbnailUrl => CdnUrlBuilder.toCdnUrl(thumbnail);

  List<String> get cdnImgUrls => img.map(CdnUrlBuilder.toCdnUrl).toList();

  List<String> get preferredVideoPosterUrls {
    final urls = <String>[];

    void addUrl(String url) {
      final normalized = CdnUrlBuilder.toCdnUrl(url).trim();
      if (normalized.isEmpty || urls.contains(normalized)) return;
      urls.add(normalized);
    }

    addUrl(thumbnail);
    if (img.isNotEmpty) {
      addUrl(img.first);
    }
    if (hasVideoSignal) {
      for (final candidate in CdnUrlBuilder.buildThumbnailUrlCandidates(docID)) {
        addUrl(candidate);
      }
    }
    return urls;
  }

  String get preferredVideoPosterUrl {
    final urls = preferredVideoPosterUrls;
    return urls.isEmpty ? '' : urls.first;
  }

  bool get isFloodMember => flood || mainFlood.trim().isNotEmpty;

  bool get isFloodSeriesRoot => !isFloodMember && floodCount.toInt() > 1;

  bool get isFloodSeriesContent => isFloodMember || isFloodSeriesRoot;

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
          if (url.isNotEmpty) out.add(CdnUrlBuilder.toCdnUrl(url));
        } else {
          final url = item.toString().trim();
          if (url.isNotEmpty) out.add(CdnUrlBuilder.toCdnUrl(url));
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
            '')
        .toString();
    final resolvedAuthorDisplayName = (data['authorDisplayName'] ??
            authorMap['displayName'] ??
            authorMap['fullName'] ??
            resolvedAuthorNickname)
        .toString();
    final resolvedAuthorAvatarUrl = CdnUrlBuilder.toCdnUrl(
      (data['authorAvatarUrl'] ?? authorMap['avatarUrl'] ?? '')
          .toString()
          .trim(),
    );
    final resolvedRozet =
        (data['rozet'] ?? authorMap['rozet'] ?? '').toString();
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
      quotedSourceAvatarUrl: CdnUrlBuilder.toCdnUrl(
        (data['quotedSourceAvatarUrl'] ?? '').toString().trim(),
      ),
      paylasGizliligi: parseNum(data['paylasGizliligi'], 1),
      scheduledAt: parseNum(data['scheduledAt']),
      sikayetEdildi: data['sikayetEdildi'] ?? false,
      stabilized: data['stabilized'] ?? true,
      stats: PostStats.fromPostData(data),
      tags: parseList(data['tags']),
      thumbnail: CdnUrlBuilder.toCdnUrl(
        (data['thumbnail'] ?? '').toString().trim(),
      ),
      timeStamp: parseNum(data['timeStamp']),
      userID: resolvedUserId,
      authorNickname: resolvedAuthorNickname,
      authorDisplayName: resolvedAuthorDisplayName,
      authorAvatarUrl: resolvedAuthorAvatarUrl,
      shortId: (data['shortId'] ?? '').toString(),
      shortUrl: (data['shortUrl'] ?? '').toString(),
      rozet: resolvedRozet,
      video: CdnUrlBuilder.toCdnUrl((data['video'] ?? '').toString().trim()),
      videoLook: data['videoLook'] is Map<String, dynamic>
          ? _clonePostsDynamicMap(data['videoLook'] as Map<String, dynamic>)
          : (data['videoLook'] is Map
              ? _clonePostsDynamicMap(
                  Map<String, dynamic>.from(data['videoLook'] as Map),
                )
              : const {
                  'preset': 'original',
                  'version': 1,
                  'intensity': 1.0,
                }),
      hlsMasterUrl: CdnUrlBuilder.toCdnUrl(
        (data['hlsMasterUrl'] ?? '').toString().trim(),
      ),
      hlsStatus: data['hlsStatus'] ?? 'none',
      hlsUpdatedAt: parseNum(data['hlsUpdatedAt']),
      yorum: data['yorum'] ?? true,
      yorumMap: _clonePostsDynamicMap(
        Map<String, dynamic>.from(data['yorumMap'] ?? {}),
      ),
      reshareMap: _clonePostsDynamicMap(
        Map<String, dynamic>.from(data['reshareMap'] ?? {}),
      ),
      poll: _clonePostsDynamicMap(
        Map<String, dynamic>.from(data['poll'] ?? {}),
      ),
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
      'img': _clonePostsStringList(img),
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
      'tags': _clonePostsStringList(tags),
      'thumbnail': thumbnail,
      'timeStamp': timeStamp,
      'userID': userID,
      if (authorNickname.isNotEmpty) 'authorNickname': authorNickname,
      if (authorDisplayName.isNotEmpty) 'authorDisplayName': authorDisplayName,
      if (authorAvatarUrl.isNotEmpty) 'authorAvatarUrl': authorAvatarUrl,
      if (shortId.isNotEmpty) 'shortId': shortId,
      if (shortUrl.isNotEmpty) 'shortUrl': shortUrl,
      if (rozet.isNotEmpty) 'rozet': rozet,
      'video': video,
      'videoLook': _clonePostsDynamicMap(videoLook),
      'hlsMasterUrl': hlsMasterUrl,
      'hlsStatus': hlsStatus,
      'hlsUpdatedAt': hlsUpdatedAt,
      'yorum': yorum,
      'yorumMap': _clonePostsDynamicMap(yorumMap),
      'reshareMap': _clonePostsDynamicMap(reshareMap),
      'poll': _clonePostsDynamicMap(poll),
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
      shortId: '',
      shortUrl: '',
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
    String? shortId,
    String? shortUrl,
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
      shortId: shortId ?? this.shortId,
      shortUrl: shortUrl ?? this.shortUrl,
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
