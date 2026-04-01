import 'package:cloud_firestore/cloud_firestore.dart';

num _interactionAsNum(Object? value) {
  if (value is num) return value;
  return num.tryParse((value ?? '').toString()) ?? 0;
}

// Like Modeli - Posts/{postID}/likes koleksiyonu için
class PostLikeModel {
  String userID;
  num timeStamp;

  PostLikeModel({
    required this.userID,
    required this.timeStamp,
  });

  factory PostLikeModel.fromMap(Map<String, dynamic> data) {
    return PostLikeModel(
      userID: (data['userID'] ?? '').toString(),
      timeStamp: _interactionAsNum(data['timeStamp']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userID': userID,
      'timeStamp': timeStamp,
    };
  }

  factory PostLikeModel.fromFirestore(DocumentSnapshot doc) {
    return PostLikeModel.fromMap(doc.data() as Map<String, dynamic>);
  }
}

// Comment Modeli - Posts/{postID}/comments koleksiyonu için
class PostCommentModel {
  static List<String> _cloneStringList(Iterable<dynamic> source) {
    return source
        .map((item) => item.toString())
        .where((item) => item.trim().isNotEmpty)
        .toList(growable: false);
  }

  List<String> likes;
  String text;
  List<String> imgs;
  List<String> videos;
  num timeStamp;
  String userID;
  String docID;
  bool edited;
  num editTimestamp;
  bool deleted;
  num deletedTimeStamp;
  bool hasReplies;
  num repliesCount;

  PostCommentModel({
    required List<String> likes,
    required this.text,
    required List<String> imgs,
    required List<String> videos,
    required this.timeStamp,
    required this.userID,
    required this.docID,
    this.edited = false,
    this.editTimestamp = 0,
    this.deleted = false,
    this.deletedTimeStamp = 0,
    this.hasReplies = false,
    this.repliesCount = 0,
  })  : likes = _cloneStringList(likes),
        imgs = _cloneStringList(imgs),
        videos = _cloneStringList(videos);

  factory PostCommentModel.fromMap(Map<String, dynamic> data, String docID) {
    return PostCommentModel(
      likes: _cloneStringList(data['likes'] ?? const []),
      text: (data['text'] ?? '').toString(),
      imgs: _cloneStringList(data['imgs'] ?? const []),
      videos: _cloneStringList(data['videos'] ?? const []),
      timeStamp: _interactionAsNum(data['timeStamp']),
      userID: (data['userID'] ?? '').toString(),
      docID: docID,
      edited: data['edited'] ?? false,
      editTimestamp: _interactionAsNum(data['editTimestamp']),
      deleted: data['deleted'] ?? false,
      deletedTimeStamp: _interactionAsNum(data['deletedTimeStamp']),
      hasReplies: data['hasReplies'] ?? false,
      repliesCount: _interactionAsNum(data['repliesCount']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'likes': _cloneStringList(likes),
      'text': text,
      'imgs': _cloneStringList(imgs),
      'videos': _cloneStringList(videos),
      'timeStamp': timeStamp,
      'userID': userID,
      'edited': edited,
      'editTimestamp': editTimestamp,
      'deleted': deleted,
      'deletedTimeStamp': deletedTimeStamp,
      'hasReplies': hasReplies,
      'repliesCount': repliesCount,
    };
  }

  factory PostCommentModel.fromFirestore(DocumentSnapshot doc) {
    return PostCommentModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
  }
}

// Sub Comment Modeli - Posts/{postID}/comments/{commentID}/sub_comments için
class SubCommentModel {
  static List<String> _cloneStringList(Iterable<dynamic> source) {
    return source
        .map((item) => item.toString())
        .where((item) => item.trim().isNotEmpty)
        .toList(growable: false);
  }

  List<String> likes;
  String text;
  List<String> imgs;
  List<String> videos;
  num timeStamp;
  String userID;
  String docID;
  bool edited;
  num editTimestamp;
  bool deleted;
  num deletedTimeStamp;

  SubCommentModel({
    required List<String> likes,
    required this.text,
    required List<String> imgs,
    required List<String> videos,
    required this.timeStamp,
    required this.userID,
    required this.docID,
    this.edited = false,
    this.editTimestamp = 0,
    this.deleted = false,
    this.deletedTimeStamp = 0,
  })  : likes = _cloneStringList(likes),
        imgs = _cloneStringList(imgs),
        videos = _cloneStringList(videos);

  factory SubCommentModel.fromMap(Map<String, dynamic> data, String docID) {
    return SubCommentModel(
      likes: _cloneStringList(data['likes'] ?? const []),
      text: (data['text'] ?? '').toString(),
      imgs: _cloneStringList(data['imgs'] ?? const []),
      videos: _cloneStringList(data['videos'] ?? const []),
      timeStamp: _interactionAsNum(data['timeStamp']),
      userID: (data['userID'] ?? '').toString(),
      docID: docID,
      edited: data['edited'] ?? false,
      editTimestamp: _interactionAsNum(data['editTimestamp']),
      deleted: data['deleted'] ?? false,
      deletedTimeStamp: _interactionAsNum(data['deletedTimeStamp']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'likes': _cloneStringList(likes),
      'text': text,
      'imgs': _cloneStringList(imgs),
      'videos': _cloneStringList(videos),
      'timeStamp': timeStamp,
      'userID': userID,
      'edited': edited,
      'editTimestamp': editTimestamp,
      'deleted': deleted,
      'deletedTimeStamp': deletedTimeStamp,
    };
  }

  factory SubCommentModel.fromFirestore(DocumentSnapshot doc) {
    return SubCommentModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
  }
}

// Reshare Modeli - Posts/{postID}/reshares için
class PostReshareModel {
  String userID;
  num timeStamp;
  String? originalUserID; // Orijinal post sahibi
  String?
      originalPostID; // Orijinal post ID'si (eğer bu post zaten bir reshare ise)

  PostReshareModel({
    required this.userID,
    required this.timeStamp,
    this.originalUserID,
    this.originalPostID,
  });

  factory PostReshareModel.fromMap(Map<String, dynamic> data) {
    return PostReshareModel(
      userID: (data['userID'] ?? '').toString(),
      timeStamp: _interactionAsNum(data['timeStamp']),
      originalUserID: data['originalUserID']?.toString(),
      originalPostID: data['originalPostID']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    final map = {
      'userID': userID,
      'timeStamp': timeStamp,
    };

    if (originalUserID != null && originalUserID!.isNotEmpty) {
      map['originalUserID'] = originalUserID!;
    }

    if (originalPostID != null && originalPostID!.isNotEmpty) {
      map['originalPostID'] = originalPostID!;
    }

    return map;
  }

  factory PostReshareModel.fromFirestore(DocumentSnapshot doc) {
    return PostReshareModel.fromMap(doc.data() as Map<String, dynamic>);
  }
}

// Shared As Modeli - Posts/{postID}/shared_as için
class PostSharedAsModel {
  String userID;
  num timeStamp;

  PostSharedAsModel({
    required this.userID,
    required this.timeStamp,
  });

  factory PostSharedAsModel.fromMap(Map<String, dynamic> data) {
    return PostSharedAsModel(
      userID: (data['userID'] ?? '').toString(),
      timeStamp: _interactionAsNum(data['timeStamp']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userID': userID,
      'timeStamp': timeStamp,
    };
  }

  factory PostSharedAsModel.fromFirestore(DocumentSnapshot doc) {
    return PostSharedAsModel.fromMap(doc.data() as Map<String, dynamic>);
  }
}

// Saved Modeli - Posts/{postID}/saveds için
class PostSavedModel {
  String userID;
  num timeStamp;

  PostSavedModel({
    required this.userID,
    required this.timeStamp,
  });

  factory PostSavedModel.fromMap(Map<String, dynamic> data) {
    return PostSavedModel(
      userID: (data['userID'] ?? '').toString(),
      timeStamp: _interactionAsNum(data['timeStamp']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userID': userID,
      'timeStamp': timeStamp,
    };
  }

  factory PostSavedModel.fromFirestore(DocumentSnapshot doc) {
    return PostSavedModel.fromMap(doc.data() as Map<String, dynamic>);
  }
}

// Viewer Modeli - Posts/{postID}/viewers için (Güncellendi)
class PostViewerModel {
  String userID;
  num timeStamp;

  PostViewerModel({
    required this.userID,
    required this.timeStamp,
  });

  factory PostViewerModel.fromMap(Map<String, dynamic> data) {
    return PostViewerModel(
      userID: (data['userID'] ?? '').toString(),
      timeStamp: _interactionAsNum(data['timeStamp']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userID': userID,
      'timeStamp': timeStamp,
    };
  }

  factory PostViewerModel.fromFirestore(DocumentSnapshot doc) {
    return PostViewerModel.fromMap(doc.data() as Map<String, dynamic>);
  }
}

// Reporter Modeli - Posts/{postID}/reporters için
class PostReporterModel {
  String userID;
  num timeStamp;

  PostReporterModel({
    required this.userID,
    required this.timeStamp,
  });

  factory PostReporterModel.fromMap(Map<String, dynamic> data) {
    return PostReporterModel(
      userID: (data['userID'] ?? '').toString(),
      timeStamp: _interactionAsNum(data['timeStamp']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userID': userID,
      'timeStamp': timeStamp,
    };
  }

  factory PostReporterModel.fromFirestore(DocumentSnapshot doc) {
    return PostReporterModel.fromMap(doc.data() as Map<String, dynamic>);
  }
}
