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
  final libFiles = _loadDartFiles(libDir);
  final entries = _scanWidgets(libFiles, widgetTests);
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

Map<String, String> _loadDartFiles(Directory dir) {
  final files = <String, String>{};
  for (final entity in dir.listSync(recursive: true)) {
    if (entity is! File || !entity.path.endsWith('.dart')) continue;
    files[_relativePath(entity.path)] = entity.readAsStringSync();
  }
  return files;
}

List<Map<String, Object?>> _scanWidgets(
  Map<String, String> libFiles,
  Map<String, String> widgetTests,
) {
  final entries = <Map<String, Object?>>[];
  final allLibPaths = libFiles.keys.toSet();
  for (final fileEntry in libFiles.entries) {
    final relativePath = fileEntry.key;
    final content = fileEntry.value;
    for (final match in _widgetClassPattern.allMatches(content)) {
      final name = match.group(1)!;
      final widgetType = match.group(2)!;
      final matchedTests = widgetTests.entries
          .where((entry) => entry.value.contains(name))
          .map((entry) => entry.key)
          .toList()
        ..sort();
      final ownerPath = _ownerPathFor(relativePath, allLibPaths);
      final ownerWidget = _ownerWidgetFor(
        ownerPath,
        libFiles,
        fallbackWidget: name,
      );
      entries.add({
        'widget': name,
        'widgetType': widgetType,
        'visibility': name.startsWith('_') ? 'private' : 'public',
        'path': relativePath,
        'module': _moduleFor(relativePath),
        'surface': _surfaceFor(relativePath, ownerPath, ownerWidget),
        'screenOwner': ownerWidget,
        'ownerPath': ownerPath,
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
    ..writeln('Owner ekran/sayfa alanlari heuristik olarak cikarilir; route benzeri dosya ve klasor yapisina gore eslenir.')
    ..writeln()
    ..writeln('| Status | Tier | Surface | Widget | Screen/Page | Owner path | Type | Module | Path | Existing widget tests | Required checks |')
    ..writeln('| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |');

  for (final entry in entries) {
    final tests = (entry['coveredByWidgetTests'] as List)
        .cast<String>()
        .map((path) => '`$path`')
        .join('<br>');
    final requiredChecks = (entry['requiredChecks'] as List)
        .cast<String>()
        .join(', ');
    buffer.writeln(
      '| ${entry['status']} | ${entry['tier']} | ${entry['surface']} | `${entry['widget']}` | `${entry['screenOwner']}` | `${entry['ownerPath']}` | ${entry['widgetType']} | ${entry['module']} | `${entry['path']}` | ${tests.isEmpty ? '—' : tests} | $requiredChecks |',
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

String _surfaceFor(String relativePath, String ownerPath, String ownerWidget) {
  final haystack =
      '${relativePath.toLowerCase()} ${ownerPath.toLowerCase()} ${ownerWidget.toLowerCase()}';
  if (haystack.contains('/agenda/') || haystack.contains('feed')) {
    return 'feed';
  }
  if (haystack.contains('/short/')) return 'short';
  if (haystack.contains('/chat/')) return 'chat';
  if (haystack.contains('notification')) return 'notifications';
  if (haystack.contains('/signin/') || haystack.contains('/splash/') || haystack.contains('auth')) {
    return 'auth';
  }
  if (haystack.contains('/story/')) return 'story';
  if (haystack.contains('/market/') || haystack.contains('pasaj')) {
    return 'pasaj';
  }
  if (haystack.contains('/profile/') || haystack.contains('/settings/')) {
    return 'profile';
  }
  if (haystack.contains('/explore/')) return 'explore';
  if (haystack.contains('/education/')) return 'education';
  return 'shared';
}

String _ownerPathFor(String relativePath, Set<String> allLibPaths) {
  final basename = _basename(relativePath);
  final dirname = _dirname(relativePath);

  if (_isRouteLikeFileName(basename)) {
    return relativePath;
  }

  if (basename.endsWith('_part.dart')) {
    for (final candidateStem in _partOwnerCandidates(basename)) {
      final candidatePath = '$dirname/$candidateStem.dart';
      if (allLibPaths.contains(candidatePath)) {
        return candidatePath;
      }
    }
  }

  if (!_shouldInferContainerOwner(relativePath, basename)) {
    return relativePath;
  }

  final siblingRoute = _sameDirectoryRouteOwner(
    relativePath,
    basename,
    dirname,
    allLibPaths,
  );
  if (siblingRoute != null) return siblingRoute;

  final parentRoute = _parentDirectoryRouteOwner(dirname, allLibPaths);
  if (parentRoute != null) return parentRoute;

  return relativePath;
}

String _ownerWidgetFor(
  String ownerPath,
  Map<String, String> libFiles, {
  required String fallbackWidget,
}) {
  final content = libFiles[ownerPath];
  if (content == null) return fallbackWidget;

  final widgetNames = _widgetClassPattern
      .allMatches(content)
      .map((match) => match.group(1)!)
      .toList();
  if (widgetNames.isEmpty) return fallbackWidget;

  for (final widgetName in widgetNames) {
    if (!widgetName.startsWith('_') && _isRouteLikeWidgetName(widgetName)) {
      return widgetName;
    }
  }
  for (final widgetName in widgetNames) {
    if (!widgetName.startsWith('_')) return widgetName;
  }
  return widgetNames.first;
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

String _basename(String path) => path.split('/').last;

String _dirname(String path) {
  final index = path.lastIndexOf('/');
  if (index == -1) return '';
  return path.substring(0, index);
}

bool _isRouteLikeFileName(String basename) {
  final lower = basename.toLowerCase();
  return lower == 'main.dart' ||
      lower.endsWith('_view.dart') ||
      lower.endsWith('_screen.dart') ||
      lower.endsWith('_page.dart') ||
      lower.endsWith('_sheet.dart') ||
      lower.endsWith('_dialog.dart');
}

bool _isRouteLikeWidgetName(String widgetName) {
  final lower = widgetName.toLowerCase();
  return lower.contains('view') ||
      lower.contains('screen') ||
      lower.contains('page') ||
      lower.contains('sheet') ||
      lower.contains('dialog') ||
      lower == 'app';
}

bool _shouldInferContainerOwner(String relativePath, String basename) {
  final lowerPath = relativePath.toLowerCase();
  final lowerBase = basename.toLowerCase();
  const pathNeedles = <String>[
    '/widgets/',
    '/components/',
    '/common/',
    '/content/',
    '/header/',
    '/footer/',
  ];
  const baseNeedles = <String>[
    'row',
    'item',
    'tile',
    'button',
    'field',
    'content',
    'header',
    'footer',
    'actions',
    'bar',
    'card',
    'badge',
    'selector',
    'attribution',
  ];
  return pathNeedles.any(lowerPath.contains) ||
      baseNeedles.any(lowerBase.contains);
}

List<String> _partOwnerCandidates(String basename) {
  final stem = basename.replaceAll('.dart', '');
  final withoutPart = stem.replaceFirst(RegExp(r'_part$'), '');
  final candidates = <String>[];
  var current = withoutPart;
  while (true) {
    candidates.add(current);
    final index = current.lastIndexOf('_');
    if (index == -1) break;
    current = current.substring(0, index);
  }
  return candidates;
}

String? _sameDirectoryRouteOwner(
  String relativePath,
  String basename,
  String dirname,
  Set<String> allLibPaths,
) {
  final candidates = allLibPaths
      .where((path) => _dirname(path) == dirname && path != relativePath)
      .where((path) => _isRouteLikeFileName(_basename(path)))
      .toList();
  if (candidates.isEmpty) return null;
  candidates.sort((a, b) {
    final aScore = _sharedPrefixScore(_basename(a), basename);
    final bScore = _sharedPrefixScore(_basename(b), basename);
    return bScore.compareTo(aScore);
  });
  return candidates.first;
}

String? _parentDirectoryRouteOwner(String dirname, Set<String> allLibPaths) {
  var currentDir = dirname;
  while (currentDir.contains('/')) {
    final dirName = currentDir.split('/').last;
    final stem = _toSnakeCase(dirName);
    final candidates = <String>[
      '$currentDir/$stem.dart',
      '$currentDir/${stem}_view.dart',
      '$currentDir/${stem}_screen.dart',
      '$currentDir/${stem}_page.dart',
    ];
    for (final candidate in candidates) {
      if (allLibPaths.contains(candidate)) return candidate;
    }
    currentDir = _dirname(currentDir);
  }
  return null;
}

int _sharedPrefixScore(String a, String b) {
  final max = a.length < b.length ? a.length : b.length;
  var score = 0;
  for (var i = 0; i < max; i++) {
    if (a[i] != b[i]) break;
    score++;
  }
  return score;
}

String _toSnakeCase(String value) {
  final buffer = StringBuffer();
  for (var i = 0; i < value.length; i++) {
    final char = value[i];
    final isUpper = char.toUpperCase() == char && char.toLowerCase() != char;
    if (i > 0 && isUpper) buffer.write('_');
    buffer.write(char.toLowerCase());
  }
  return buffer.toString();
}

String _relativePath(String path) {
  const marker = '/Users/turqapp/Desktop/TurqApp/';
  if (path.startsWith(marker)) {
    return path.substring(marker.length);
  }
  return path;
}
