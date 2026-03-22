import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

Iterable<String> _manifestEntries() sync* {
  final suiteDir = Directory('config/test_suites');
  for (final entity in suiteDir.listSync(recursive: false)) {
    if (entity is! File) continue;
    final path = entity.path;
    if (!path.endsWith('.txt') && !path.endsWith('.tsv')) continue;
    for (final rawLine in entity.readAsLinesSync()) {
      final line = rawLine.trim();
      if (line.isEmpty || line.startsWith('#')) continue;
      if (path.endsWith('.tsv')) {
        yield line.split('|').first.trim();
      } else {
        yield line;
      }
    }
  }
}

Set<String> _integrationTests() {
  return Directory('integration_test')
      .listSync(recursive: true)
      .whereType<File>()
      .where((file) => file.path.endsWith('_test.dart'))
      .map((file) => file.path.replaceAll('\\', '/'))
      .toSet();
}

void main() {
  test('every integration test is registered in a suite manifest', () {
    final integrationTests = _integrationTests();
    final manifestEntries = _manifestEntries().toSet();

    final missing = integrationTests.difference(manifestEntries).toList()
      ..sort();

    expect(
      missing,
      isEmpty,
      reason: 'Unregistered integration tests: ${missing.join(', ')}',
    );
  });

  test('suite manifest entries point to existing integration tests', () {
    final integrationTests = _integrationTests();
    final missingTargets = _manifestEntries()
        .where((path) => !integrationTests.contains(path))
        .toList()
      ..sort();

    expect(
      missingTargets,
      isEmpty,
      reason:
          'Suite manifest has missing test paths: ${missingTargets.join(', ')}',
    );
  });

  test('release gate suite keeps the official 8-entry contract', () {
    final releaseEntries = File('config/test_suites/release_gate_e2e.txt')
        .readAsLinesSync()
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty && !line.startsWith('#'))
        .toList();

    expect(releaseEntries, hasLength(8));
  });
}
