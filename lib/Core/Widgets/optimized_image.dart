// 📸 Optimized Image Widget
// Drop-in replacement for CachedNetworkImage with automatic thumbnail selection

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../Services/turq_image_cache_manager.dart';
import '../Utils/image_helper.dart';

class OptimizedImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final PlaceholderWidgetBuilder? placeholder;
  final LoadingErrorWidgetBuilder? errorWidget;
  final bool useThumbnail;
  final int? memCacheWidth;
  final int? memCacheHeight;

  const OptimizedImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
    this.useThumbnail = true,
    this.memCacheWidth,
    this.memCacheHeight,
  });

  @override
  Widget build(BuildContext context) {
    // Get optimized URL (thumbnail if available)
    final String optimizedUrl = useThumbnail && ImageHelper.isFirebaseStorageUrl(imageUrl)
        ? ImageHelper.getThumbnailUrl(
            imageUrl,
            width: width?.toInt() ?? 300,
          )
        : imageUrl;

    // Calculate memory cache dimensions
    final int? effectiveMemCacheWidth = memCacheWidth ?? width?.toInt();
    final int? effectiveMemCacheHeight = memCacheHeight ?? height?.toInt();

    return CachedNetworkImage(
      imageUrl: optimizedUrl,
      cacheManager: TurqImageCacheManager.instance,
      width: width,
      height: height,
      fit: fit,

      // ✅ Memory cache optimization
      memCacheWidth: effectiveMemCacheWidth,
      memCacheHeight: effectiveMemCacheHeight,

      // ✅ Disk cache optimization
      maxWidthDiskCache: 600, // Max 600px disk cache
      maxHeightDiskCache: 600,

      // ✅ No fade for cached images — instant display
      fadeInDuration: Duration.zero,
      fadeOutDuration: Duration.zero,
      placeholderFadeInDuration: Duration.zero,

      // ✅ Placeholder
      placeholder: placeholder ??
          (context, url) => Container(
                width: width,
                height: height,
                color: Colors.grey[200],
                child: const Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
                  ),
                ),
              ),

      // ✅ Error widget with retry fallback
      errorWidget: errorWidget ??
          (context, url, error) {
            // If thumbnail failed, try original URL
            if (ImageHelper.isThumbnail(optimizedUrl)) {
              return CachedNetworkImage(
                imageUrl: imageUrl, // Original URL
                cacheManager: TurqImageCacheManager.instance,
                width: width,
                height: height,
                fit: fit,
                memCacheWidth: effectiveMemCacheWidth,
                memCacheHeight: effectiveMemCacheHeight,
                placeholder: (context, url) => Container(
                  width: width,
                  height: height,
                  color: Colors.grey[200],
                ),
                errorWidget: (context, url, error) => Container(
                  width: width,
                  height: height,
                  color: Colors.grey[300],
                  child: const Icon(
                    Icons.broken_image,
                    color: Colors.grey,
                  ),
                ),
              );
            }

            // Default error widget
            return Container(
              width: width,
              height: height,
              color: Colors.grey[300],
              child: const Icon(
                Icons.broken_image,
                color: Colors.grey,
              ),
            );
          },
    );
  }
}

/// Optimized Circle Avatar with thumbnail support
class OptimizedCircleAvatar extends StatelessWidget {
  final String imageUrl;
  final double radius;
  final Color? backgroundColor;

  const OptimizedCircleAvatar({
    super.key,
    required this.imageUrl,
    this.radius = 20,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final thumbnailUrl = ImageHelper.getThumbnailUrl(
      imageUrl,
      width: (radius * 2).toInt(),
    );

    return CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor ?? Colors.grey[200],
      backgroundImage: imageUrl.isNotEmpty
          ? CachedNetworkImageProvider(
              thumbnailUrl,
              cacheManager: TurqImageCacheManager.instance,
              maxWidth: (radius * 2).toInt(),
              maxHeight: (radius * 2).toInt(),
            )
          : null,
      child: imageUrl.isEmpty
          ? Icon(
              Icons.person,
              size: radius,
              color: Colors.grey[400],
            )
          : null,
    );
  }
}

/// Optimized Network Image for simple use cases
class OptimizedNetworkImage extends StatelessWidget {
  final String imageUrl;
  final BoxFit fit;
  final double? width;
  final double? height;

  const OptimizedNetworkImage({
    super.key,
    required this.imageUrl,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return OptimizedImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
    );
  }
}
