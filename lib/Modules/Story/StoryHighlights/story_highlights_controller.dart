import 'dart:async';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Repositories/story_repository.dart';
import 'package:turqappv2/Core/Repositories/story_highlights_repository.dart';
import 'package:turqappv2/Core/Services/silent_refresh_gate.dart';
import 'package:turqappv2/Core/Services/webp_upload_service.dart';
import 'package:turqappv2/Core/Utils/cdn_url_builder.dart';
import 'package:turqappv2/Core/Utils/text_normalization_utils.dart';
import 'package:turqappv2/Core/Utils/url_utils.dart';
import 'package:turqappv2/Services/current_user_service.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'story_highlight_model.dart';

part 'story_highlights_controller_cover_part.dart';
part 'story_highlights_controller_facade_part.dart';
part 'story_highlights_controller_runtime_part.dart';
part 'story_highlights_controller_actions_part.dart';
part 'story_highlights_controller_class_part.dart';
