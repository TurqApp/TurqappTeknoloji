import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'story_highlights_controller.dart';

class HighlightPickerSheet extends StatefulWidget {
  final String storyId;
  const HighlightPickerSheet({super.key, required this.storyId});

  @override
  State<HighlightPickerSheet> createState() => _HighlightPickerSheetState();
}

class _HighlightPickerSheetState extends State<HighlightPickerSheet> {
  final TextEditingController _titleController = TextEditingController();
  bool _isCreatingNew = false;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const SizedBox.shrink();
    final media = MediaQuery.of(context);
    final topInset = media.padding.top;
    final bottomInset = media.viewInsets.bottom;

    final tag = 'highlights_$uid';
    final controller = Get.isRegistered<StoryHighlightsController>(tag: tag)
        ? Get.find<StoryHighlightsController>(tag: tag)
        : Get.put(StoryHighlightsController(userId: uid), tag: tag);

    return Container(
      margin: EdgeInsets.only(top: topInset + 4),
      constraints: BoxConstraints(
        maxHeight: media.size.height - topInset - 8,
      ),
      padding: EdgeInsets.fromLTRB(16, 10, 16, 16 + bottomInset),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFD9D9D9),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Öne Çıkarılanlar',
              style: TextStyle(
                color: Colors.black,
                fontSize: 19,
                fontFamily: 'MontserratBold',
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Hikayeni profiline sabitlemek için bir başlık oluştur.',
              style: TextStyle(
                color: Color(0xFF6F6F6F),
                fontSize: 12,
                fontFamily: 'MontserratMedium',
              ),
            ),
            const SizedBox(height: 12),
            Obx(() {
              if (controller.highlights.isEmpty && !_isCreatingNew) {
                return _buildNewHighlightForm(controller);
              }
              return Column(
                children: [
                  ...controller.highlights.map((h) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF7F7F7),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        leading: ClipOval(
                          child: SizedBox(
                            width: 40,
                            height: 40,
                            child: h.coverUrl.isNotEmpty
                                ? CachedNetworkImage(
                                    imageUrl: h.coverUrl,
                                    fit: BoxFit.cover,
                                  )
                                : Container(
                                    color: Colors.grey.withAlpha(30),
                                    child: const Icon(
                                      CupertinoIcons.collections,
                                      size: 18,
                                    ),
                                  ),
                          ),
                        ),
                        title: Text(
                          h.title,
                          style: const TextStyle(
                            fontFamily: 'MontserratMedium',
                            fontSize: 14,
                            color: Colors.black,
                          ),
                        ),
                        subtitle: Text(
                          '${h.storyIds.length} hikaye',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF8A8A8A),
                            fontFamily: 'MontserratMedium',
                          ),
                        ),
                        trailing: h.storyIds.contains(widget.storyId)
                            ? const Icon(
                                CupertinoIcons.checkmark_circle_fill,
                                color: Colors.black,
                              )
                            : const Icon(
                                CupertinoIcons.plus_circle,
                                color: Colors.black54,
                              ),
                        onTap: () async {
                          if (!h.storyIds.contains(widget.storyId)) {
                            await controller.addStoryToHighlight(
                              h.id,
                              widget.storyId,
                            );
                          }
                          Get.back();
                        },
                      ),
                    );
                  }),
                  const SizedBox(height: 2),
                  if (_isCreatingNew)
                    _buildNewHighlightForm(controller)
                  else
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFFDDDDDD),
                          ),
                        ),
                        child: const Icon(CupertinoIcons.add, size: 20),
                      ),
                      title: const Text(
                        'Yeni Öne Çıkarılan',
                        style: TextStyle(
                          fontFamily: 'MontserratMedium',
                          fontSize: 14,
                          color: Colors.black,
                        ),
                      ),
                      onTap: () => setState(() => _isCreatingNew = true),
                    ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildNewHighlightForm(StoryHighlightsController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.black.withValues(alpha: 0.2)),
                color: Colors.white,
              ),
              child: TextField(
                controller: _titleController,
                autofocus: false,
                decoration: InputDecoration(
                  hintText: 'Başlık girin...',
                  hintStyle: TextStyle(
                    color: Colors.grey.withAlpha(150),
                    fontSize: 14,
                    fontFamily: 'MontserratMedium',
                  ),
                  border: InputBorder.none,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                style: const TextStyle(
                  fontFamily: 'MontserratMedium',
                  fontSize: 14,
                  color: Colors.black,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              onPressed: _isSubmitting
                  ? null
                  : () async {
                      final title = _titleController.text.trim();
                      if (title.isEmpty) return;
                      setState(() => _isSubmitting = true);
                      try {
                        final created = await controller.createHighlight(
                          title: title,
                          storyIds: [widget.storyId],
                        );
                        if (created != null) {
                          Get.back();
                        } else {
                          AppSnackbar(
                            'Hata',
                            'Öne çıkarılan oluşturulamadı. Lütfen tekrar deneyin.',
                          );
                        }
                      } finally {
                        if (mounted) setState(() => _isSubmitting = false);
                      }
                    },
              child: _isSubmitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Oluştur',
                      style: TextStyle(
                        fontFamily: 'MontserratSemiBold',
                        fontSize: 14,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
