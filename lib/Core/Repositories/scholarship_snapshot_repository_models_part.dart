part of 'scholarship_snapshot_repository.dart';

class ScholarshipListingSnapshot {
  const ScholarshipListingSnapshot({
    required this.items,
    required this.found,
  });

  final List<Map<String, dynamic>> items;
  final int found;
}
