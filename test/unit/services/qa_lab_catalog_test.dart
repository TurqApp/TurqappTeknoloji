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
}
