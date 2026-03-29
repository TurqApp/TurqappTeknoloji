import 'package:cloud_firestore/cloud_firestore.dart';

class MessageModel {
  final String docID;
  final String rawDocID;
  final String source;
  final num timeStamp;
  final String userID;
  final num lat;
  final num long;
  final String postType;
  final String postID;
  final List<String> imgs;
  final String video;
  final bool isRead;
  final List<String> kullanicilar;
  final List<String> begeniler;
  final String metin;
  final String sesliMesaj;
  final String kisiAdSoyad;
  final String kisiTelefon;
  final bool isEdited;
  final bool isUnsent;
  final bool isForwarded;
  final String replyMessageId;
  final String replySenderId;
  final String replyText;
  final String replyType;
  final Map<String, List<String>> reactions;
  final String status; // "sent" | "delivered" | "read" | ""
  final String videoThumbnail;
  final int audioDurationMs;
  final bool isStarred;

  static List<String> _cloneStringList(Iterable<dynamic> source) {
    return source
        .map((item) => item.toString())
        .where((item) => item.trim().isNotEmpty)
        .toList(growable: false);
  }

  static Map<String, List<String>> _cloneReactionsMap(
    Map<String, List<String>> source,
  ) {
    return source.map(
      (key, value) => MapEntry(
        key,
        List<String>.from(value, growable: false),
      ),
    );
  }

  static String _asString(dynamic value, {String fallback = ''}) {
    if (value == null) return fallback;
    final normalized = value.toString();
    return normalized;
  }

  static num _asNum(dynamic value, {num fallback = 0}) {
    if (value is num) return value;
    return num.tryParse(value?.toString() ?? '') ?? fallback;
  }

  static int _asInt(dynamic value, {int fallback = 0}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }

  MessageModel({
    required this.docID,
    required this.rawDocID,
    required this.source,
    required this.timeStamp,
    required this.userID,
    required this.lat,
    required this.long,
    required this.postType,
    required this.postID,
    required List<String> imgs,
    required this.video,
    required this.isRead,
    required List<String> kullanicilar,
    required this.metin,
    required this.sesliMesaj,
    required this.kisiAdSoyad,
    required this.kisiTelefon,
    required List<String> begeniler,
    required this.isEdited,
    required this.isUnsent,
    required this.isForwarded,
    required this.replyMessageId,
    required this.replySenderId,
    required this.replyText,
    required this.replyType,
    required Map<String, List<String>> reactions,
    this.status = '',
    this.videoThumbnail = '',
    this.audioDurationMs = 0,
    this.isStarred = false,
  })  : imgs = List<String>.from(imgs, growable: false),
        kullanicilar = List<String>.from(kullanicilar, growable: false),
        begeniler = List<String>.from(begeniler, growable: false),
        reactions = _cloneReactionsMap(reactions);

  factory MessageModel.fromJson(Map<String, dynamic> json, String docID) {
    return MessageModel(
      docID: docID,
      rawDocID: _asString(json['rawDocID'], fallback: docID),
      source: _asString(json['source'], fallback: 'legacy'),
      timeStamp: _asNum(json['timeStamp']),
      userID: _asString(json['userID']),
      lat: _asNum(json['lat']),
      long: _asNum(json['long']),
      postType: _asString(json['postType']),
      postID: _asString(json['postID']),
      imgs: _cloneStringList(json['imgs'] ?? const []),
      video: _asString(json['video']),
      isRead: json['isRead'] ?? false,
      kullanicilar: _cloneStringList(json['kullanicilar'] ?? const []),
      begeniler: _cloneStringList(json['begeniler'] ?? const []),
      metin: _asString(json['metin']),
      sesliMesaj: _asString(json['sesliMesaj']),
      kisiAdSoyad: _asString(json['kisiAdSoyad']),
      kisiTelefon: _asString(json['kisiTelefon']),
      isEdited: json['isEdited'] ?? false,
      isUnsent: json['unsent'] ?? false,
      isForwarded: json['forwarded'] ?? false,
      replyMessageId: _asString(json['replyMessageId']),
      replySenderId: _asString(json['replySenderId']),
      replyText: _asString(json['replyText']),
      replyType: _asString(json['replyType']),
      reactions: _normalizeReactions(json['reactions']),
      status: _asString(json['status']),
      videoThumbnail: _asString(json['videoThumbnail']),
      audioDurationMs: _asInt(json['audioDurationMs']),
      isStarred: json['isStarred'] ?? false,
    );
  }

  factory MessageModel.fromSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MessageModel.fromJson(data, doc.id);
  }

  factory MessageModel.fromConversationSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return MessageModel.fromConversationData(data, doc.id);
  }

  factory MessageModel.fromConversationData(
    Map<String, dynamic> data,
    String docId,
  ) {
    final createdAt = data['createdDate'];
    num ts = 0;
    if (createdAt is Timestamp) {
      ts = createdAt.millisecondsSinceEpoch;
    } else if (createdAt is num) {
      ts = createdAt;
    }

    final mediaUrls = _cloneStringList(data['mediaUrls'] ?? const []);
    final location = data['location'] as Map<String, dynamic>?;
    final contact = data['contact'] as Map<String, dynamic>?;
    final postRef = data['postRef'] as Map<String, dynamic>?;
    final seenBy = _cloneStringList(data['seenBy'] ?? const []);
    final likes = _cloneStringList(data['likes'] ?? const []);
    final replyTo = data['replyTo'] as Map<String, dynamic>?;

    return MessageModel(
      docID: 'conv_$docId',
      rawDocID: docId,
      source: 'conversation',
      timeStamp: ts,
      userID: _asString(data['senderId']),
      lat: _asNum(location?['lat']),
      long: _asNum(location?['lng']),
      postType: _asString(postRef?['postType']),
      postID: _asString(postRef?['postId']),
      imgs: mediaUrls,
      video: _asString(data['videoUrl']),
      isRead: seenBy.length > 1,
      kullanicilar: [],
      begeniler: likes,
      metin: _asString(data['text']),
      sesliMesaj: _asString(data['audioUrl']),
      kisiAdSoyad: _asString(contact?['name']),
      kisiTelefon: _asString(contact?['phone']),
      isEdited: data['isEdited'] ?? false,
      isUnsent: data['unsent'] ?? false,
      isForwarded: data['forwarded'] ?? false,
      replyMessageId: _asString(replyTo?['messageId']),
      replySenderId: _asString(replyTo?['senderId']),
      replyText: _asString(replyTo?['text']),
      replyType: _asString(replyTo?['type']),
      reactions: _normalizeReactions(data['reactions']),
      status: _asString(data['status']),
      videoThumbnail: _asString(data['videoThumbnail']),
      audioDurationMs: _asInt(data['audioDurationMs']),
      isStarred: data['isStarred'] ?? false,
    );
  }

  static Map<String, List<String>> _normalizeReactions(dynamic raw) {
    if (raw is! Map) return {};
    final out = <String, List<String>>{};
    raw.forEach((key, value) {
      out[key.toString()] = _cloneStringList(value ?? const []);
    });
    return out;
  }
}
