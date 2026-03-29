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

  static int _asInt(Object? value) {
    if (value is num) return value.toInt();
    return int.tryParse((value ?? '').toString()) ?? 0;
  }

  static String _asString(Object? value) => (value ?? '').toString();

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
      userID: _asString(map['userID']),
      tutoringTitle: _asString(map['tutoringTitle']),
      tutorName: _asString(map['tutorName']),
      tutorImage: _asString(map['tutorImage']),
      status: _asString(map['status']).isEmpty
          ? 'pending'
          : _asString(map['status']),
      timeStamp: _asInt(map['timeStamp']),
      statusUpdatedAt: _asInt(map['statusUpdatedAt']),
      note: _asString(map['note']),
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
