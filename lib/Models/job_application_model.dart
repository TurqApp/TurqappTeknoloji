class JobApplicationModel {
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
      userID: map['userID'] ?? '',
      jobTitle: map['jobTitle'] ?? '',
      companyName: map['companyName'] ?? '',
      companyLogo: map['companyLogo'] ?? '',
      applicantName: map['applicantName'] ?? '',
      applicantNickname: map['applicantNickname'] ?? '',
      applicantPfImage: map['applicantPfImage'] ?? '',
      status: map['status'] ?? 'pending',
      timeStamp: map['timeStamp'] ?? 0,
      statusUpdatedAt: map['statusUpdatedAt'] ?? 0,
      note: map['note'] ?? '',
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
