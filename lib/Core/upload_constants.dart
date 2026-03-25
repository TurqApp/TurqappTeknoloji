class UploadConstants {
  static const int maxImageSizeBytes = 8 * 1024 * 1024;
  static const int maxRegularVideoSizeBytes = 35 * 1024 * 1024;
  static const int maxBadgedVideoSizeBytes = 45 * 1024 * 1024;
  static const int maxVideoSizeBytes = maxBadgedVideoSizeBytes;
  static const int maxPassthroughVideoBytes = 35 * 1024 * 1024;
  static const int maxTotalPostSizeBytes = 150 * 1024 * 1024;

  // Count limits
  static const int maxImagesPerPost = 4;
  static const int maxVideosPerPost = 1;

  static const int maxVideoLengthSeconds = 1800;

  static const int maxImageWidth = 4096;
  static const int maxImageHeight = 4096;
  static const int maxVideoWidth = 1920;
  static const int maxVideoHeight = 1080;
  static const int thumbnailMaxWidth = 600;

  static const int defaultImageQuality = 85;
  static const int highImageQuality = 95;
  static const int mediumImageQuality = 70;

  static String formatBytes(int bytes) {
    if (bytes >= 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    } else if (bytes >= 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else if (bytes >= 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else {
      return '$bytes bytes';
    }
  }

  static String getMaxImageSizeText() => formatBytes(maxImageSizeBytes);
  static String getMaxVideoSizeText() => formatBytes(maxVideoSizeBytes);
  static String getMaxTotalSizeText() => formatBytes(maxTotalPostSizeBytes);
}
