part of 'qa_lab_catalog.dart';

List<String> _inferCatalogTags(String path) {
  final lower = path.toLowerCase();
  if (lower.contains('turqapp_complete')) {
    return <String>[
      'splash',
      'login',
      'feed',
      'comments',
      'profile',
      'settings',
      'explore',
      'pasaj',
      'chat',
      'short',
      'notifications',
      'composer',
    ];
  }

  final tags = <String>{};

  void add(String value) {
    if (value.trim().isNotEmpty) {
      tags.add(value.trim());
    }
  }

  if (lower.contains('/auth/') || lower.contains('login')) {
    add('auth');
    add('login');
    add('splash');
  }
  if (lower.contains('/feed/') || lower.contains('feed_')) {
    add('feed');
  }
  if (lower.contains('/short') || lower.contains('/shorts/')) {
    add('short');
    add('scroll');
  }
  if (lower.contains('/chat/') || lower.contains('message')) {
    add('chat');
    add('message');
  }
  if (lower.contains('/comments/')) {
    add('comments');
  }
  if (lower.contains('/notifications/')) {
    add('notifications');
  }
  if (lower.contains('/story/')) {
    add('story');
  }
  if (lower.contains('/profile/')) {
    add('profile');
  }
  if (lower.contains('/explore/')) {
    add('explore');
  }
  if (lower.contains('/education/') ||
      lower.contains('/market/') ||
      lower.contains('practice') ||
      lower.contains('question_bank')) {
    add('pasaj');
    add('education');
  }
  if (lower.contains('/system/') || lower.contains('process_death')) {
    add('system');
  }
  if (lower.contains('permission')) {
    add('permissions');
    add('settings');
  }
  if (lower.contains('settings')) {
    add('settings');
  }
  if (lower.contains('upload')) {
    add('upload');
  }
  if (lower.contains('cache')) {
    add('cache');
  }
  if (lower.contains('hls')) {
    add('hls');
    add('video');
  }
  if (lower.contains('video') ||
      lower.contains('playback') ||
      lower.contains('autoplay') ||
      lower.contains('fullscreen')) {
    add('video');
  }
  if (lower.contains('autoplay')) {
    add('autoplay');
  }
  if (lower.contains('playback')) {
    add('playback');
  }
  if (lower.contains('audio') || lower.contains('mute')) {
    add('audio');
  }
  if (lower.contains('network')) {
    add('network');
  }
  if (lower.contains('resume') || lower.contains('restore')) {
    add('resume');
  }
  if (lower.contains('scroll')) {
    add('scroll');
  }
  if (lower.contains('sign_in')) {
    add('login');
  }
  if (lower.contains('route') || lower.contains('deeplink')) {
    add('route');
  }
  if (lower.contains('rules')) {
    add('backend_rules');
  }
  if (lower.contains('ratelimiter')) {
    add('backend');
  }
  if (tags.isEmpty) {
    add('general');
  }
  return tags.toList(growable: false);
}

List<QALabCatalogEntry> _entriesForSurface(String surface) {
  final normalized = surface.trim().toLowerCase();
  return QALabCatalog.entries
      .where((entry) => entry.tags.contains(normalized))
      .toList(growable: false);
}

QALabSurfaceCoverageReport _surfaceCoverage(String surface) {
  final normalized = surface.trim().toLowerCase();
  final requiredTags = List<String>.from(
    QALabCatalog.focusSurfaceRequirements[normalized] ?? <String>[normalized],
  );
  final relevantEntries = _entriesForSurface(normalized);
  final coveredTags = requiredTags
      .where(
        (tag) => relevantEntries.any((entry) => entry.tags.contains(tag)),
      )
      .toList(growable: false);
  final missingTags = requiredTags
      .where((tag) => !coveredTags.contains(tag))
      .toList(growable: false);

  var integrationCount = 0;
  var runnableInAppCount = 0;
  var suiteCount = 0;
  var unitCount = 0;
  var widgetCount = 0;
  var backendCount = 0;

  for (final entry in relevantEntries) {
    switch (entry.origin) {
      case QALabTestOrigin.integration:
        integrationCount += 1;
        break;
      case QALabTestOrigin.suite:
        suiteCount += 1;
        break;
      case QALabTestOrigin.unit:
        unitCount += 1;
        break;
      case QALabTestOrigin.widget:
        widgetCount += 1;
        break;
      case QALabTestOrigin.backend:
        backendCount += 1;
        break;
    }
    if (entry.runnableInApp) {
      runnableInAppCount += 1;
    }
  }

  return QALabSurfaceCoverageReport(
    surface: normalized,
    requiredTags: requiredTags,
    coveredTags: coveredTags,
    missingTags: missingTags,
    integrationCount: integrationCount,
    runnableInAppCount: runnableInAppCount,
    suiteCount: suiteCount,
    unitCount: unitCount,
    widgetCount: widgetCount,
    backendCount: backendCount,
  );
}

List<QALabSurfaceCoverageReport> _focusCoverageReports() {
  return QALabCatalog.focusSurfaces
      .map(_surfaceCoverage)
      .toList(growable: false);
}

Map<String, dynamic> _focusCoverageJson() {
  final reports = _focusCoverageReports();
  final completeCount = reports.where((report) => report.complete).length;
  final averageCoverage = reports.isEmpty
      ? 1.0
      : reports
              .map((report) => report.coverageRatio)
              .fold<double>(0, (sum, ratio) => sum + ratio) /
          reports.length;
  return <String, dynamic>{
    'completeCount': completeCount,
    'surfaceCount': reports.length,
    'averageCoverage': averageCoverage,
    'surfaces': reports.map((report) => report.toJson()).toList(
          growable: false,
        ),
  };
}

Map<String, dynamic> _summaryJson() {
  final byOrigin = <String, int>{};
  final byTag = <String, int>{};
  var runnableInAppCount = 0;
  for (final entry in QALabCatalog.entries) {
    byOrigin.update(entry.origin.name, (value) => value + 1, ifAbsent: () => 1);
    if (entry.runnableInApp) {
      runnableInAppCount += 1;
    }
    for (final tag in entry.tags) {
      byTag.update(tag, (value) => value + 1, ifAbsent: () => 1);
    }
  }
  return <String, dynamic>{
    'totalCount': QALabCatalog.entries.length,
    'runnableInAppCount': runnableInAppCount,
    'byOrigin': byOrigin,
    'byTag': byTag,
    'focusCoverage': _focusCoverageJson(),
  };
}
