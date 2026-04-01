import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Repositories/practice_exam_repository.dart';
import 'package:turqappv2/Core/Services/CacheFirst/cache_first.dart';
import 'package:turqappv2/Core/Services/pasaj_feature_gate.dart';
import 'package:turqappv2/Core/Services/read_budget_registry.dart';
import 'package:turqappv2/Core/Services/typesense_education_service.dart';
import 'package:turqappv2/Modules/Education/pasaj_tabs.dart';
import 'package:turqappv2/Modules/Education/PracticeExams/sinav_model.dart';

part 'practice_exam_snapshot_repository_query_part.dart';
part 'practice_exam_snapshot_repository_codec_part.dart';
part 'practice_exam_snapshot_repository_facade_part.dart';
part 'practice_exam_snapshot_repository_runtime_part.dart';
