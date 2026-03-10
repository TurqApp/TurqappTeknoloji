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

    return SafeArea(
      top: false,
      child: AnimatedPadding(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: EdgeInsets.only(bottom: bottomInset),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: media.size.height - topInset - 24,
          ),
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
          decoration: BoxDecoration(
            color: const Color(0xFFFCFCFC),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x22000000),
                blurRadius: 24,
                offset: Offset(0, -8),
              ),
            ],
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 46,
                    height: 5,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD7D7D7),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: Colors.black.withValues(alpha: 0.06),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F1F1),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          CupertinoIcons.bookmark_fill,
                          color: Colors.black,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Öne Çıkarılanlar',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 18,
                                fontFamily: 'MontserratBold',
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Bu hikayeyi profilinde sabit bir koleksiyona ekle.',
                              style: TextStyle(
                                color: Color(0xFF6D6D6D),
                                fontSize: 12,
                                height: 1.35,
                                fontFamily: 'MontserratMedium',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Obx(() {
                  if (controller.highlights.isEmpty && !_isCreatingNew) {
                    return _buildEmptyCreateState(controller);
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(left: 2, bottom: 8),
                        child: Text(
                          'Koleksiyonların',
                          style: TextStyle(
                            color: Color(0xFF6D6D6D),
                            fontSize: 12,
                            fontFamily: 'MontserratSemiBold',
                          ),
                        ),
                      ),
                      ...controller.highlights.map((h) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: Colors.black.withValues(alpha: 0.06),
                            ),
                          ),
                          child: ListTile(
                            minTileHeight: 72,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 4,
                            ),
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: SizedBox(
                                width: 48,
                                height: 48,
                                child: h.coverUrl.isNotEmpty
                                    ? CachedNetworkImage(
                                        imageUrl: h.coverUrl,
                                        fit: BoxFit.cover,
                                      )
                                    : Container(
                                        color: const Color(0xFFF2F2F2),
                                        child: const Icon(
                                          CupertinoIcons.collections_solid,
                                          size: 20,
                                          color: Colors.black54,
                                        ),
                                      ),
                              ),
                            ),
                            title: Text(
                              h.title,
                              style: const TextStyle(
                                fontFamily: 'MontserratSemiBold',
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
                            trailing: Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: h.storyIds.contains(widget.storyId)
                                    ? Colors.black
                                    : const Color(0xFFF4F4F4),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                h.storyIds.contains(widget.storyId)
                                    ? CupertinoIcons.check_mark
                                    : CupertinoIcons.add,
                                color: h.storyIds.contains(widget.storyId)
                                    ? Colors.white
                                    : Colors.black,
                                size: 18,
                              ),
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
                      const SizedBox(height: 6),
                      if (_isCreatingNew)
                        _buildNewHighlightForm(controller)
                      else
                        _buildCreateAnotherTile(),
                    ],
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyCreateState(StoryHighlightsController controller) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'İlk koleksiyonunu oluştur',
            style: TextStyle(
              color: Colors.black,
              fontSize: 15,
              fontFamily: 'MontserratSemiBold',
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Bu hikaye için bir başlık belirle. Sonra profilinde sabit görünsün.',
            style: TextStyle(
              color: Color(0xFF6D6D6D),
              fontSize: 12,
              height: 1.35,
              fontFamily: 'MontserratMedium',
            ),
          ),
          const SizedBox(height: 14),
          _buildNewHighlightForm(controller),
        ],
      ),
    );
  }

  Widget _buildCreateAnotherTile() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => setState(() => _isCreatingNew = true),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
          ),
          child: const Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: Color(0xFFF3F3F3),
                child: Icon(
                  CupertinoIcons.add,
                  size: 20,
                  color: Colors.black,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Yeni öne çıkarılan oluştur',
                  style: TextStyle(
                    fontFamily: 'MontserratSemiBold',
                    fontSize: 14,
                    color: Colors.black,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNewHighlightForm(StoryHighlightsController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 52,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.black.withValues(alpha: 0.12)),
              color: Colors.white,
            ),
            child: TextField(
              controller: _titleController,
              autofocus: false,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                hintText: 'Başlık girin...',
                hintStyle: TextStyle(
                  color: Colors.grey.withAlpha(150),
                  fontSize: 14,
                  fontFamily: 'MontserratMedium',
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 14,
                ),
              ),
              style: const TextStyle(
                fontFamily: 'MontserratMedium',
                fontSize: 14,
                color: Colors.black,
              ),
              onSubmitted: (_) => _submitCreate(controller),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              onPressed: _isSubmitting ? null : () => _submitCreate(controller),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
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

  Future<void> _submitCreate(StoryHighlightsController controller) async {
    final title = _titleController.text.trim();
    if (title.isEmpty || _isSubmitting) return;
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
  }
}
