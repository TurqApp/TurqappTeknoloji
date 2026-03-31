import 'dart:convert';
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:turqappv2/Core/Repositories/conversation_repository.dart';
import 'package:turqappv2/Models/chat_listing_model.dart';
import 'package:turqappv2/Modules/Chat/chat_unread_policy.dart';
import 'package:turqappv2/Services/current_user_service.dart';

import '../../Services/network_awareness_service.dart';

part 'unread_messages_controller_fields_part.dart';
part 'unread_messages_controller_base_part.dart';
part 'unread_messages_controller_class_part.dart';
part 'unread_messages_controller_facade_part.dart';
part 'unread_messages_controller_support_part.dart';
part 'unread_messages_controller_sync_part.dart';
