import 'dart:async';

import 'package:get/get.dart';
import 'package:turqappv2/Core/Services/CacheFirst/cache_first.dart';
import 'package:turqappv2/Core/Services/read_budget_registry.dart';
import 'package:turqappv2/Core/Services/typesense_education_service.dart';
import 'package:turqappv2/Core/Services/user_summary_resolver.dart';
import 'package:turqappv2/Models/Education/individual_scholarships_model.dart';
import 'package:turqappv2/Modules/Education/Scholarships/scholarship_constants.dart';

part 'scholarship_snapshot_repository_models_part.dart';
part 'scholarship_snapshot_repository_facade_part.dart';
part 'scholarship_snapshot_repository_state_part.dart';
part 'scholarship_snapshot_repository_query_part.dart';
part 'scholarship_snapshot_repository_codec_part.dart';

class ScholarshipSnapshotRepository extends GetxService {
  ScholarshipSnapshotRepository();

  static const String _homeSurfaceKey = 'scholarship_home_snapshot';
  static const String _searchSurfaceKey = 'scholarship_search_snapshot';

  static ScholarshipSnapshotRepository? maybeFind() {
    final isRegistered = Get.isRegistered<ScholarshipSnapshotRepository>();
    if (!isRegistered) return null;
    return Get.find<ScholarshipSnapshotRepository>();
  }

  static ScholarshipSnapshotRepository ensure() {
    final existing = maybeFind();
    if (existing != null) return existing;
    return Get.put(ScholarshipSnapshotRepository(), permanent: true);
  }

  final _state = _ScholarshipSnapshotRepositoryState();
}
