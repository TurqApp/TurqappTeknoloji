part of 'scholarship_repository.dart';

class _TimedScholarship {
  const _TimedScholarship({
    required this.data,
    required this.cachedAt,
  });

  final Map<String, dynamic> data;
  final DateTime cachedAt;
}

class _TimedScholarshipList {
  const _TimedScholarshipList({
    required this.items,
    required this.cachedAt,
  });

  final List<Map<String, dynamic>> items;
  final DateTime cachedAt;
}

class _TimedScholarshipApply {
  const _TimedScholarshipApply({
    required this.value,
    required this.cachedAt,
  });

  final bool value;
  final DateTime cachedAt;
}
