part of 'upload_queue_service.dart';

Future<int> _resolveMaxVideoBytesForStorageRule() =>
    UploadValidationService.currentMaxVideoSizeBytesAsync();

const Duration _recentDuplicateWindow = Duration(minutes: 15);
const String _queueKeyPrefix = 'upload_queue';
const int _maxRetries = 3;
