import 'dart:async';
import 'dart:collection';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:turqappv2/Core/Services/PlaybackIntelligence/metadata_cache_policy.dart';
import 'package:turqappv2/Core/Services/PlaybackIntelligence/metadata_read_policy.dart';
import 'package:turqappv2/Core/Services/qa_lab_mode.dart';
import 'package:turqappv2/Core/Utils/avatar_url.dart';
import 'package:turqappv2/Core/Utils/nickname_utils.dart';

import 'turq_image_cache_manager.dart';

part 'user_profile_cache_service_fetch_part.dart';
part 'user_profile_cache_service_base_part.dart';
part 'user_profile_cache_service_class_part.dart';
part 'user_profile_cache_service_facade_part.dart';
part 'user_profile_cache_service_storage_part.dart';

class _CachedUserProfile {
  final Map<String, dynamic> data;
  final DateTime cachedAt;

  _CachedUserProfile({
    required Map<String, dynamic> data,
    required this.cachedAt,
  }) : data = data.map(
         (key, value) => MapEntry(
           key,
           _cloneCachedUserProfileValue(value),
         ),
       );
}

dynamic _cloneCachedUserProfileValue(dynamic value) {
  if (value is Map) {
    return value.map(
      (key, nestedValue) => MapEntry(
        key.toString(),
        _cloneCachedUserProfileValue(nestedValue),
      ),
    );
  }
  if (value is List) {
    return value
        .map(_cloneCachedUserProfileValue)
        .toList(growable: false);
  }
  return value;
}
