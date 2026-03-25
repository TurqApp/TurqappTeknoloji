import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:turqappv2/Core/Repositories/notifications_repository.dart';
import 'package:turqappv2/Core/job_collection_helper.dart';
import 'package:turqappv2/Core/Services/read_budget_registry.dart';
import 'package:turqappv2/Core/Utils/text_normalization_utils.dart';
import 'package:turqappv2/Models/job_review_model.dart';
import 'package:turqappv2/Models/job_model.dart';
import 'package:turqappv2/Models/job_application_model.dart';

part 'job_repository_query_part.dart';
part 'job_repository_action_part.dart';
part 'job_repository_cache_part.dart';
part 'job_repository_models_part.dart';

class JobRepository extends GetxService {
  JobRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  static const Duration _ttl = Duration(hours: 6);
  static const String _prefsPrefix = 'job_repository_v1';
  final Map<String, _TimedJobs> _memory = <String, _TimedJobs>{};
  final Map<String, _TimedBool> _boolMemory = <String, _TimedBool>{};
  SharedPreferences? _prefs;

  static JobRepository? maybeFind() {
    final isRegistered = Get.isRegistered<JobRepository>();
    if (!isRegistered) return null;
    return Get.find<JobRepository>();
  }

  static JobRepository ensure() {
    final existing = maybeFind();
    if (existing != null) return existing;
    return Get.put(JobRepository(), permanent: true);
  }

  @override
  void onInit() {
    super.onInit();
    SharedPreferences.getInstance().then((prefs) => _prefs = prefs);
  }
}
