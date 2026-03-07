import 'package:cloud_firestore/cloud_firestore.dart';

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
      userID: data['userID'] ?? '',
      timestamp: (data['timestamp'] ?? 0) as num,
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
      userID: data['userID'] ?? '',
      text: data['text'] ?? '',
      timestamp: (data['timestamp'] ?? 0) as num,
      likes: CommentLikes.fromMap(data['likes'] ?? {}),
      parentCommentID: data['parentCommentID'],
      edited: data['edited'] ?? false,
      editTimestamp: (data['editTimestamp'] ?? 0) as num,
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

  CommentLikes({
    this.count = 0,
    this.userIDs = const [],
  });

  factory CommentLikes.fromMap(Map<String, dynamic> data) {
    return CommentLikes(
      count: (data['count'] ?? 0) as num,
      userIDs: List<String>.from(data['userIDs'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'count': count,
      'userIDs': userIDs,
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
      userID: data['userID'] ?? '',
      timestamp: (data['timestamp'] ?? 0) as num,
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
      userID: data['userID'] ?? '',
      timestamp: (data['timestamp'] ?? 0) as num,
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
      userID: data['userID'] ?? '',
      timestamp: (data['timestamp'] ?? 0) as num,
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
