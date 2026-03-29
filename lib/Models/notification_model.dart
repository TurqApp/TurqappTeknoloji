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
      isRead: (json['isRead'] ?? json['read'] ?? false) == true,
      type: (json['type'] ?? '').toString(),
      postID: (json['postID'] ?? '').toString(),
      postType: (json['postType'] ?? '').toString(),
      thumbnail:
          (json['thumbnail'] ?? json['imageUrl'] ?? json['imageURL'] ?? '')
              .toString(),
      timeStamp: (json['timeStamp'] as num?)?.toInt() ??
          int.tryParse((json['timeStamp'] ?? '').toString()) ??
          0,
      title: (json['title'] ?? '').toString(),
      userID: (json['userID'] ?? '').toString(),
      desc: (json['desc'] ?? '').toString(),
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
