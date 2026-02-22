import 'package:cloud_firestore/cloud_firestore.dart';

// Kullanıcı Beğendiği Postlar - users/{userID}/liked_posts
class UserLikedPostModel {
  String postDocID;
  num timeStamp;

  UserLikedPostModel({
    required this.postDocID,
    required this.timeStamp,
  });

  factory UserLikedPostModel.fromMap(Map<String, dynamic> data) {
    return UserLikedPostModel(
      postDocID: data['post_docID'] ?? '',
      timeStamp: (data['timeStamp'] ?? 0) as num,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'post_docID': postDocID,
      'timeStamp': timeStamp,
    };
  }

  factory UserLikedPostModel.fromFirestore(DocumentSnapshot doc) {
    return UserLikedPostModel.fromMap(doc.data() as Map<String, dynamic>);
  }
}

// Kullanıcı Kaydettiği Postlar - users/{userID}/saved_posts
class UserSavedPostModel {
  String postDocID;
  num timeStamp;

  UserSavedPostModel({
    required this.postDocID,
    required this.timeStamp,
  });

  factory UserSavedPostModel.fromMap(Map<String, dynamic> data) {
    return UserSavedPostModel(
      postDocID: data['post_docID'] ?? '',
      timeStamp: (data['timeStamp'] ?? 0) as num,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'post_docID': postDocID,
      'timeStamp': timeStamp,
    };
  }

  factory UserSavedPostModel.fromFirestore(DocumentSnapshot doc) {
    return UserSavedPostModel.fromMap(doc.data() as Map<String, dynamic>);
  }
}

// Kullanıcı Yorum Yaptığı Postlar - users/{userID}/commented_posts
class UserCommentedPostModel {
  String postDocID;
  num timeStamp;

  UserCommentedPostModel({
    required this.postDocID,
    required this.timeStamp,
  });

  factory UserCommentedPostModel.fromMap(Map<String, dynamic> data) {
    return UserCommentedPostModel(
      postDocID: data['post_docID'] ?? '',
      timeStamp: (data['timeStamp'] ?? 0) as num,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'post_docID': postDocID,
      'timeStamp': timeStamp,
    };
  }

  factory UserCommentedPostModel.fromFirestore(DocumentSnapshot doc) {
    return UserCommentedPostModel.fromMap(doc.data() as Map<String, dynamic>);
  }
}

// Kullanıcı Yeniden Paylaştığı Postlar - users/{userID}/reshared_posts
class UserResharedPostModel {
  String postDocID;
  num timeStamp;
  String? originalUserID; // Orijinal post sahibi
  String? originalPostID; // Orijinal post ID'si (eğer bu post zaten bir reshare ise)

  UserResharedPostModel({
    required this.postDocID,
    required this.timeStamp,
    this.originalUserID,
    this.originalPostID,
  });

  factory UserResharedPostModel.fromMap(Map<String, dynamic> data) {
    return UserResharedPostModel(
      postDocID: data['post_docID'] ?? '',
      timeStamp: (data['timeStamp'] ?? 0) as num,
      originalUserID: data['originalUserID'],
      originalPostID: data['originalPostID'],
    );
  }

  Map<String, dynamic> toMap() {
    final map = {
      'post_docID': postDocID,
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

  factory UserResharedPostModel.fromFirestore(DocumentSnapshot doc) {
    return UserResharedPostModel.fromMap(doc.data() as Map<String, dynamic>);
  }
}

// Kullanıcı Gönderi Olarak Paylaştığı Postlar - users/{userID}/shared_as_posts
class UserSharedAsPostModel {
  String postDocID;
  num timeStamp;

  UserSharedAsPostModel({
    required this.postDocID,
    required this.timeStamp,
  });

  factory UserSharedAsPostModel.fromMap(Map<String, dynamic> data) {
    return UserSharedAsPostModel(
      postDocID: data['post_docID'] ?? '',
      timeStamp: (data['timeStamp'] ?? 0) as num,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'post_docID': postDocID,
      'timeStamp': timeStamp,
    };
  }

  factory UserSharedAsPostModel.fromFirestore(DocumentSnapshot doc) {
    return UserSharedAsPostModel.fromMap(doc.data() as Map<String, dynamic>);
  }
}

// Bildirim Modeli - users/{userID}/notifications
class NotificationModel {
  String type; // "like|comment|reshared_posts|follow|shared_as_posts|message"
  String fromUserID;
  String postID;
  num timeStamp;
  bool read;

  NotificationModel({
    required this.type,
    required this.fromUserID,
    required this.postID,
    required this.timeStamp,
    this.read = false,
  });

  factory NotificationModel.fromMap(Map<String, dynamic> data) {
    return NotificationModel(
      type: data['type'] ?? '',
      fromUserID: data['fromUserID'] ?? '',
      postID: data['postID'] ?? '',
      timeStamp: (data['timeStamp'] ?? 0) as num,
      read: data['read'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'fromUserID': fromUserID,
      'postID': postID,
      'timeStamp': timeStamp,
      'read': read,
    };
  }

  factory NotificationModel.fromFirestore(DocumentSnapshot doc) {
    return NotificationModel.fromMap(doc.data() as Map<String, dynamic>);
  }

  // Notification factory methods
  factory NotificationModel.createLike({
    required String fromUserID,
    required String postID,
  }) {
    return NotificationModel(
      type: 'like',
      fromUserID: fromUserID,
      postID: postID,
      timeStamp: DateTime.now().millisecondsSinceEpoch,
    );
  }

  factory NotificationModel.createComment({
    required String fromUserID,
    required String postID,
  }) {
    return NotificationModel(
      type: 'comment',
      fromUserID: fromUserID,
      postID: postID,
      timeStamp: DateTime.now().millisecondsSinceEpoch,
    );
  }

  factory NotificationModel.createReshare({
    required String fromUserID,
    required String postID,
  }) {
    return NotificationModel(
      type: 'reshared_posts',
      fromUserID: fromUserID,
      postID: postID,
      timeStamp: DateTime.now().millisecondsSinceEpoch,
    );
  }

  factory NotificationModel.createSharedAs({
    required String fromUserID,
    required String postID,
  }) {
    return NotificationModel(
      type: 'shared_as_posts',
      fromUserID: fromUserID,
      postID: postID,
      timeStamp: DateTime.now().millisecondsSinceEpoch,
    );
  }
}