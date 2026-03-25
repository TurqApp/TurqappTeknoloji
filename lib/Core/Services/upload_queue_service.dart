import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:get/get.dart';
import 'package:image/image.dart' as img;
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:turqappv2/Core/upload_constants.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:turqappv2/Core/Utils/cdn_url_builder.dart';
import 'package:turqappv2/Core/Utils/nickname_utils.dart';
import 'package:turqappv2/Core/Utils/text_normalization_utils.dart';
import 'package:turqappv2/Core/Utils/user_scoped_key.dart';
import 'package:turqappv2/Core/Services/optimized_nsfw_service.dart';
import 'package:turqappv2/Core/Repositories/post_repository.dart';
import 'package:turqappv2/Core/Services/upload_validation_service.dart';
import 'package:turqappv2/Core/Services/video_compression_service.dart';
import 'package:turqappv2/Core/Services/typesense_post_service.dart';
import 'package:turqappv2/Core/Services/webp_upload_service.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Services/current_user_service.dart';

part 'upload_queue_service_helpers_part.dart';
part 'upload_queue_service_facade_part.dart';
part 'upload_queue_service_queue_part.dart';
part 'upload_queue_service_lifecycle_part.dart';
part 'upload_queue_service_models_part.dart';
part 'upload_queue_service_persistence_part.dart';
part 'upload_queue_service_post_shell_part.dart';
part 'upload_queue_service_processing_part.dart';

class UploadQueueService extends GetxController {
  static UploadQueueService? maybeFind() {
    final isRegistered = Get.isRegistered<UploadQueueService>();
    if (!isRegistered) return null;
    return Get.find<UploadQueueService>();
  }

  static UploadQueueService ensure({bool permanent = false}) {
    final existing = maybeFind();
    if (existing != null) return existing;
    return Get.put(UploadQueueService(), permanent: permanent);
  }

  static int get _maxVideoBytesForStorageRule =>
      UploadValidationService.currentMaxVideoSizeBytes;
  static const Duration _recentDuplicateWindow = Duration(minutes: 15);
  final RxList<QueuedUpload> _queue = <QueuedUpload>[].obs;
  final RxBool _isProcessing = false.obs;
  final RxBool _isPaused = false.obs;
  final RxInt _failedCount = 0.obs;
  final RxInt _completedCount = 0.obs;
  StreamSubscription<User?>? _authSub;

  static const String _queueKeyPrefix = 'upload_queue';
  static const int _maxRetries = 3;

  void _notifyQueueUpdated() {
    _queue.refresh();
  }

  @override
  void onInit() {
    super.onInit();
    _UploadQueueServiceLifecyclePart(this).handleOnInit();
  }

  Future<void> _createPendingPostShell(QueuedUpload upload) =>
      _performCreatePendingPostShell(upload);

  /// Save queue to local storage
  Future<void> _saveQueueToStorage() => _performSaveQueueToStorage();

  /// Load queue from local storage
  Future<void> _loadQueueFromStorage() => _performLoadQueueFromStorage();

  @override
  void onClose() {
    _UploadQueueServiceLifecyclePart(this).handleOnClose();
    super.onClose();
  }
}
