// 📁 lib/Services/offline_mode_service.dart
// 📡 Offline mode detection and queue management
// Works with CurrentUserService for seamless offline experience

import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:turqappv2/Core/follow_service.dart';
import 'package:turqappv2/Services/current_user_service.dart';

part 'offline_mode_service_queue_part.dart';
part 'offline_mode_service_persistence_part.dart';
part 'offline_mode_service_action_part.dart';
part 'offline_mode_service_facade_part.dart';
part 'offline_mode_service_fields_part.dart';
part 'offline_mode_service_runtime_part.dart';
part 'offline_mode_service_models_part.dart';
part 'offline_mode_service_class_part.dart';
