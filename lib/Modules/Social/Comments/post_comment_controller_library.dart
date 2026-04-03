import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';

import '../../../Core/app_snackbar.dart';
import '../../../Core/Services/cache_invalidation_service.dart';
import '../../../Core/Services/giphy_picker_service.dart';
import '../../../Core/Services/user_summary_resolver.dart';
import '../../../Core/blocked_texts.dart';
import '../../../Models/post_interactions_models_new.dart';
import '../../../Services/current_user_service.dart';
import '../../../Services/post_interaction_service.dart';

part 'post_comment_controller_actions_part.dart';
part 'post_comment_controller_base_part.dart';
part 'post_comment_controller_class_part.dart';
part 'post_comment_controller_facade_part.dart';
part 'post_comment_controller_fields_part.dart';
part 'post_comment_controller_runtime_part.dart';
