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
    required this.imgs,
    required this.video,
    required this.isRead,
    required this.kullanicilar,
    required this.metin,
    required this.sesliMesaj,
    required this.kisiAdSoyad,
    required this.kisiTelefon,
    required this.begeniler,
    required this.isEdited,
    required this.isUnsent,
    required this.isForwarded,
    required this.replyMessageId,
    required this.replySenderId,
    required this.replyText,
    required this.replyType,
    required this.reactions,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json, String docID) {
    return MessageModel(
      docID: docID,
      rawDocID: json['rawDocID'] ?? docID,
      source: json['source'] ?? 'legacy',
      timeStamp: json['timeStamp'] ?? 0,
      userID: json['userID'] ?? '',
      lat: json['lat'] ?? 0,
      long: json['long'] ?? 0,
      postType: json['postType'] ?? '',
      postID: json['postID'] ?? '',
      imgs: List<String>.from(json['imgs'] ?? []),
      video: json['video'] ?? '',
      isRead: json['isRead'] ?? false,
      kullanicilar: List<String>.from(json['kullanicilar'] ?? []),
      begeniler: List<String>.from(json['begeniler'] ?? []),
      metin: json['metin'] ?? '',
      sesliMesaj: json['sesliMesaj'] ?? '',
      kisiAdSoyad: json['kisiAdSoyad'] ?? '',
      kisiTelefon: json['kisiTelefon'] ?? '',
      isEdited: json['isEdited'] ?? false,
      isUnsent: json['unsent'] ?? false,
      isForwarded: json['forwarded'] ?? false,
      replyMessageId: json['replyMessageId'] ?? '',
      replySenderId: json['replySenderId'] ?? '',
      replyText: json['replyText'] ?? '',
      replyType: json['replyType'] ?? '',
      reactions: _normalizeReactions(json['reactions']),
    );
  }

  factory MessageModel.fromSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MessageModel.fromJson(data, doc.id);
  }

  factory MessageModel.fromConversationSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final createdAt = data['createdAt'];
    num ts = 0;
    if (createdAt is Timestamp) {
      ts = createdAt.millisecondsSinceEpoch;
    } else if (createdAt is num) {
      ts = createdAt;
    }

    final mediaUrls = List<String>.from(data['mediaUrls'] ?? []);
    final location = data['location'] as Map<String, dynamic>?;
    final contact = data['contact'] as Map<String, dynamic>?;
    final postRef = data['postRef'] as Map<String, dynamic>?;
    final seenBy = List<String>.from(data['seenBy'] ?? []);
    final likes = List<String>.from(data['likes'] ?? []);
    final replyTo = data['replyTo'] as Map<String, dynamic>?;

    return MessageModel(
      docID: 'conv_${doc.id}',
      rawDocID: doc.id,
      source: 'conversation',
      timeStamp: ts,
      userID: data['senderId'] ?? '',
      lat: (location?['lat'] ?? 0).toDouble(),
      long: (location?['lng'] ?? 0).toDouble(),
      postType: postRef?['postType'] ?? '',
      postID: postRef?['postId'] ?? '',
      imgs: mediaUrls,
      video: '',
      isRead: seenBy.length > 1,
      kullanicilar: [],
      begeniler: likes,
      metin: data['text'] ?? '',
      sesliMesaj: data['audioUrl'] ?? '',
      kisiAdSoyad: contact?['name'] ?? '',
      kisiTelefon: contact?['phone'] ?? '',
      isEdited: data['isEdited'] ?? false,
      isUnsent: data['unsent'] ?? false,
      isForwarded: data['forwarded'] ?? false,
      replyMessageId: replyTo?['messageId'] ?? '',
      replySenderId: replyTo?['senderId'] ?? '',
      replyText: replyTo?['text'] ?? '',
      replyType: replyTo?['type'] ?? '',
      reactions: _normalizeReactions(data['reactions']),
    );
  }

  static Map<String, List<String>> _normalizeReactions(dynamic raw) {
    if (raw is! Map) return {};
    final out = <String, List<String>>{};
    raw.forEach((key, value) {
      out[key.toString()] = List<String>.from(value ?? const []);
    });
    return out;
  }
}
