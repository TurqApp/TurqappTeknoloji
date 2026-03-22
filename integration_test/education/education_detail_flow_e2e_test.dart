import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:turqappv2/Core/Services/integration_test_keys.dart';
import 'package:turqappv2/Modules/Education/pasaj_tabs.dart';

import '../core/bootstrap/test_app_bootstrap.dart';
import '../core/helpers/deep_flow_helpers.dart';
import '../core/helpers/smoke_artifact_collector.dart';

Future<bool> _openScholarshipDetail(WidgetTester tester) async {
  await tapItKey(
    tester,
    IntegrationTestKeys.educationTab(PasajTabIds.scholarships),
    settlePumps: 8,
  );
  final finder = findItKeyPrefix('it-scholarship-item-');
  for (var i = 0; i < 10; i++) {
    if (finder.evaluate().isNotEmpty) break;
    await tester.pump(const Duration(milliseconds: 250));
  }
  if (finder.evaluate().isEmpty) return false;
  await tapItKey(
    tester,
    firstValueKeyString(finder)!,
    settlePumps: 10,
  );
  expect(byItKey(IntegrationTestKeys.screenScholarshipDetail), findsOneWidget);
  await pageBackAndSettle(tester, settlePumps: 8);
  expect(byItKey(IntegrationTestKeys.screenEducation), findsOneWidget);
  return true;
}

Future<bool> _openPracticeExamDetail(WidgetTester tester) async {
  await tapItKey(
    tester,
    IntegrationTestKeys.educationTab(PasajTabIds.practiceExams),
    settlePumps: 8,
  );
  final finder = findItKeyPrefix('it-practice-exam-open-');
  for (var i = 0; i < 10; i++) {
    if (finder.evaluate().isNotEmpty) break;
    await tester.pump(const Duration(milliseconds: 250));
  }
  if (finder.evaluate().isEmpty) return false;
  await tapItKey(
    tester,
    firstValueKeyString(finder)!,
    settlePumps: 10,
  );
  if (byItKey(IntegrationTestKeys.screenPracticeExamPreview)
      .evaluate()
      .isNotEmpty) {
    await pageBackAndSettle(tester, settlePumps: 8);
    expect(byItKey(IntegrationTestKeys.screenEducation), findsOneWidget);
    return true;
  }
  if (find.byType(CupertinoAlertDialog).evaluate().isNotEmpty) {
    await pageBackAndSettle(tester, settlePumps: 6);
    expect(byItKey(IntegrationTestKeys.screenEducation), findsOneWidget);
    return true;
  }
  return false;
}

Future<bool> _openJobDetail(WidgetTester tester) async {
  await tapItKey(
    tester,
    IntegrationTestKeys.educationTab(PasajTabIds.jobFinder),
    settlePumps: 8,
  );
  final finder = findItKeyPrefix('it-job-item-');
  for (var i = 0; i < 10; i++) {
    if (finder.evaluate().isNotEmpty) break;
    await tester.pump(const Duration(milliseconds: 250));
  }
  if (finder.evaluate().isEmpty) return false;
  await tapItKey(
    tester,
    firstValueKeyString(finder)!,
    settlePumps: 10,
  );
  expect(byItKey(IntegrationTestKeys.screenJobDetail), findsOneWidget);
  await pageBackAndSettle(tester, settlePumps: 8);
  expect(byItKey(IntegrationTestKeys.screenEducation), findsOneWidget);
  return true;
}

void main() {
  ensureIntegrationBinding();

  testWidgets(
    'Education tab reaches at least one deep detail route',
    (tester) async {
      await SmokeArtifactCollector.runScenario(
        'education_detail_flow_e2e',
        tester,
        () async {
          await launchTurqApp(tester);
          await expectFeedScreen(tester);

          await tapItKey(tester, IntegrationTestKeys.navEducation);
          expect(byItKey(IntegrationTestKeys.screenEducation), findsOneWidget);

          var openedDetail = await _openScholarshipDetail(tester);
          openedDetail = await _openJobDetail(tester) || openedDetail;
          openedDetail = await _openPracticeExamDetail(tester) || openedDetail;

          expect(
            openedDetail,
            isTrue,
            reason:
                'Education detail flow could not reach scholarship, job, or practice exam detail.',
          );
        },
      );
    },
    skip: !kRunIntegrationSmoke,
  );
}
