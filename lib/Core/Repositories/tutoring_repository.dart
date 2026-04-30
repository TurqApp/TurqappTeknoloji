import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:turqappv2/Core/Repositories/local_preference_repository.dart';
import 'package:turqappv2/Core/Repositories/notifications_repository.dart';
import 'package:turqappv2/Core/Repositories/tutoring_snapshot_repository.dart';
import 'package:turqappv2/Core/Services/app_firestore.dart';
import 'package:turqappv2/Core/Services/read_budget_registry.dart';
import 'package:turqappv2/Core/Services/typesense_education_service.dart';
import 'package:turqappv2/Core/Utils/location_text_utils.dart';
import 'package:turqappv2/Models/Education/tutoring_application_model.dart';
import 'package:turqappv2/Models/Education/tutoring_model.dart';
import 'package:turqappv2/Models/Education/tutoring_review_model.dart';

part 'tutoring_repository_query_part.dart';
part 'tutoring_repository_action_part.dart';
part 'tutoring_repository_base_part.dart';
part 'tutoring_repository_class_part.dart';
part 'tutoring_repository_cache_part.dart';
part 'tutoring_repository_facade_part.dart';

class TutoringPage {
  const TutoringPage({
    required this.items,
    required this.lastDocument,
    required this.hasMore,
  });

  final List<TutoringModel> items;
  final DocumentSnapshot? lastDocument;
  final bool hasMore;
}

class _TimedValue<T> {
  const _TimedValue({
    required this.value,
    required this.cachedAt,
  });

  final T value;
  final DateTime cachedAt;
}
