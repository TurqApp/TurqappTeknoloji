class JobApplicationModel {
  static int _asInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse((value ?? '').toString()) ?? 0;
  }

  final String jobDocID;
  final String userID;
  final String jobTitle;
  final String companyName;
  final String companyLogo;
  final String applicantName;
  final String applicantNickname;
  final String applicantPfImage;
  final String status; // pending / reviewing / accepted / rejected
  final int timeStamp;
  final int statusUpdatedAt;
  final String note;

  JobApplicationModel({
    required this.jobDocID,
    required this.userID,
    required this.jobTitle,
    required this.companyName,
    required this.companyLogo,
    this.applicantName = '',
    this.applicantNickname = '',
    this.applicantPfImage = '',
    required this.status,
    required this.timeStamp,
    this.statusUpdatedAt = 0,
    this.note = '',
  });

  factory JobApplicationModel.fromMap(Map<String, dynamic> map, String docID) {
    return JobApplicationModel(
      jobDocID: docID,
      userID: (map['userID'] ?? '').toString(),
      jobTitle: (map['jobTitle'] ?? '').toString(),
      companyName: (map['companyName'] ?? '').toString(),
      companyLogo: (map['companyLogo'] ?? '').toString(),
      applicantName: (map['applicantName'] ?? '').toString(),
      applicantNickname: (map['applicantNickname'] ?? '').toString(),
      applicantPfImage: (map['applicantPfImage'] ?? '').toString(),
      status: (map['status'] ?? 'pending').toString(),
      timeStamp: _asInt(map['timeStamp']),
      statusUpdatedAt: _asInt(map['statusUpdatedAt']),
      note: (map['note'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userID': userID,
      'jobTitle': jobTitle,
      'companyName': companyName,
      'companyLogo': companyLogo,
      'applicantName': applicantName,
      'applicantNickname': applicantNickname,
      'applicantPfImage': applicantPfImage,
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
