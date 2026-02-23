import 'package:cloud_firestore/cloud_firestore.dart';

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
      userID: data['userID'] ?? '',
      timeStamp: (data['timeStamp'] ?? 0) as num,
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
    required this.likes,
    required this.text,
    required this.imgs,
    required this.videos,
    required this.timeStamp,
    required this.userID,
    required this.docID,
    this.edited = false,
    this.editTimestamp = 0,
    this.deleted = false,
    this.deletedTimeStamp = 0,
    this.hasReplies = false,
    this.repliesCount = 0,
  });

  factory PostCommentModel.fromMap(Map<String, dynamic> data, String docID) {
    return PostCommentModel(
      likes: List<String>.from(data['likes'] ?? []),
      text: data['text'] ?? '',
      imgs: List<String>.from(data['imgs'] ?? []),
      videos: List<String>.from(data['videos'] ?? []),
      timeStamp: (data['timeStamp'] ?? 0) as num,
      userID: data['userID'] ?? '',
      docID: docID,
      edited: data['edited'] ?? false,
      editTimestamp: (data['editTimestamp'] ?? 0) as num,
      deleted: data['deleted'] ?? false,
      deletedTimeStamp: (data['deletedTimeStamp'] ?? 0) as num,
      hasReplies: data['hasReplies'] ?? false,
      repliesCount: (data['repliesCount'] ?? 0) as num,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'likes': likes,
      'text': text,
      'imgs': imgs,
      'videos': videos,
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
    required this.likes,
    required this.text,
    required this.imgs,
    required this.videos,
    required this.timeStamp,
    required this.userID,
    required this.docID,
    this.edited = false,
    this.editTimestamp = 0,
    this.deleted = false,
    this.deletedTimeStamp = 0,
  });

  factory SubCommentModel.fromMap(Map<String, dynamic> data, String docID) {
    return SubCommentModel(
      likes: List<String>.from(data['likes'] ?? []),
      text: data['text'] ?? '',
      imgs: List<String>.from(data['imgs'] ?? []),
      videos: List<String>.from(data['videos'] ?? []),
      timeStamp: (data['timeStamp'] ?? 0) as num,
      userID: data['userID'] ?? '',
      docID: docID,
      edited: data['edited'] ?? false,
      editTimestamp: (data['editTimestamp'] ?? 0) as num,
      deleted: data['deleted'] ?? false,
      deletedTimeStamp: (data['deletedTimeStamp'] ?? 0) as num,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'likes': likes,
      'text': text,
      'imgs': imgs,
      'videos': videos,
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
  String? originalPostID; // Orijinal post ID'si (eğer bu post zaten bir reshare ise)

  PostReshareModel({
    required this.userID,
    required this.timeStamp,
    this.originalUserID,
    this.originalPostID,
  });

  factory PostReshareModel.fromMap(Map<String, dynamic> data) {
    return PostReshareModel(
      userID: data['userID'] ?? '',
      timeStamp: (data['timeStamp'] ?? 0) as num,
      originalUserID: data['originalUserID'],
      originalPostID: data['originalPostID'],
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
      userID: data['userID'] ?? '',
      timeStamp: (data['timeStamp'] ?? 0) as num,
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
      userID: data['userID'] ?? '',
      timeStamp: (data['timeStamp'] ?? 0) as num,
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
      userID: data['userID'] ?? '',
      timeStamp: (data['timeStamp'] ?? 0) as num,
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
      userID: data['userID'] ?? '',
      timeStamp: (data['timeStamp'] ?? 0) as num,
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
