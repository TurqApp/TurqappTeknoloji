import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Services/giphy_picker_service.dart';
import 'package:turqappv2/Core/Utils/nickname_utils.dart';
import 'package:turqappv2/Core/Utils/url_utils.dart';

import 'story_maker_controller.dart';

Future<void> showStoryStickerSheet(
    BuildContext context, StoryMakerController controller) async {
  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: const Color(0xFF171717),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
    ),
    builder: (ctx) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'story.add_sticker'.tr,
                style: TextStyle(
                  color: Colors.white,
                  fontFamily: 'MontserratMedium',
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _item('🔗 ${'story.sticker_link'.tr}', () async {
                    final data = await _askLinkData();
                    if (data == null) return;
                    controller.addSticker(
                      stickerType: 'link',
                      label: '🔗 ${data.text}',
                      data: data.url,
                    );
                  }),
                  _item('🏷️ ${'story.sticker_hashtag'.tr}', () async {
                    final v = await _askText(
                      'story.sticker_topic_label'.tr,
                      '#gundem',
                    );
                    if (v == null || v.trim().isEmpty) return;
                    controller.addSticker(
                      stickerType: 'hashtag',
                      label: v.startsWith('#') ? v.trim() : '#${v.trim()}',
                      data: v.replaceAll('#', '').trim(),
                    );
                  }),
                  _item('⏳ ${'story.sticker_countdown'.tr}', () async {
                    final v = await _askText(
                      'story.sticker_countdown_label'.tr,
                      'Lansman',
                    );
                    if (v == null || v.trim().isEmpty) return;
                    controller.addSticker(
                      stickerType: 'countdown',
                      label: '⏳ ${v.trim()}',
                      data: v.trim(),
                    );
                  }),
                  _item('🙋 ${'story.sticker_add_yours'.tr}', () async {
                    final v = await _askText(
                      'story.sticker_title_label'.tr,
                      'story.sticker_add_yours'.tr,
                    );
                    if (v == null || v.trim().isEmpty) return;
                    controller.addSticker(
                      stickerType: 'add_yours',
                      label: '🙋 ${v.trim()}',
                      data: v.trim(),
                    );
                  }),
                  _item('❓ ${'story.sticker_question'.tr}', () async {
                    final v = await _askText(
                      'story.sticker_question_label'.tr,
                      'Bana bir soru sor',
                    );
                    if (v == null || v.trim().isEmpty) return;
                    controller.addSticker(
                      stickerType: 'question',
                      label: '❓ ${v.trim()}',
                      data: v.trim(),
                    );
                  }),
                  _item('@️⃣ ${'story.sticker_mention'.tr}', () async {
                    final v = await _askText(
                      'story.sticker_user_label'.tr,
                      'story.placeholder_nickname'.tr,
                    );
                    if (v == null || v.trim().isEmpty) return;
                    final clean = normalizeHandleInput(v);
                    controller.addSticker(
                      stickerType: 'mention',
                      label: '@$clean',
                      data: clean,
                    );
                  }),
                  _item('🎞️ ${'story.sticker_gif'.tr}', () async {
                    final url = await GiphyPickerService.pickGifUrl(
                      context,
                      randomId: 'turqapp_story',
                    );
                    if (url != null && url.isNotEmpty) {
                      controller.addGifFromUrl(url);
                    }
                  }),
                  _item('📝 ${'story.sticker_text'.tr}', () async {
                    final v = await _askText(
                      'story.text_title'.tr,
                      'story.text_title'.tr,
                    );
                    if (v == null || v.trim().isEmpty) return;
                    controller.addStyledTextElement(v.trim());
                  }),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}

Widget _item(String title, VoidCallback onTap) {
  return InkWell(
    borderRadius: BorderRadius.circular(12),
    onTap: () {
      Get.back();
      onTap();
    },
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF262626),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontFamily: 'MontserratMedium',
          fontSize: 13,
        ),
      ),
    ),
  );
}

Future<String?> _askText(String title, String hint) async {
  final c = TextEditingController();
  return Get.dialog<String>(
    AlertDialog(
      backgroundColor: const Color(0xFF1F1F1F),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      content: TextField(
        controller: c,
        autofocus: true,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.white54),
          enabledBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.white24),
          ),
          focusedBorder: const UnderlineInputBorder(
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
          child: Text('common.cancel'.tr),
        ),
        TextButton(
          style: TextButton.styleFrom(
            foregroundColor: Colors.white,
          ),
          onPressed: () => Get.back(result: c.text.trim()),
          child: Text('common.add'.tr),
        ),
      ],
    ),
  );
}

String _pretty(String raw) {
  final v = raw.trim();
  if (v.length <= 36) return v;
  return '${v.substring(0, 33)}...';
}

class _LinkData {
  final String url;
  final String text;
  const _LinkData({required this.url, required this.text});
}

Future<_LinkData?> _askLinkData() async {
  final urlCtrl = TextEditingController(text: 'https://');
  final textCtrl = TextEditingController();
  return Get.dialog<_LinkData>(
    AlertDialog(
      backgroundColor: const Color(0xFF1F1F1F),
      title: Text(
        'story.link_add'.tr,
        style: TextStyle(color: Colors.white),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: urlCtrl,
            autofocus: true,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'common.url'.tr,
              labelStyle: const TextStyle(color: Colors.white70),
              hintText: 'common.url_example'.tr,
              hintStyle: const TextStyle(color: Colors.white54),
              enabledBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.white24),
              ),
              focusedBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.white),
              ),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: textCtrl,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'story.link_text_label'.tr,
              labelStyle: const TextStyle(color: Colors.white70),
              hintText: 'story.link_text_hint'.tr,
              hintStyle: const TextStyle(color: Colors.white54),
              enabledBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.white24),
              ),
              focusedBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          style: TextButton.styleFrom(
            foregroundColor: Colors.white70,
          ),
          onPressed: () => Get.back(),
          child: Text('common.cancel'.tr),
        ),
        TextButton(
          style: TextButton.styleFrom(
            foregroundColor: Colors.white,
          ),
          onPressed: () {
            String url = urlCtrl.text.trim();
            if (url.isEmpty) return;
            url = ensureUrlHasScheme(url);
            final uri = Uri.tryParse(url);
            if (uri == null || !uri.hasScheme || uri.host.isEmpty) return;

            final custom = textCtrl.text.trim();
            final display = custom.isEmpty ? _pretty(url) : custom;
            Get.back(result: _LinkData(url: url, text: display));
          },
          child: Text('common.done'.tr),
        ),
      ],
    ),
  );
}
