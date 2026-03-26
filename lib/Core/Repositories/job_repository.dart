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
part 'job_repository_facade_part.dart';
part 'job_repository_class_part.dart';
part 'job_repository_fields_part.dart';
part 'job_repository_models_part.dart';
