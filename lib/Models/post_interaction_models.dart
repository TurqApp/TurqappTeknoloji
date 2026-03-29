import 'package:cloud_firestore/cloud_firestore.dart';

num _parseLegacyInteractionNum(dynamic raw) {
  if (raw is num) return raw;
  if (raw is Timestamp) return raw.millisecondsSinceEpoch;
  return num.tryParse(raw?.toString() ?? '') ?? 0;
}

// Beğeni modeli
class PostLikeModel {
  String userID;
  num timestamp;

  PostLikeModel({
    required this.userID,
    required this.timestamp,
  });

  factory PostLikeModel.fromMap(Map<String, dynamic> data, String docID) {
    return PostLikeModel(
      userID: (data['userID'] ?? '').toString(),
      timestamp: _parseLegacyInteractionNum(data['timestamp']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userID': userID,
      'timestamp': timestamp,
    };
  }

  factory PostLikeModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PostLikeModel.fromMap(data, doc.id);
  }
}

// Yorum modeli
class PostCommentModel {
  String userID;
  String text;
  num timestamp;
  CommentLikes likes;
  String? parentCommentID;
  bool edited;
  num editTimestamp;

  PostCommentModel({
    required this.userID,
    required this.text,
    required this.timestamp,
    required this.likes,
    this.parentCommentID,
    this.edited = false,
    this.editTimestamp = 0,
  });

  factory PostCommentModel.fromMap(Map<String, dynamic> data, String docID) {
    return PostCommentModel(
      userID: (data['userID'] ?? '').toString(),
      text: (data['text'] ?? '').toString(),
      timestamp: _parseLegacyInteractionNum(data['timestamp']),
      likes: CommentLikes.fromMap(
        (data['likes'] as Map?)?.cast<String, dynamic>() ?? const {},
      ),
      parentCommentID: (data['parentCommentID'] ?? '').toString().trim().isEmpty
          ? null
          : (data['parentCommentID'] ?? '').toString(),
      edited: data['edited'] ?? false,
      editTimestamp: _parseLegacyInteractionNum(data['editTimestamp']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userID': userID,
      'text': text,
      'timestamp': timestamp,
      'likes': likes.toMap(),
      if (parentCommentID != null) 'parentCommentID': parentCommentID,
      'edited': edited,
      'editTimestamp': editTimestamp,
    };
  }

  factory PostCommentModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PostCommentModel.fromMap(data, doc.id);
  }
}

// Yorum beğenileri için yardımcı sınıf
class CommentLikes {
  num count;
  List<String> userIDs;

  static List<String> _cloneStringList(List<String> source) =>
      List<String>.from(source, growable: false);

  static List<String> _sanitizeUserIds(dynamic raw) {
    if (raw is! List) return const <String>[];
    final sanitized = <String>[];
    for (final item in raw) {
      final userId = item?.toString().trim() ?? '';
      if (userId.isEmpty) continue;
      sanitized.add(userId);
    }
    return List<String>.from(sanitized, growable: false);
  }

  CommentLikes({
    this.count = 0,
    List<String> userIDs = const [],
  }) : userIDs = _cloneStringList(userIDs);

  factory CommentLikes.fromMap(Map<String, dynamic> data) {
    return CommentLikes(
      count: (data['count'] ?? 0) as num,
      userIDs: _sanitizeUserIds(data['userIDs']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'count': count,
      'userIDs': _cloneStringList(userIDs),
    };
  }
}

// Kaydedme modeli
class PostSavedModel {
  String userID;
  num timestamp;

  PostSavedModel({
    required this.userID,
    required this.timestamp,
  });

  factory PostSavedModel.fromMap(Map<String, dynamic> data, String docID) {
    return PostSavedModel(
      userID: (data['userID'] ?? '').toString(),
      timestamp: _parseLegacyInteractionNum(data['timestamp']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userID': userID,
      'timestamp': timestamp,
    };
  }

  factory PostSavedModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PostSavedModel.fromMap(data, doc.id);
  }
}

// Yeniden paylaşma modeli
class PostReshareModel {
  String userID;
  num timestamp;

  PostReshareModel({
    required this.userID,
    required this.timestamp,
  });

  factory PostReshareModel.fromMap(Map<String, dynamic> data, String docID) {
    return PostReshareModel(
      userID: (data['userID'] ?? '').toString(),
      timestamp: _parseLegacyInteractionNum(data['timestamp']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userID': userID,
      'timestamp': timestamp,
    };
  }

  factory PostReshareModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PostReshareModel.fromMap(data, doc.id);
  }
}

// Görüntüleme modeli
class PostViewerModel {
  String userID;
  num timestamp;

  PostViewerModel({
    required this.userID,
    required this.timestamp,
  });

  factory PostViewerModel.fromMap(Map<String, dynamic> data, String docID) {
    return PostViewerModel(
      userID: (data['userID'] ?? '').toString(),
      timestamp: _parseLegacyInteractionNum(data['timestamp']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userID': userID,
      'timestamp': timestamp,
    };
  }

  factory PostViewerModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PostViewerModel.fromMap(data, doc.id);
  }
}
