import 'package:flutter_test/flutter_test.dart';
import 'package:turqappv2/Core/Services/integration_test_fixture_contract.dart';
import 'package:turqappv2/Core/Services/integration_test_state_probe.dart';

Map<String, dynamic> readIntegrationProbe() {
  return IntegrationTestStateProbe.snapshot();
}

Map<String, dynamic> readSurfaceProbe(String surface) {
  final snapshot = readIntegrationProbe();
  final payload = snapshot[surface];
  expect(payload, isA<Map<String, dynamic>>());
  return Map<String, dynamic>.from(payload as Map<String, dynamic>);
}

List<String> _readDocIds(Map<String, dynamic> payload) {
  final raw = payload['docIds'];
  if (raw is! List) return const <String>[];
  return raw
      .map((item) => item?.toString() ?? '')
      .where((id) => id.isNotEmpty)
      .toList();
}

void expectSurfaceRegistered(String surface) {
  final payload = readSurfaceProbe(surface);
  expect(payload['registered'], isTrue,
      reason: '$surface controller not registered');
}

void expectCenteredIndexValid(
  String surface, {
  required String indexField,
  required String countField,
}) {
  final payload = readSurfaceProbe(surface);
  final count = (payload[countField] as num?)?.toInt() ?? 0;
  final index = (payload[indexField] as num?)?.toInt() ?? -1;
  if (count <= 0) return;
  expect(index, greaterThanOrEqualTo(0), reason: '$surface index negative');
  expect(index, lessThan(count), reason: '$surface index out of range');
}

void expectSelectedNavIndex(int expectedIndex) {
  final payload = readSurfaceProbe('navBar');
  expect(payload['registered'], isTrue,
      reason: 'navBar controller not registered');
  expect(
    (payload['selectedIndex'] as num?)?.toInt(),
    expectedIndex,
    reason: 'unexpected navBar selected index',
  );
}

void expectCountNeverDropsToZeroAfterReplay(
  String surface, {
  required Map<String, dynamic> before,
  required Map<String, dynamic> after,
  String countField = 'count',
}) {
  final beforeCount = (before[countField] as num?)?.toInt() ?? 0;
  final afterCount = (after[countField] as num?)?.toInt() ?? 0;
  if (beforeCount <= 0) return;
  expect(afterCount, greaterThan(0),
      reason: '$surface count dropped to zero after route replay');
}

void expectDocPreservedIfStillPresent(
  String surface, {
  required Map<String, dynamic> before,
  required Map<String, dynamic> after,
  required String activeDocField,
}) {
  final beforeDocId = (before[activeDocField] as String?)?.trim() ?? '';
  if (beforeDocId.isEmpty) return;
  final afterDocIds = _readDocIds(after);
  if (!afterDocIds.contains(beforeDocId)) return;
  final afterDocId = (after[activeDocField] as String?)?.trim() ?? '';
  expect(
    afterDocId,
    beforeDocId,
    reason: '$surface active doc changed even though previous doc still exists',
  );
}

void expectNonNegativeCounter(
  String surface,
  Map<String, dynamic> payload, {
  required String field,
}) {
  final value = (payload[field] as num?)?.toInt() ?? 0;
  expect(value, greaterThanOrEqualTo(0),
      reason: '$surface $field became negative');
}

void expectSurfaceMatchesFixture(
  String surface,
  Map<String, dynamic> payload, {
  String countField = 'count',
  String docIdsField = 'docIds',
  String unreadField = 'unreadTotal',
}) {
  final contract = IntegrationTestFixtureContract.current.surface(surface);
  if (contract == null || !contract.isConfigured) return;

  final count = (payload[countField] as num?)?.toInt() ?? 0;
  if (contract.minCount != null) {
    expect(
      count,
      greaterThanOrEqualTo(contract.minCount!),
      reason: '$surface count is below fixture contract minimum',
    );
  }

  final docIds = _readDocIds(
    <String, dynamic>{'docIds': payload[docIdsField]},
  );
  for (final docId in contract.requiredDocIds) {
    expect(
      docIds,
      contains(docId),
      reason: '$surface fixture docId missing: $docId',
    );
  }

  if (contract.maxUnread != null) {
    final unread = (payload[unreadField] as num?)?.toInt() ?? 0;
    expect(
      unread,
      lessThanOrEqualTo(contract.maxUnread!),
      reason: '$surface unread total exceeded fixture contract maximum',
    );
  }
}
