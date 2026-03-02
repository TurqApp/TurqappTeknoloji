class JobApplicationModel {
  final String jobDocID;
  final String userID;
  final String jobTitle;
  final String companyName;
  final String companyLogo;
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
