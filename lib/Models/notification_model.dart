class NotificationModel {
  String docID;
  bool isRead;
  String type;
  String desc;
  String postID;
  String postType;
  String thumbnail;
  num timeStamp;
  String title;
  String userID;

  static String _asString(Object? value) => (value ?? '').toString();

  static int _asInt(Object? value) {
    if (value is num) return value.toInt();
    return int.tryParse(_asString(value)) ?? 0;
  }

  static bool _asBool(Object? value) {
    if (value is bool) return value;
    final raw = _asString(value).trim().toLowerCase();
    return raw == 'true' || raw == '1';
  }

  NotificationModel({
    required this.docID,
    required this.desc,
    required this.isRead,
    required this.type,
    required this.postID,
    required this.postType,
    required this.thumbnail,
    required this.timeStamp,
    required this.title,
    required this.userID,
  });

  // Firebase'den gelen veriyi modele dönüştürmek için
  factory NotificationModel.fromJson(Map<String, dynamic> json, String docID) {
    return NotificationModel(
      docID: docID,
      isRead: _asBool(json['isRead'] ?? json['read']),
      type: _asString(json['type']),
      postID: _asString(json['postID']),
      postType: _asString(json['postType']),
      thumbnail: _asString(
        json['thumbnail'] ?? json['imageUrl'] ?? json['imageURL'],
      ),
      timeStamp: _asInt(json['timeStamp']),
      title: _asString(json['title']),
      userID: _asString(json['userID']),
      desc: _asString(json['desc']),
    );
  }

  // Firestore'a veri gönderirken kullanılabilecek toJson metodu
  Map<String, dynamic> toJson() {
    return {
      'isRead': isRead,
      'read': isRead,
      'type': type,
      'postID': postID,
      'postType': postType,
      'thumbnail': thumbnail,
      'timeStamp': timeStamp,
      'title': title,
      'userID': userID,
      'desc': desc
    };
  }
}
