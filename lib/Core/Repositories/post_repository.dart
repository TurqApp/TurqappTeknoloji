import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:turqappv2/Core/Repositories/user_repository.dart';
import 'package:turqappv2/Core/Services/integration_test_mode.dart';
import 'package:turqappv2/Core/Repositories/user_subcollection_repository.dart';
import 'package:turqappv2/Core/Services/read_budget_registry.dart';
import 'package:turqappv2/Core/Services/typesense_post_service.dart';
import 'package:turqappv2/Services/current_user_service.dart';

import '../../Models/posts_model.dart';
import '../../Models/post_sharers_model.dart';
import '../../Services/post_count_manager.dart';
import '../../Services/post_interaction_service.dart';

part 'post_repository_interaction_part.dart';
part 'post_repository_base_part.dart';
part 'post_repository_facade_part.dart';
part 'post_repository_models_part.dart';
part 'post_repository_query_part.dart';
part 'post_repository_sharing_part.dart';
part 'post_repository_support_part.dart';
part 'post_repository_class_part.dart';
part 'post_repository_fields_part.dart';
