import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
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

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const SizedBox.shrink();

    final tag = 'highlights_$uid';
    final controller = Get.isRegistered<StoryHighlightsController>(tag: tag)
        ? Get.find<StoryHighlightsController>(tag: tag)
        : Get.put(StoryHighlightsController(userId: uid), tag: tag);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'One Cikarilanlar',
            style: TextStyle(
              fontSize: 18,
              fontFamily: 'MontserratMedium',
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          // Existing highlights
          Obx(() {
            if (controller.highlights.isEmpty && !_isCreatingNew) {
              return _buildNewHighlightForm(controller);
            }
            return Column(
              children: [
                ...controller.highlights.map((h) {
                  return ListTile(
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
                                child: const Icon(CupertinoIcons.collections,
                                    size: 18),
                              ),
                      ),
                    ),
                    title: Text(h.title,
                        style: const TextStyle(
                            fontFamily: 'MontserratMedium', fontSize: 14)),
                    subtitle: Text('${h.storyIds.length} hikaye',
                        style: const TextStyle(fontSize: 12)),
                    trailing: h.storyIds.contains(widget.storyId)
                        ? const Icon(CupertinoIcons.checkmark_circle_fill,
                            color: Colors.green)
                        : const Icon(CupertinoIcons.plus_circle,
                            color: Colors.grey),
                    onTap: () async {
                      if (!h.storyIds.contains(widget.storyId)) {
                        await controller.addStoryToHighlight(
                            h.id, widget.storyId);
                      }
                      Get.back();
                    },
                  );
                }),
                const Divider(),
                if (_isCreatingNew)
                  _buildNewHighlightForm(controller)
                else
                  ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.grey.withAlpha(80)),
                      ),
                      child: const Icon(CupertinoIcons.add, size: 20),
                    ),
                    title: const Text('Yeni One Cikarilan',
                        style: TextStyle(
                            fontFamily: 'MontserratMedium', fontSize: 14)),
                    onTap: () => setState(() => _isCreatingNew = true),
                  ),
              ],
            );
          }),
          SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
        ],
      ),
    );
  }

  Widget _buildNewHighlightForm(StoryHighlightsController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _titleController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Baslik girin...',
                hintStyle:
                    TextStyle(color: Colors.grey.withAlpha(150), fontSize: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              style:
                  const TextStyle(fontFamily: 'MontserratMedium', fontSize: 14),
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: () async {
              final title = _titleController.text.trim();
              if (title.isEmpty) return;
              await controller.createHighlight(
                title: title,
                storyIds: [widget.storyId],
              );
              Get.back();
            },
            child: const Text('Olustur',
                style: TextStyle(fontFamily: 'MontserratMedium')),
          ),
        ],
      ),
    );
  }
}
