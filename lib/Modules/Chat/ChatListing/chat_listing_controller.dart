import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:turqappv2/Core/Helpers/UnreadMessagesController/unread_messages_controller.dart';
import 'package:turqappv2/Core/Repositories/conversation_repository.dart';
import 'package:turqappv2/Core/Services/cache_invalidation_service.dart';
import 'package:turqappv2/Core/Utils/text_normalization_utils.dart';
import 'package:turqappv2/Services/current_user_service.dart';

import '../../../Models/chat_listing_model.dart';
import '../../../Core/Services/network_awareness_service.dart';
import '../../../Core/Services/user_profile_cache_service.dart';
import '../chat_unread_policy.dart';
import '../CreateChat/create_chat.dart';

part 'chat_listing_controller_data_part.dart';
part 'chat_listing_controller_actions_part.dart';
part 'chat_listing_controller_base_part.dart';
part 'chat_listing_controller_facade_part.dart';
part 'chat_listing_controller_fields_part.dart';
part 'chat_listing_controller_class_part.dart';
