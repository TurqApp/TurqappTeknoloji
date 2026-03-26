import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:audioplayers/audioplayers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path/path.dart' as path;
import 'package:turqappv2/Core/BottomSheets/no_yes_alert.dart';
import 'package:turqappv2/Core/Services/app_image_picker_service.dart';
import 'package:turqappv2/Core/Services/audio_focus_coordinator.dart';
import 'package:turqappv2/Core/Services/optimized_nsfw_service.dart';
import 'package:turqappv2/Core/Services/story_music_library_service.dart';
import 'package:turqappv2/Core/Services/upload_validation_service.dart';
import 'package:turqappv2/Core/Services/user_moderation_guard.dart';
import 'package:turqappv2/Core/Services/webp_upload_service.dart';
import 'package:turqappv2/Core/Utils/cdn_url_builder.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Models/music_model.dart';
import 'package:turqappv2/Modules/SpotifySelector/spotify_selector.dart';
import 'package:turqappv2/Modules/Story/StoryRow/story_row_controller.dart';
import 'package:turqappv2/Services/current_user_service.dart';
import 'package:video_player/video_player.dart';

import 'drawing_screen.dart';

part 'story_maker_controller_class_part.dart';
part 'story_maker_controller_media_part.dart';
part 'story_maker_controller_elements_part.dart';
part 'story_maker_controller_facade_part.dart';
part 'story_maker_controller_fields_part.dart';
part 'story_maker_controller_models_part.dart';
part 'story_maker_controller_save_part.dart';
part 'story_maker_controller_runtime_part.dart';
