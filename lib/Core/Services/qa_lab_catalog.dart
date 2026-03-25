part 'qa_lab_catalog_entries_part.dart';
part 'qa_lab_catalog_helpers_part.dart';

enum QALabTestOrigin {
  integration,
  suite,
  unit,
  widget,
  backend,
}

class QALabSurfaceCoverageReport {
  const QALabSurfaceCoverageReport({
    required this.surface,
    required this.requiredTags,
    required this.coveredTags,
    required this.missingTags,
    required this.integrationCount,
    required this.runnableInAppCount,
    required this.suiteCount,
    required this.unitCount,
    required this.widgetCount,
    required this.backendCount,
  });

  final String surface;
  final List<String> requiredTags;
  final List<String> coveredTags;
  final List<String> missingTags;
  final int integrationCount;
  final int runnableInAppCount;
  final int suiteCount;
  final int unitCount;
  final int widgetCount;
  final int backendCount;

  double get coverageRatio {
    if (requiredTags.isEmpty) return 1;
    return coveredTags.length / requiredTags.length;
  }

  bool get complete => missingTags.isEmpty;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'surface': surface,
      'requiredTags': requiredTags,
      'coveredTags': coveredTags,
      'missingTags': missingTags,
      'integrationCount': integrationCount,
      'runnableInAppCount': runnableInAppCount,
      'suiteCount': suiteCount,
      'unitCount': unitCount,
      'widgetCount': widgetCount,
      'backendCount': backendCount,
      'coverageRatio': coverageRatio,
      'complete': complete,
    };
  }
}

class QALabCatalogEntry {
  const QALabCatalogEntry({
    required this.path,
    required this.origin,
    required this.runnableInApp,
    this.notes = '',
  });

  final String path;
  final QALabTestOrigin origin;
  final bool runnableInApp;
  final String notes;

  String get id => path.replaceAll(RegExp(r'[^a-zA-Z0-9]+'), '_');

  String get title {
    final normalized = path.split('/').last.trim();
    if (normalized.isEmpty) return path;
    return normalized;
  }

  List<String> get tags => QALabCatalog.inferTags(path);

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'title': title,
      'path': path,
      'origin': origin.name,
      'runnableInApp': runnableInApp,
      'tags': tags,
      'notes': notes,
    };
  }
}

class QALabCatalog {
  const QALabCatalog._();

  static const List<String> focusSurfaces = _qaLabFocusSurfaces;

  static const Map<String, List<String>> focusSurfaceRequirements =
      _qaLabFocusSurfaceRequirements;

  static const List<QALabCatalogEntry> entries = _qaLabCatalogEntries;

  static List<String> inferTags(String path) {
    return _inferCatalogTags(path);
  }

  static List<QALabCatalogEntry> entriesForSurface(String surface) {
    return _entriesForSurface(surface);
  }

  static QALabSurfaceCoverageReport surfaceCoverage(String surface) {
    return _surfaceCoverage(surface);
  }

  static List<QALabSurfaceCoverageReport> focusCoverageReports() {
    return _focusCoverageReports();
  }

  static Map<String, dynamic> focusCoverageJson() {
    return _focusCoverageJson();
  }

  static Map<String, dynamic> summaryJson() {
    return _summaryJson();
  }
}
