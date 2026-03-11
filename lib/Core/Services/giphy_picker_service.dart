import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:giphy_get/giphy_get.dart';

import 'gif_library_service.dart';

class GiphyPickerService {
  GiphyPickerService._();

  static const String _giphyApiKeyFromDefine =
      String.fromEnvironment('GIPHY_API_KEY', defaultValue: '');
  static const String _iosApiKey = 'nm7oSMwfZ2MMPa0BEXfsITsabvSLzkfD';
  static const String _androidApiKey = 'fvRJgAKFDSPPjifx8VEGmAFnLBU6wbp';

  static String get _effectiveApiKey {
    if (_giphyApiKeyFromDefine.isNotEmpty) {
      return _giphyApiKeyFromDefine;
    }
    if (kIsWeb) return '';
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
        return _iosApiKey;
      case TargetPlatform.android:
        return _androidApiKey;
      default:
        return '';
    }
  }

  static Future<String?> pickGifUrl(
    BuildContext context, {
    String randomId = 'turqapp',
  }) async {
    final selectedFromLibrary = await _showLibrarySheet(
      context,
      randomId: randomId,
      allowApiSearch: _effectiveApiKey.isNotEmpty,
    );
    if (selectedFromLibrary != null && selectedFromLibrary.isNotEmpty) {
      return selectedFromLibrary;
    }

    if (_effectiveApiKey.isNotEmpty) {
      final gif = await GiphyGet.getGif(
        context: context,
        apiKey: _effectiveApiKey,
        lang: GiphyLanguage.turkish,
        randomID: randomId,
        tabColor: Colors.white,
      );

      final url =
          gif?.images?.original?.url ?? gif?.images?.downsized?.url ?? '';
      if (url.isNotEmpty) {
        final category = _resolveCategory(gif);
        await GifLibraryService.instance.recordUsage(
          url,
          source: 'giphy',
          category: category,
        );
      }
      return url;
    }

    final manual = await _askManualUrl();
    if (manual != null && manual.trim().isNotEmpty) {
      await GifLibraryService.instance.recordUsage(
        manual.trim(),
        source: 'manual',
        category: 'gif',
      );
    }
    return manual;
  }

  static Future<String?> _showLibrarySheet(
    BuildContext context, {
    required String randomId,
    required bool allowApiSearch,
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
                        'giphyGif',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 16,
                          fontFamily: 'MontserratBold',
                        ),
                      ),
                    ),
                    if (allowApiSearch)
                      TextButton(
                        onPressed: () => Navigator.of(sheetContext).pop(''),
                        child: const Text(
                          'Giphy Ara',
                          style: TextStyle(
                            color: Colors.black,
                            fontFamily: 'MontserratBold',
                          ),
                        ),
                      )
                    else
                      TextButton(
                        onPressed: () => Navigator.of(sheetContext).pop(''),
                        child: const Text(
                          'URL Ekle',
                          style: TextStyle(
                            color: Colors.black,
                            fontFamily: 'MontserratBold',
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                FutureBuilder<List<Map<String, dynamic>>>(
                  future: GifLibraryService.instance.fetchGlobalLibrary(),
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
                          children: const [
                            Icon(
                              Icons.gif_box_outlined,
                              color: Colors.black38,
                              size: 34,
                            ),
                            SizedBox(height: 10),
                            Text(
                              'Henüz kayıtlı GIF yok',
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
                              child: Image.network(
                                url,
                                fit: BoxFit.cover,
                                gaplessPlayback: true,
                                loadingBuilder: (context, child, progress) {
                                  if (progress == null) return child;
                                  return Container(
                                    color: const Color(0xFFF3F4F6),
                                    child: const Center(
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    ),
                                  );
                                },
                                errorBuilder: (_, __, ___) => Container(
                                  color: const Color(0xFFF3F4F6),
                                  child: const Icon(
                                    Icons.broken_image_outlined,
                                    color: Colors.black38,
                                  ),
                                ),
                              ),
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

  static Future<String?> _askManualUrl() async {
    final controller = TextEditingController(text: 'https://');
    return Get.dialog<String>(
      AlertDialog(
        backgroundColor: const Color(0xFF1F1F1F),
        title: const Text(
          'GIF URL',
          style: TextStyle(color: Colors.white),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'https://...',
            hintStyle: TextStyle(color: Colors.white54),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white24),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white),
            ),
          ),
        ),
        actions: [
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Colors.white70,
            ),
            onPressed: () => Get.back(),
            child: const Text('İptal'),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Colors.white,
            ),
            onPressed: () => Get.back(result: controller.text.trim()),
            child: const Text('Ekle'),
          ),
        ],
      ),
    );
  }

  static String _resolveCategory(GiphyGif? gif) {
    if (gif == null) return 'gif';
    final url = (gif.url ?? '').toLowerCase();
    final slug = (gif.slug ?? '').toLowerCase();
    if (url.contains('/emoji/') || slug.contains('emoji-')) {
      return 'emoji';
    }
    if ((gif.isSticker ?? 0) == 1 || url.contains('/stickers/')) {
      return 'sticker';
    }
    return 'gif';
  }
}
