import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Repositories/notifications_snapshot_repository.dart';
import 'package:turqappv2/Core/Repositories/notifications_repository.dart';
import 'package:turqappv2/Core/Services/CacheFirst/cache_first.dart';
import 'package:turqappv2/Core/Services/integration_test_mode.dart';
import 'package:turqappv2/Core/Services/notification_preferences_service.dart';
import 'package:turqappv2/Core/Utils/text_normalization_utils.dart';
import 'package:turqappv2/Models/notification_model.dart';
import 'package:turqappv2/Modules/InAppNotifications/notification_post_types.dart';
import 'package:turqappv2/Services/current_user_service.dart';

part 'in_app_notifications_controller_data_part.dart';
part 'in_app_notifications_controller_actions_part.dart';
part 'in_app_notifications_controller_base_part.dart';
part 'in_app_notifications_controller_class_part.dart';
part 'in_app_notifications_controller_facade_part.dart';
part 'in_app_notifications_controller_fields_part.dart';
