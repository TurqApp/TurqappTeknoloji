import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:turqappv2/Core/Repositories/local_preference_repository.dart';
import 'package:turqappv2/Core/Services/PlaybackIntelligence/metadata_read_policy.dart';
import 'package:turqappv2/Core/Repositories/post_repository.dart';
import 'package:turqappv2/Core/Repositories/profile_posts_snapshot_repository.dart';
import 'package:turqappv2/Core/Services/app_firebase_auth.dart';
import 'package:turqappv2/Core/Services/app_firestore.dart';
import 'package:turqappv2/Core/Services/PlaybackIntelligence/metadata_cache_policy.dart';
import 'package:turqappv2/Core/Services/CacheFirst/cached_resource.dart';
import 'package:turqappv2/Models/posts_model.dart';
import 'package:turqappv2/Services/current_user_service.dart';

part 'profile_repository_cache_part.dart';
part 'profile_repository_facade_part.dart';
part 'profile_repository_fields_part.dart';
part 'profile_repository_query_part.dart';
