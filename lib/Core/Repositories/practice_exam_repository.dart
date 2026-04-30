import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:turqappv2/Core/Repositories/local_preference_repository.dart';
import 'package:turqappv2/Core/Repositories/practice_exam_snapshot_repository.dart';
import 'package:turqappv2/Core/Services/app_firestore.dart';
import 'package:turqappv2/Core/Services/read_budget_registry.dart';
import 'package:turqappv2/Core/Services/typesense_education_service.dart';
import 'package:turqappv2/Modules/Education/PracticeExams/ders_ve_sonuclar_model.dart';
import 'package:turqappv2/Modules/Education/PracticeExams/sinav_model.dart';
import 'package:turqappv2/Modules/Education/PracticeExams/soru_model.dart';

part 'practice_exam_repository_action_part.dart';
part 'practice_exam_repository_query_part.dart';
part 'practice_exam_repository_detail_part.dart';
part 'practice_exam_repository_facade_part.dart';
part 'practice_exam_repository_fields_part.dart';
part 'practice_exam_repository_models_part.dart';
part 'practice_exam_repository_lifecycle_part.dart';
part 'practice_exam_repository_cache_part.dart';
part 'practice_exam_repository_helpers_part.dart';
part 'practice_exam_repository_constants_part.dart';
