import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:turqappv2/Core/Repositories/local_preference_repository.dart';
import 'package:turqappv2/Core/Repositories/user_subcollection_repository.dart';
import 'package:turqappv2/Core/Services/app_firestore.dart';
import 'package:turqappv2/Core/Services/turq_image_cache_manager.dart';
import 'package:turqappv2/Core/Utils/text_normalization_utils.dart';
import 'package:turqappv2/Models/music_model.dart';
import 'package:turqappv2/Services/current_user_service.dart';

part 'story_music_library_service_fetch_part.dart';
part 'story_music_library_service_action_part.dart';

class StoryMusicLibraryService {
  StoryMusicLibraryService._();

  static StoryMusicLibraryService? _instance;
  static StoryMusicLibraryService? maybeFind() => _instance;

  static StoryMusicLibraryService ensure() =>
      maybeFind() ?? (_instance = StoryMusicLibraryService._());

  static StoryMusicLibraryService get instance => ensure();

  static const String _cacheKey = 'storyMusic.library.v1';
  static const String _cacheTimeKey = 'storyMusic.library.updatedAt.v1';
  static const Duration _cacheTtl = Duration(days: 7);
  final UserSubcollectionRepository _userSubcollectionRepository =
      ensureUserSubcollectionRepository();

  CollectionReference<Map<String, dynamic>> get _collection =>
      AppFirestore.instance.collection('storyMusic');
}
