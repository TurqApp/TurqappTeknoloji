// 📸 Image Helper Utility
// Provides optimized image URL generation with thumbnail support

class ImageHelper {
  /// Get thumbnail URL for Firebase Storage images
  /// Returns thumbnail URL based on desired width
  ///
  /// Example:
  /// ```dart
  /// final url = 'https://firebasestorage.googleapis.com/.../image.jpg';
  /// final thumb = ImageHelper.getThumbnailUrl(url, width: 300);
  /// // Returns: https://firebasestorage.googleapis.com/.../image_thumb_300.webp
  /// ```
  static String getThumbnailUrl(String originalUrl, {int width = 300}) {
    if (originalUrl.isEmpty) return '';

    // Only process Firebase Storage URLs
    if (!originalUrl.contains('firebasestorage.googleapis.com')) {
      return originalUrl;
    }

    // Skip if already a thumbnail
    if (originalUrl.contains('_thumb_')) {
      return originalUrl;
    }

    // Determine best thumbnail size based on requested width
    final thumbnailSize = _selectThumbnailSize(width);
    final suffix = '_thumb_$thumbnailSize';

    // Replace extension with thumbnail suffix + .webp
    // Supports: .jpg, .jpeg, .png, .webp
    final thumbUrl = originalUrl.replaceFirstMapped(
      RegExp(r'\.(jpg|jpeg|png|webp)', caseSensitive: false),
      (match) => '$suffix.webp',
    );

    return thumbUrl;
  }

  /// Select optimal thumbnail size
  /// - width <= 200  → 150px thumbnail (avatars)
  /// - width <= 400  → 300px thumbnail (feed previews)
  /// - width > 400   → 600px thumbnail (detail views)
  static int _selectThumbnailSize(int requestedWidth) {
    if (requestedWidth <= 200) return 150;
    if (requestedWidth <= 400) return 300;
    return 600;
  }

  /// Get original (full-size) URL
  /// Useful when thumbnail doesn't exist yet
  static String getOriginalUrl(String thumbnailUrl) {
    if (thumbnailUrl.isEmpty) return '';

    // Remove thumbnail suffix
    return thumbnailUrl.replaceAllMapped(
      RegExp(r'_thumb_\d+\.webp'),
      (match) {
        // Try to detect original extension from URL params or default to .webp
        return '.webp';
      },
    );
  }

  /// Check if URL is a Firebase Storage URL
  static bool isFirebaseStorageUrl(String url) {
    return url.contains('firebasestorage.googleapis.com');
  }

  /// Check if URL is already a thumbnail
  static bool isThumbnail(String url) {
    return url.contains('_thumb_');
  }

  /// Get thumbnail URLs for all sizes
  /// Useful for preloading multiple sizes
  static Map<int, String> getAllThumbnailUrls(String originalUrl) {
    return {
      150: getThumbnailUrl(originalUrl, width: 150),
      300: getThumbnailUrl(originalUrl, width: 300),
      600: getThumbnailUrl(originalUrl, width: 600),
    };
  }
}
