import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:turqappv2/Core/Services/qa_lab_catalog.dart';

void main() {
  test('focus coverage reports critical feed and short surfaces', () {
    final reports = QALabCatalog.focusCoverageReports();
    final surfaces = reports.map((report) => report.surface).toSet();

    expect(
      surfaces,
      containsAll(<String>['feed', 'short', 'chat', 'notifications', 'auth']),
    );

    final feed = QALabCatalog.surfaceCoverage('feed');
    final short = QALabCatalog.surfaceCoverage('short');

    expect(feed.integrationCount, greaterThan(0));
    expect(feed.coveredTags, contains('feed'));
    expect(feed.coveredTags, contains('video'));
    expect(feed.coveredTags, contains('scroll'));
    expect(short.integrationCount, greaterThan(0));
    expect(short.coveredTags, contains('short'));
    expect(short.coveredTags, contains('video'));
    expect(short.coveredTags, contains('scroll'));
  });

  test('qa catalog stays in sync with repo test inventory', () {
    final repoRoot = _findRepoRoot();
    final actualPaths = <String>{
      ..._collectRelativePaths(repoRoot, 'integration_test', '_test.dart'),
      ..._collectRelativePaths(repoRoot, 'test', '_test.dart'),
      ..._collectRelativePaths(repoRoot, 'functions/tests', '.js'),
      ..._collectRelativePaths(repoRoot, 'config/test_suites', '.txt'),
      ..._collectRelativePaths(repoRoot, 'config/test_suites', '.tsv'),
    };
    final catalogPaths =
        QALabCatalog.entries.map((entry) => entry.path).toSet();

    final missingFromCatalog = actualPaths.difference(catalogPaths).toList()
      ..sort();
    final staleCatalogEntries = catalogPaths.difference(actualPaths).toList()
      ..sort();

    expect(
      missingFromCatalog,
      isEmpty,
      reason: 'Catalog is missing repo tests: ${missingFromCatalog.join(', ')}',
    );
    expect(
      staleCatalogEntries,
      isEmpty,
      reason: 'Catalog contains stale paths: ${staleCatalogEntries.join(', ')}',
    );
  });
}

Directory _findRepoRoot() {
  var current = Directory.current.absolute;
  while (true) {
    if (File('${current.path}/pubspec.yaml').existsSync()) {
      return current;
    }
    final parent = current.parent;
    if (parent.path == current.path) {
      throw StateError('Could not locate repo root from ${Directory.current}.');
    }
    current = parent;
  }
}

Set<String> _collectRelativePaths(
  Directory repoRoot,
  String relativeDir,
  String suffix,
) {
  final base = Directory('${repoRoot.path}/$relativeDir');
  if (!base.existsSync()) {
    return <String>{};
  }
  return base
      .listSync(recursive: true)
      .whereType<File>()
      .map((file) => file.path.substring(repoRoot.path.length + 1))
      .where((path) => path.endsWith(suffix))
      .toSet();
}
