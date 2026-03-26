import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:turqappv2/Core/Services/read_budget_registry.dart';
import 'package:turqappv2/Core/Services/scholarship_firestore_path.dart';
import 'package:turqappv2/Models/Education/individual_scholarships_model.dart';

part 'scholarship_repository_query_part.dart';
part 'scholarship_repository_action_part.dart';
part 'scholarship_repository_cache_part.dart';
part 'scholarship_repository_facade_part.dart';
part 'scholarship_repository_fields_part.dart';
part 'scholarship_repository_models_part.dart';

class ScholarshipRepository extends GetxService {
  static const Duration _ttl = Duration(hours: 12);
  static const String _prefsPrefix = 'scholarship_repository_v1:';
  static const String _applyPrefix = 'scholarship_apply_repository_v1:';
  static const String _countKey = 'scholarship_total_count_v1';
  final _state = _ScholarshipRepositoryState();

  static ScholarshipRepository? maybeFind() =>
      _maybeFindScholarshipRepository();

  static ScholarshipRepository ensure() => _ensureScholarshipRepository();

  @override
  void onInit() {
    super.onInit();
    _handleScholarshipRepositoryInit(this);
  }
}
