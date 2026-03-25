part of 'test_repository.dart';

class _TimedTests {
  const _TimedTests({
    required this.items,
    required this.cachedAt,
  });

  final List<TestsModel> items;
  final DateTime cachedAt;
}

class TestPageResult {
  const TestPageResult({
    required this.items,
    required this.lastDocument,
    required this.hasMore,
  });

  final List<TestsModel> items;
  final DocumentSnapshot? lastDocument;
  final bool hasMore;
}
