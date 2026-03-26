import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Repositories/short_repository.dart';
import 'package:turqappv2/Core/Services/CacheFirst/cache_first.dart';
import 'package:turqappv2/Core/Services/IndexPool/index_pool_store.dart';
import 'package:turqappv2/Core/Services/runtime_invariant_guard.dart';
import 'package:turqappv2/Core/Services/user_summary_resolver.dart';
import 'package:turqappv2/Core/Services/visibility_policy_service.dart';
import 'package:turqappv2/Models/posts_model.dart';

part 'short_snapshot_repository_query_part.dart';
part 'short_snapshot_repository_visibility_part.dart';
part 'short_snapshot_repository_models_part.dart';
part 'short_snapshot_repository_fields_part.dart';
part 'short_snapshot_repository_runtime_part.dart';
part 'short_snapshot_repository_facade_part.dart';

class ShortSnapshotRepository extends GetxService {
  late final _ShortSnapshotRepositoryShellState _shellState;
  ShortSnapshotRepository() {
    _shellState = _ShortSnapshotRepositoryShellState(this);
  }

  static const String _homeSurfaceKey = 'short_home_snapshot';
  static const int _defaultPersistLimit = 20;
  static const int _maxPageSkips = 4;
}
