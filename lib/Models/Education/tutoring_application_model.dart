class TutoringApplicationModel {
  final String tutoringDocID;
  final String userID;
  final String tutoringTitle;
  final String tutorName;
  final String tutorImage;
  final String status; // pending / reviewing / accepted / rejected
  final int timeStamp;
  final int statusUpdatedAt;
  final String note;

  TutoringApplicationModel({
    required this.tutoringDocID,
    required this.userID,
    required this.tutoringTitle,
    required this.tutorName,
    required this.tutorImage,
    required this.status,
    required this.timeStamp,
    this.statusUpdatedAt = 0,
    this.note = '',
  });

  factory TutoringApplicationModel.fromMap(
      Map<String, dynamic> map, String docID) {
    return TutoringApplicationModel(
      tutoringDocID: docID,
      userID: (map['userID'] ?? '').toString(),
      tutoringTitle: (map['tutoringTitle'] ?? '').toString(),
      tutorName: (map['tutorName'] ?? '').toString(),
      tutorImage: (map['tutorImage'] ?? '').toString(),
      status: (map['status'] ?? 'pending').toString(),
      timeStamp: (map['timeStamp'] as num?)?.toInt() ??
          int.tryParse((map['timeStamp'] ?? '').toString()) ??
          0,
      statusUpdatedAt: (map['statusUpdatedAt'] as num?)?.toInt() ??
          int.tryParse((map['statusUpdatedAt'] ?? '').toString()) ??
          0,
      note: (map['note'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userID': userID,
      'tutoringTitle': tutoringTitle,
      'tutorName': tutorName,
      'tutorImage': tutorImage,
      'status': status,
      'timeStamp': timeStamp,
      'statusUpdatedAt': statusUpdatedAt,
      'note': note,
    };
  }

  static String statusText(String status) {
    switch (status) {
      case 'pending':
        return 'Beklemede';
      case 'reviewing':
        return 'İnceleniyor';
      case 'accepted':
        return 'Kabul Edildi';
      case 'rejected':
        return 'Reddedildi';
      default:
        return 'Beklemede';
    }
  }
}
