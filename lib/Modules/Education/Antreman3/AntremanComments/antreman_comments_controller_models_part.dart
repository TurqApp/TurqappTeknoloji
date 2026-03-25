part of 'antreman_comments_controller.dart';

class Comment {
  final String docID;
  final String userID;
  final String metin;
  final int timeStamp;
  final List<String> begeniler;
  final String? photoUrl;

  Comment({
    required this.docID,
    required this.userID,
    required this.metin,
    required this.timeStamp,
    required this.begeniler,
    this.photoUrl,
  });

  factory Comment.fromJson(String docID, Map<String, dynamic> json) {
    return Comment(
      docID: docID,
      userID: json['userID'] ?? '',
      metin: json['metin'] ?? '',
      timeStamp: json['timeStamp'] ?? 0,
      begeniler: List<String>.from(json['begeniler'] ?? []),
      photoUrl: json['photoUrl'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userID': userID,
      'metin': metin,
      'timeStamp': timeStamp,
      'begeniler': begeniler,
      'photoUrl': photoUrl,
    };
  }
}

class Reply {
  final String docID;
  final String userID;
  final String metin;
  final int timeStamp;
  final List<String> begeniler;
  final String? photoUrl;

  Reply({
    required this.docID,
    required this.userID,
    required this.metin,
    required this.timeStamp,
    required this.begeniler,
    this.photoUrl,
  });

  factory Reply.fromJson(String docID, Map<String, dynamic> json) {
    return Reply(
      docID: docID,
      userID: json['userID'] ?? '',
      metin: json['metin'] ?? '',
      timeStamp: json['timeStamp'] ?? 0,
      begeniler: List<String>.from(json['begeniler'] ?? []),
      photoUrl: json['photoUrl'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userID': userID,
      'metin': metin,
      'timeStamp': timeStamp,
      'begeniler': begeniler,
      'photoUrl': photoUrl,
    };
  }
}
