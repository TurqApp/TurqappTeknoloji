import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:turqappv2/Core/Repositories/local_preference_repository.dart';
import 'package:turqappv2/Core/Repositories/scholarship_snapshot_repository.dart';
import 'package:turqappv2/Core/Services/read_budget_registry.dart';
import 'package:turqappv2/Core/Services/scholarship_firestore_path.dart';
import 'package:turqappv2/Core/Services/typesense_education_service.dart';
import 'package:turqappv2/Models/Education/individual_scholarships_model.dart';

part 'scholarship_repository_query_part.dart';
part 'scholarship_repository_action_part.dart';
part 'scholarship_repository_cache_part.dart';
part 'scholarship_repository_facade_part.dart';
part 'scholarship_repository_fields_part.dart';
part 'scholarship_repository_models_part.dart';
part 'scholarship_repository_support_part.dart';

class ScholarshipRepository extends GetxService {
  final _state = _ScholarshipRepositoryState();

  @override
  void onInit() {
    super.onInit();
    _handleScholarshipRepositoryInit(this);
  }
}
