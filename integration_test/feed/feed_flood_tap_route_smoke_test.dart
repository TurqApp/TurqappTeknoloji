import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Repositories/post_repository.dart';
import 'package:turqappv2/Models/posts_model.dart';
import 'package:turqappv2/Modules/Agenda/FloodListing/flood_listing.dart';
import 'package:turqappv2/Modules/Agenda/FloodListing/flood_listing_controller.dart';
import 'package:turqappv2/Modules/Agenda/agenda_controller.dart';

import '../core/bootstrap/test_app_bootstrap.dart';
import '../core/helpers/contract_waiters.dart';
import '../core/helpers/smoke_artifact_collector.dart';
import '../core/helpers/test_state_probe.dart';
import '../core/helpers/transient_error_policy.dart';

const String _requiredFloodDocIdsRaw =
    String.fromEnvironment('INTEGRATION_FEED_FLOOD_DOC_IDS', defaultValue: '');

void main() {
  ensureIntegrationBinding();

  testWidgets(
    'Feed flood root tap opens flood listing with children',
    (tester) async {
      final originalOnError = installTransientFlutterErrorPolicy();
      try {
        await SmokeArtifactCollector.runScenario(
          'feed_flood_tap_route',
          tester,
          () async {
            await launchTurqApp(
              tester,
              relaxFeedFixtureDocRequirement: true,
            );
            await expectFeedScreen(tester);

            await waitForSurfaceProbeContract(
              tester,
              'feed',
              (payload) =>
                  payload['registered'] == true &&
                  (payload['count'] as num? ?? 0) > 0 &&
                  (payload['floodRootCount'] as num? ?? 0) >= 0,
              reason: 'Feed did not stabilize before flood tap smoke.',
              context: 'feed flood tap initial contract',
            );

            final requiredFloodDocIds = _parseDocIds(_requiredFloodDocIdsRaw);
            if (requiredFloodDocIds.isNotEmpty) {
              await _attachRequiredFloodRoots(requiredFloodDocIds);
              await settleSmokeShell(
                tester,
                context: 'feed flood tap required doc attach settle',
              );
            }

            final feedPayload = readSurfaceProbe('feed');
            final floodRootDocIds =
                (feedPayload['floodRootDocIds'] as List<dynamic>? ?? const [])
                    .map((item) => item?.toString().trim() ?? '')
                    .where((docId) => docId.isNotEmpty)
                    .toList(growable: false);
            final targetDocId = requiredFloodDocIds.isNotEmpty
                ? requiredFloodDocIds.first
                : await _resolveOrAttachFallbackFloodRoot(floodRootDocIds);
            final targetModel = await _resolveFloodRoot(targetDocId);
            expect(
              targetModel,
              isNotNull,
              reason: 'Flood root model could not be resolved for $targetDocId',
            );
            expect(
              targetModel!.floodCount.toInt(),
              greaterThan(1),
              reason:
                  'Target doc is not a flood root: $targetDocId floodCount=${targetModel.floodCount}',
            );

            final targetFinder = find.byKey(Key('agenda-media-$targetDocId'));
            await pumpUntilVisible(
              tester,
              targetFinder,
              maxPumps: 24,
            );
            await tester.ensureVisible(targetFinder.first);
            await tester.pump(const Duration(milliseconds: 250));
            final tapPoint = tester.getCenter(targetFinder.first);
            await tester.tapAt(tapPoint);
            await settleSmokeShell(
              tester,
              context: 'feed flood tap route settle',
            );

            expect(find.byType(FloodListing), findsOneWidget);

            final floodController = maybeFindFloodListingController();
            expect(
              floodController,
              isNotNull,
              reason: 'FloodListingController was not registered after tap.',
            );

            await waitForSurfaceProbeContract(
              tester,
              'feed',
              (_) => true,
              maxPumps: 6,
              context: 'feed flood tap route post-settle',
            );

            final loadedFloods = floodController!.floods
                .map((post) => post.docID.trim())
                .where((docId) => docId.isNotEmpty)
                .toList(growable: false);

            expect(
              loadedFloods,
              contains(targetDocId),
              reason:
                  'Flood route did not contain tapped root doc: $targetDocId loaded=$loadedFloods',
            );
            expect(
              floodController.floods.length,
              greaterThan(1),
              reason:
                  'Flood route did not load child items after tap for $targetDocId',
            );

            if (kDebugMode) {
              debugPrint(
                '[integration-smoke] flood tap target=$targetDocId loaded=${floodController.floods.length}',
              );
            }
          },
        );
      } finally {
        restoreTransientFlutterErrorPolicy(originalOnError);
      }
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
  if (normalizedDocIds.isEmpty) return;

  final agenda = controller!.agendaList;
  final existingDocIds = agenda
      .map((post) => post.docID.trim())
      .where((docId) => docId.isNotEmpty)
      .toSet();
  final missingDocIds = normalizedDocIds
      .where((docId) => !existingDocIds.contains(docId))
      .toList(growable: false);
  if (missingDocIds.isEmpty) return;

  final resolvedById = await _fetchPostsByIds(normalizedDocIds);
  final merged = <PostsModel>[
    ...agenda,
    ...missingDocIds
        .map((docId) => resolvedById[docId])
        .whereType<PostsModel>(),
  ];
  controller.agendaList.assignAll(merged);
}

Future<PostsModel?> _resolveFloodRoot(String docId) async {
  final normalized = docId.trim();
  if (normalized.isEmpty) return null;
  final post = await PostRepository.ensure().fetchPostById(
    normalized,
    preferCache: false,
  );
  if (post != null) return post;
  final snap =
      await FirebaseFirestore.instance.collection('Posts').doc(normalized).get();
  if (!snap.exists) return null;
  final data = snap.data();
  if (data == null) return null;
  return PostsModel.fromMap(data, snap.id);
}

Future<String> _resolveOrAttachFallbackFloodRoot(List<String> existingDocIds) async {
  if (existingDocIds.isNotEmpty) {
    return existingDocIds.first;
  }
  final controller = maybeFindAgendaController();
  expect(
    controller,
    isNotNull,
    reason: 'AgendaController not registered while resolving fallback flood root.',
  );
  final fallbackRoots = await PostRepository.ensure().fetchFloodSeriesRoots(
    limit: 1,
    preferCache: false,
    cacheOnly: false,
  );
  expect(
    fallbackRoots,
    isNotEmpty,
    reason: 'Feed flood tap smoke could not resolve any fallback flood root.',
  );
  final fallback = fallbackRoots.first;
  final merged = <PostsModel>[
    if (!controller!.agendaList
        .any((post) => post.docID.trim() == fallback.docID.trim()))
      fallback,
    ...controller.agendaList.where(
      (post) => post.docID.trim() != fallback.docID.trim(),
    ),
  ];
  controller.agendaList.assignAll(merged);
  return fallback.docID.trim();
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
  if (unresolved.isEmpty) return resolved;

  final posts = FirebaseFirestore.instance.collection('Posts');
  final merged = Map<String, PostsModel>.from(resolved);
  for (final docId in unresolved) {
    try {
      final snap = await posts.doc(docId).get();
      if (!snap.exists) continue;
      final data = snap.data();
      if (data == null) continue;
      merged[docId] = PostsModel.fromMap(data, snap.id);
    } catch (_) {}
  }
  return merged;
}
