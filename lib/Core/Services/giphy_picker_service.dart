import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Services/turq_image_cache_manager.dart';

import 'gif_library_service.dart';

class GiphyPickerService {
  GiphyPickerService._();

  static Future<String?> pickGifUrl(
    BuildContext context, {
    String randomId = 'turqapp',
  }) async {
    return _showLibrarySheet(
      context,
      randomId: randomId,
    );
  }

  static Future<String?> _showLibrarySheet(
    BuildContext context, {
    required String randomId,
  }) async {
    return showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      isScrollControlled: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 34,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.black12,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'GIF',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 16,
                          fontFamily: 'MontserratBold',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                FutureBuilder<List<Map<String, dynamic>>>(
                  future: _loadGifItemsForPicker(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 40),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }

                    final items = snapshot.data ?? const [];
                    if (items.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 28),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.gif_box_outlined,
                              color: Colors.black38,
                              size: 34,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'giphy_picker.empty'.tr,
                              style: TextStyle(
                                color: Colors.black54,
                                fontSize: 14,
                                fontFamily: 'MontserratMedium',
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return SizedBox(
                      height: MediaQuery.of(context).size.height * 0.48,
                      child: GridView.builder(
                        itemCount: items.length,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                          childAspectRatio: 1,
                        ),
                        itemBuilder: (context, index) {
                          final url = (items[index]['url'] ?? '').toString();
                          return GestureDetector(
                            onTap: () async {
                              await GifLibraryService.instance.recordUsage(
                                url,
                                source: 'library',
                                category: (items[index]['category'] ?? 'gif')
                                    .toString(),
                              );
                              if (sheetContext.mounted) {
                                Navigator.of(sheetContext).pop(url);
                              }
                            },
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: _GifGridTile(url: url),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static Future<List<Map<String, dynamic>>> _loadGifItemsForPicker() async {
    final items = await GifLibraryService.instance.fetchGlobalLibrary();
    if (items.isEmpty) return items;
    await GifLibraryService.instance.warmTopGifCache();
    return items;
  }
}

class _GifGridTile extends StatelessWidget {
  const _GifGridTile({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<FileInfo?>(
      future: TurqImageCacheManager.instance.getFileFromCache(url),
      builder: (context, snapshot) {
        final cachedFile = snapshot.data?.file;
        if (cachedFile != null && cachedFile.existsSync()) {
          return Image.file(
            cachedFile,
            fit: BoxFit.cover,
            gaplessPlayback: true,
          );
        }

        return CachedNetworkImage(
          imageUrl: url,
          cacheManager: TurqImageCacheManager.instance,
          fit: BoxFit.cover,
          fadeInDuration: Duration.zero,
          fadeOutDuration: Duration.zero,
          placeholderFadeInDuration: Duration.zero,
          placeholder: (context, _) => Container(
            color: const Color(0xFFF3F4F6),
            child: const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
          errorWidget: (_, __, ___) => Container(
            color: const Color(0xFFF3F4F6),
            child: const Icon(
              Icons.broken_image_outlined,
              color: Colors.black38,
            ),
          ),
        );
      },
    );
  }
}
