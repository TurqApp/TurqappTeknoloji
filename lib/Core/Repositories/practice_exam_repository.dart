import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:turqappv2/Core/Services/read_budget_registry.dart';
import 'package:turqappv2/Core/Utils/text_normalization_utils.dart';
import 'package:turqappv2/Modules/Education/PracticeExams/ders_ve_sonuclar_model.dart';
import 'package:turqappv2/Modules/Education/PracticeExams/sinav_model.dart';
import 'package:turqappv2/Modules/Education/PracticeExams/soru_model.dart';

part 'practice_exam_repository_query_part.dart';
part 'practice_exam_repository_detail_part.dart';
part 'practice_exam_repository_class_part.dart';
part 'practice_exam_repository_models_part.dart';
part 'practice_exam_repository_lifecycle_part.dart';
part 'practice_exam_repository_cache_part.dart';
part 'practice_exam_repository_helpers_part.dart';
