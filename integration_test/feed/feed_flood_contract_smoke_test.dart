import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Repositories/feed_home_contract.dart';
import 'package:turqappv2/Core/Repositories/post_repository.dart';
import 'package:turqappv2/Core/Services/integration_test_keys.dart';
import 'package:turqappv2/Models/posts_model.dart';
import 'package:turqappv2/Modules/Agenda/agenda_controller.dart';

import '../core/bootstrap/test_app_bootstrap.dart';
import '../core/helpers/contract_waiters.dart';
import '../core/helpers/smoke_artifact_collector.dart';
import '../core/helpers/test_state_probe.dart';

const String _requiredFloodDocIdsRaw =
    String.fromEnvironment('INTEGRATION_FEED_FLOOD_DOC_IDS', defaultValue: '');

void main() {
  ensureIntegrationBinding();

  testWidgets(
    'Feed flood contract keeps flood roots renderable and stable',
    (tester) async {
      await SmokeArtifactCollector.runScenario(
        'feed_flood_contract',
        tester,
        () async {
          await launchTurqApp(
            tester,
            relaxFeedFixtureDocRequirement: true,
          );
          await expectFeedScreen(tester);

          final initialFeed = await waitForSurfaceProbeContract(
            tester,
            'feed',
            (payload) =>
                payload['registered'] == true &&
                (payload['count'] as num?) != null &&
                (payload['count'] as num).toInt() > 0 &&
                payload['feedViewMode'] == 'forYou' &&
                payload['usesPrimaryFeedPaging'] ==
                    FeedHomeContract.primaryHybridV1.usesPrimaryFeedPaging &&
                payload['feedContractId'] ==
                    FeedHomeContract.primaryHybridV1.contractId,
            reason: 'Feed did not stabilize before flood contract assertions.',
            context: 'feed flood initial contract',
          );

          expectFeedUsesPrimaryContract(initialFeed);
          expectNonNegativeCounter(
            'feed',
            initialFeed,
            field: 'floodRootCount',
          );
          expectNonNegativeCounter(
            'feed',
            initialFeed,
            field: 'floodSeriesCount',
          );

          final requiredFloodDocIds = _parseDocIds(_requiredFloodDocIdsRaw);
          if (requiredFloodDocIds.isNotEmpty) {
            await _attachRequiredFloodRoots(requiredFloodDocIds);
            await settleSmokeShell(
              tester,
              context: 'feed flood required doc attach settle',
            );

            final controller = maybeFindAgendaController();
            expect(
              controller,
              isNotNull,
              reason: 'AgendaController not registered for flood contract.',
            );
            final floodRootDocIds = controller!.agendaList
                .where((post) => post.floodCount.toInt() > 1)
                .map((post) => post.docID.trim())
                .where((docId) => docId.isNotEmpty)
                .toSet();
            for (final docId in requiredFloodDocIds) {
              expect(
                floodRootDocIds,
                contains(docId),
                reason:
                    'Required flood root did not resolve into agenda list: $docId',
              );
            }
          } else {
            debugPrint(
              '[integration-smoke] flood: no explicit flood doc ids provided',
            );
          }

          final beforeReplay = readSurfaceProbe('feed');
          await tester.drag(
            byItKey(IntegrationTestKeys.screenFeed),
            const Offset(0, -520),
          );
          await settleSmokeShell(
            tester,
            context: 'feed flood scroll settle',
          );

          final afterReplay = readSurfaceProbe('feed');
          expectFeedUsesPrimaryContract(afterReplay);
          expectCountNeverDropsToZeroAfterReplay(
            'feed',
            before: beforeReplay,
            after: afterReplay,
          );
          expectNonNegativeCounter(
            'feed',
            afterReplay,
            field: 'floodRootCount',
          );
          expectNonNegativeCounter(
            'feed',
            afterReplay,
            field: 'floodSeriesCount',
          );
        },
      );
    },
    skip: !kRunIntegrationSmoke,
  );
}

List<String> _parseDocIds(String raw) {
  return raw
      .split(',')
      .map((item) => item.trim())
      .where((item) => item.isNotEmpty)
      .toList(growable: false);
}

Future<void> _attachRequiredFloodRoots(List<String> docIds) async {
  final controller = maybeFindAgendaController();
  expect(
    controller,
    isNotNull,
    reason: 'AgendaController not registered while attaching flood roots.',
  );
  final normalizedDocIds = docIds
      .map((docId) => docId.trim())
      .where((docId) => docId.isNotEmpty)
      .toList(growable: false);
  if (normalizedDocIds.isEmpty) {
    return;
  }

  final agenda = controller!.agendaList;
  final existingDocIds = agenda
      .map((post) => post.docID.trim())
      .where((docId) => docId.isNotEmpty)
      .toSet();
  final missingDocIds = normalizedDocIds
      .where((docId) => !existingDocIds.contains(docId))
      .toList(growable: false);

  final resolvedById = await _fetchPostsByIds(normalizedDocIds);
  for (final docId in normalizedDocIds) {
    final post = resolvedById[docId];
    expect(
      post,
      isNotNull,
      reason: 'Flood smoke could not resolve post card for docId=$docId',
    );
    expect(
      post!.floodCount.toInt(),
      greaterThan(1),
      reason:
          'Flood smoke docId=$docId is not a flood root (floodCount=${post.floodCount})',
    );
  }

  if (missingDocIds.isEmpty) {
    return;
  }

  final merged = <PostsModel>[
    ...agenda,
    ...missingDocIds
        .map((docId) => resolvedById[docId])
        .whereType<PostsModel>(),
  ];
  controller.agendaList.assignAll(merged);
}

Future<Map<String, PostsModel>> _fetchPostsByIds(List<String> docIds) async {
  final resolved = await PostRepository.ensure().fetchPostCardsByIds(
    docIds,
    preferCache: false,
    cacheOnly: false,
  );
  final unresolved = docIds
      .where((docId) => !resolved.containsKey(docId))
      .toList(growable: false);
  if (unresolved.isEmpty) {
    return resolved;
  }

  final posts = FirebaseFirestore.instance.collection('Posts');
  final merged = Map<String, PostsModel>.from(resolved);
  for (final docId in unresolved) {
    try {
      final snap = await posts.doc(docId).get();
      if (!snap.exists) continue;
      final data = snap.data();
      if (data == null) continue;
      merged[docId] = PostsModel.fromMap(data, snap.id);
    } catch (error) {
      debugPrint(
        '[integration-smoke] flood: direct post fetch failed '
        'docId=$docId error=$error',
      );
    }
  }
  return merged;
}
