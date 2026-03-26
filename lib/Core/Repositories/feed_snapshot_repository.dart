import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Repositories/post_repository.dart';
import 'package:turqappv2/Core/Services/CacheFirst/cache_first.dart';
import 'package:turqappv2/Core/Services/IndexPool/index_pool_store.dart';
import 'package:turqappv2/Core/Services/integration_test_mode.dart';
import 'package:turqappv2/Core/Services/runtime_invariant_guard.dart';
import 'package:turqappv2/Core/Services/user_summary_resolver.dart';
import 'package:turqappv2/Core/Services/visibility_policy_service.dart';
import 'package:turqappv2/Models/posts_model.dart';

part 'feed_snapshot_repository_fetch_part.dart';
part 'feed_snapshot_repository_codec_part.dart';
part 'feed_snapshot_repository_facade_part.dart';
part 'feed_snapshot_repository_fields_part.dart';
part 'feed_snapshot_repository_visibility_part.dart';
part 'feed_snapshot_repository_models_part.dart';
part 'feed_snapshot_repository_runtime_part.dart';

class FeedSnapshotRepository extends GetxService {
  FeedSnapshotRepository() {
    _state = _FeedSnapshotRepositoryState(this);
  }

  static const String _homeSurfaceKey = 'feed_home_snapshot';
  static const int _defaultPersistLimit = 40;
  static final Set<String> _hybridBackfillRequested = <String>{};
  late final _FeedSnapshotRepositoryState _state;

  static FeedSnapshotRepository? maybeFind() {
    final isRegistered = Get.isRegistered<FeedSnapshotRepository>();
    if (!isRegistered) return null;
    return Get.find<FeedSnapshotRepository>();
  }

  static FeedSnapshotRepository ensure() {
    final existing = maybeFind();
    if (existing != null) return existing;
    return Get.put(FeedSnapshotRepository(), permanent: true);
  }
}
