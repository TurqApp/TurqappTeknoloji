part of 'job_repository.dart';

class _TimedJobs {
  const _TimedJobs({
    required this.items,
    required this.cachedAt,
  });

  final List<JobModel> items;
  final DateTime cachedAt;
}

class _TimedBool {
  const _TimedBool({
    required this.value,
    required this.cachedAt,
  });

  final bool value;
  final DateTime cachedAt;
}
