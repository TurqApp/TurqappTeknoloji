import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Services/CacheFirst/cache_first.dart';
import 'package:turqappv2/Core/Services/read_budget_registry.dart';
import 'package:turqappv2/Core/Services/typesense_education_service.dart';
import 'package:turqappv2/Core/Services/user_summary_resolver.dart';
import 'package:turqappv2/Core/job_collection_helper.dart';
import 'package:turqappv2/Models/job_model.dart';

part 'job_home_snapshot_repository_data_part.dart';
part 'job_home_snapshot_repository_facade_part.dart';
part 'job_home_snapshot_repository_fields_part.dart';
part 'job_home_snapshot_repository_query_part.dart';

class JobHomeSnapshotRepository extends GetxService {
  static const String _homeSurfaceKey = 'jobs_home_snapshot';
  static const String _searchSurfaceKey = 'jobs_search_snapshot';
  static const String _ownerSurfaceKey = 'jobs_owner_snapshot';

  final _JobHomeSnapshotRepositoryState _state;

  JobHomeSnapshotRepository() : _state = _JobHomeSnapshotRepositoryState() {
    _state.initialize(this);
  }
}
