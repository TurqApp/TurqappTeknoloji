part of 'report_repository.dart';

class ReportAggregateItem {
  final String id;
  final Map<String, dynamic> data;

  const ReportAggregateItem({
    required this.id,
    required this.data,
  });
}

class ReportReasonItem {
  final String id;
  final Map<String, dynamic> data;

  const ReportReasonItem({
    required this.id,
    required this.data,
  });
}
