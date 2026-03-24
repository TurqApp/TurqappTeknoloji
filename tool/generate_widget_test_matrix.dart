import 'dart:convert';
import 'dart:io';

final RegExp _widgetClassPattern = RegExp(
  r'class\s+([A-Za-z_]\w*)\s+extends\s+(StatelessWidget|StatefulWidget)',
);

void main() {
  final repoRoot = Directory.current;
  final libDir = Directory('${repoRoot.path}/lib');
  final widgetTestDir = Directory('${repoRoot.path}/test/widget');
  final docsDir = Directory('${repoRoot.path}/docs/testing');

  if (!docsDir.existsSync()) {
    docsDir.createSync(recursive: true);
  }

  final widgetTests = _loadWidgetTests(widgetTestDir);
  final entries = _scanWidgets(libDir, widgetTests);
  final summary = _buildSummary(entries);

  final markdown = _buildMarkdown(summary, entries);
  final json = const JsonEncoder.withIndent('  ').convert({
    'generatedAt': DateTime.now().toUtc().toIso8601String(),
    'summary': summary,
    'entries': entries,
  });

  File('${docsDir.path}/widget_test_matrix.md').writeAsStringSync(markdown);
  File('${docsDir.path}/widget_test_matrix.json').writeAsStringSync(json);

  stdout.writeln(
    'Generated widget test matrix for ${entries.length} widget classes.',
  );
}

Map<String, String> _loadWidgetTests(Directory testDir) {
  final tests = <String, String>{};
  for (final entity in testDir.listSync(recursive: true)) {
    if (entity is! File || !entity.path.endsWith('.dart')) continue;
    tests[_relativePath(entity.path)] = entity.readAsStringSync();
  }
  return tests;
}

List<Map<String, Object?>> _scanWidgets(
  Directory libDir,
  Map<String, String> widgetTests,
) {
  final entries = <Map<String, Object?>>[];
  for (final entity in libDir.listSync(recursive: true)) {
    if (entity is! File || !entity.path.endsWith('.dart')) continue;
    final content = entity.readAsStringSync();
    for (final match in _widgetClassPattern.allMatches(content)) {
      final name = match.group(1)!;
      final widgetType = match.group(2)!;
      final relativePath = _relativePath(entity.path);
      final matchedTests = widgetTests.entries
          .where((entry) => entry.value.contains(name))
          .map((entry) => entry.key)
          .toList()
        ..sort();
      entries.add({
        'widget': name,
        'widgetType': widgetType,
        'visibility': name.startsWith('_') ? 'private' : 'public',
        'path': relativePath,
        'module': _moduleFor(relativePath),
        'tier': _tierFor(relativePath, name),
        'requiredChecks': _requiredChecks(relativePath, widgetType),
        'coveredByWidgetTests': matchedTests,
        'status': matchedTests.isEmpty ? 'planned' : 'covered',
      });
    }
  }
  entries.sort((a, b) {
    final tierCompare = (a['tier'] as String).compareTo(b['tier'] as String);
    if (tierCompare != 0) return tierCompare;
    final moduleCompare =
        (a['module'] as String).compareTo(b['module'] as String);
    if (moduleCompare != 0) return moduleCompare;
    return (a['widget'] as String).compareTo(b['widget'] as String);
  });
  return entries;
}

Map<String, Object?> _buildSummary(List<Map<String, Object?>> entries) {
  final total = entries.length;
  final covered = entries.where((entry) => entry['status'] == 'covered').length;
  final publicCount =
      entries.where((entry) => entry['visibility'] == 'public').length;
  final privateCount = total - publicCount;
  final byTier = <String, int>{};
  final byModule = <String, int>{};

  for (final entry in entries) {
    byTier.update(entry['tier'] as String, (value) => value + 1,
        ifAbsent: () => 1);
    byModule.update(entry['module'] as String, (value) => value + 1,
        ifAbsent: () => 1);
  }

  return {
    'totalWidgets': total,
    'publicWidgets': publicCount,
    'privateWidgets': privateCount,
    'coveredWidgets': covered,
    'plannedWidgets': total - covered,
    'tiers': byTier,
    'modules': byModule,
  };
}

String _buildMarkdown(
  Map<String, Object?> summary,
  List<Map<String, Object?>> entries,
) {
  final buffer = StringBuffer()
    ..writeln('# Widget Test Matrix')
    ..writeln()
    ..writeln('Generated from `tool/generate_widget_test_matrix.dart`.')
    ..writeln()
    ..writeln('## Summary')
    ..writeln()
    ..writeln('- Total widget classes: ${summary['totalWidgets']}')
    ..writeln('- Public widget classes: ${summary['publicWidgets']}')
    ..writeln('- Private widget classes: ${summary['privateWidgets']}')
    ..writeln('- Directly referenced by current widget tests: ${summary['coveredWidgets']}')
    ..writeln('- Planned / not yet directly covered: ${summary['plannedWidgets']}')
    ..writeln()
    ..writeln('## Tier Definitions')
    ..writeln()
    ..writeln('- `P0`: core user surfaces; requires render, interaction, semantics, text-scale, and platform variation')
    ..writeln('- `P1`: important secondary widgets; requires render, interaction, semantics')
    ..writeln('- `P2`: support widgets; requires render and semantics at minimum')
    ..writeln()
    ..writeln('## Matrix')
    ..writeln()
    ..writeln('| Status | Tier | Widget | Type | Module | Path | Existing widget tests | Required checks |')
    ..writeln('| --- | --- | --- | --- | --- | --- | --- | --- |');

  for (final entry in entries) {
    final tests = (entry['coveredByWidgetTests'] as List)
        .cast<String>()
        .map((path) => '`$path`')
        .join('<br>');
    final requiredChecks = (entry['requiredChecks'] as List)
        .cast<String>()
        .join(', ');
    buffer.writeln(
      '| ${entry['status']} | ${entry['tier']} | `${entry['widget']}` | ${entry['widgetType']} | ${entry['module']} | `${entry['path']}` | ${tests.isEmpty ? '—' : tests} | $requiredChecks |',
    );
  }

  return buffer.toString();
}

String _moduleFor(String relativePath) {
  final segments = relativePath.split('/');
  if (segments.length >= 3 && segments[0] == 'lib') {
    return '${segments[1]}/${segments[2]}';
  }
  if (segments.length >= 2) {
    return '${segments[0]}/${segments[1]}';
  }
  return relativePath;
}

String _tierFor(String relativePath, String widgetName) {
  final lowerPath = relativePath.toLowerCase();
  final lowerName = widgetName.toLowerCase();
  const p0Needles = [
    'main.dart',
    '/splash/',
    '/agenda/',
    '/short/',
    '/chat/',
    '/profile/',
    '/navbar/',
    '/story/',
    '/market/',
    '/education/',
    '/settings/',
    '/sign',
    '/notifications/',
  ];
  const p1Needles = [
    '/core/widgets/',
    '/core/buttons/',
    '/bottomsheets/',
    '/recommendeduserlist/',
    '/inappnotifications/',
    '/explore/',
  ];

  if (p0Needles.any(lowerPath.contains) ||
      lowerName.contains('view') ||
      lowerName.contains('screen')) {
    return 'P0';
  }
  if (p1Needles.any(lowerPath.contains) ||
      lowerName.contains('sheet') ||
      lowerName.contains('dialog')) {
    return 'P1';
  }
  return 'P2';
}

List<String> _requiredChecks(String relativePath, String widgetType) {
  final lowerPath = relativePath.toLowerCase();
  final checks = <String>['render', 'semantics'];
  final needsInteraction = widgetType == 'StatefulWidget' ||
      lowerPath.contains('/modules/') ||
      lowerPath.contains('/buttons/') ||
      lowerPath.contains('/bottomsheets/');
  if (needsInteraction) {
    checks.add('interaction');
  }
  if (lowerPath.contains('/modules/') ||
      lowerPath.contains('/core/widgets/') ||
      lowerPath.contains('/core/buttons/')) {
    checks.add('textScale');
  }
  if (lowerPath.contains('/agenda/') ||
      lowerPath.contains('/short/') ||
      lowerPath.contains('/profile/') ||
      lowerPath.contains('/chat/') ||
      lowerPath.contains('/story/')) {
    checks.add('platform');
  }
  return checks;
}

String _relativePath(String path) {
  const marker = '/Users/turqapp/Desktop/TurqApp/';
  if (path.startsWith(marker)) {
    return path.substring(marker.length);
  }
  return path;
}
