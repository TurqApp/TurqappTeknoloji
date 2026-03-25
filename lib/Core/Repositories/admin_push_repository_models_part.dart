part of 'admin_push_repository.dart';

class AdminPushReport {
  final String id;
  final Map<String, dynamic> data;

  const AdminPushReport({
    required this.id,
    required this.data,
  });
}

class AdminPushTargetFilters {
  final String uid;
  final String meslek;
  final String konum;
  final String gender;
  final int? minAge;
  final int? maxAge;

  const AdminPushTargetFilters({
    this.uid = '',
    this.meslek = '',
    this.konum = '',
    this.gender = '',
    this.minAge,
    this.maxAge,
  });
}
