import 'dart:async';
import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Services/cache_invalidation_service.dart';
import 'package:turqappv2/Core/Services/app_firestore.dart';
import 'package:turqappv2/Core/Utils/bool_utils.dart';
import 'package:turqappv2/Core/Repositories/notifications_repository.dart';
import 'package:turqappv2/Core/Repositories/user_subcollection_repository.dart';
import 'package:turqappv2/Core/Services/user_moderation_guard.dart';
import 'package:turqappv2/Modules/InAppNotifications/notification_post_types.dart';

import '../Models/post_interactions_models_new.dart';
import '../Models/posts_model.dart';
import '../Models/user_interactions_models.dart';
import 'current_user_service.dart';
import 'offline_mode_service.dart';
import 'post_moderation_utils.dart';

part 'post_interaction_service_actions_part.dart';
part 'post_interaction_service_facade_part.dart';
part 'post_interaction_service_helpers_part.dart';
part 'post_interaction_service_moderation_part.dart';
part 'post_interaction_service_query_part.dart';
part 'post_interaction_service_models_part.dart';
part 'post_interaction_service_constants_part.dart';

/// Post etkileşimlerini yöneten servis.
///
/// Uygulamanın yeni Firestore mimarisine göre tüm etkileşimleri (beğeni,
/// yorum, kaydetme, yeniden paylaşma, görüntüleme, şikayet) Posts alt
/// koleksiyonları ile users alt koleksiyonları arasında çift yönlü olarak
/// senkronize eder.
