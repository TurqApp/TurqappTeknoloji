import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Repositories/local_preference_repository.dart';
import 'package:turqappv2/Core/Services/app_firestore.dart';
import 'package:turqappv2/Core/Services/read_budget_registry.dart';
import 'package:turqappv2/Models/hashtag_model.dart';
import 'package:turqappv2/Models/posts_model.dart';
import 'package:turqappv2/Services/current_user_service.dart';

part 'top_tags_repository_cache_part.dart';
part 'top_tags_repository_base_part.dart';
part 'top_tags_repository_runtime_part.dart';
