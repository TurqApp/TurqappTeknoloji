import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Services/giphy_picker_service.dart';

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
              const Text(
                'Sticker Ekle',
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
                  _item('🔗 Bağlantı', () async {
                    final data = await _askLinkData();
                    if (data == null) return;
                    controller.addSticker(
                      stickerType: 'link',
                      label: '🔗 ${data.text}',
                      data: data.url,
                    );
                  }),
                  _item('🏷️ Konu etiketi', () async {
                    final v = await _askText('Konu etiketi', '#gundem');
                    if (v == null || v.trim().isEmpty) return;
                    controller.addSticker(
                      stickerType: 'hashtag',
                      label: v.startsWith('#') ? v.trim() : '#${v.trim()}',
                      data: v.replaceAll('#', '').trim(),
                    );
                  }),
                  _item('⏳ Geri sayım', () async {
                    final v = await _askText('Geri sayım başlığı', 'Lansman');
                    if (v == null || v.trim().isEmpty) return;
                    controller.addSticker(
                      stickerType: 'countdown',
                      label: '⏳ ${v.trim()}',
                      data: v.trim(),
                    );
                  }),
                  _item('🙋 Sen de ekle', () async {
                    final v = await _askText('Başlık', 'Sen de ekle');
                    if (v == null || v.trim().isEmpty) return;
                    controller.addSticker(
                      stickerType: 'add_yours',
                      label: '🙋 ${v.trim()}',
                      data: v.trim(),
                    );
                  }),
                  _item('❓ Soru', () async {
                    final v = await _askText('Soru', 'Bana bir soru sor');
                    if (v == null || v.trim().isEmpty) return;
                    controller.addSticker(
                      stickerType: 'question',
                      label: '❓ ${v.trim()}',
                      data: v.trim(),
                    );
                  }),
                  _item('@️⃣ Bahsetme', () async {
                    final v = await _askText('Kullanıcı', '@kullanici');
                    if (v == null || v.trim().isEmpty) return;
                    final clean = v.trim().replaceFirst('@', '');
                    controller.addSticker(
                      stickerType: 'mention',
                      label: '@$clean',
                      data: clean,
                    );
                  }),
                  _item('🎞️ GIF', () async {
                    final url = await GiphyPickerService.pickGifUrl(
                      context,
                      randomId: 'turqapp_story',
                    );
                    if (url != null && url.isNotEmpty) {
                      controller.addGifFromUrl(url);
                    }
                  }),
                  _item('📝 Metin', () async {
                    final v = await _askText('Metin', 'Metin');
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
          child: const Text('İptal'),
        ),
        TextButton(
          style: TextButton.styleFrom(
            foregroundColor: Colors.white,
          ),
          onPressed: () => Get.back(result: c.text.trim()),
          child: const Text('Ekle'),
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
      title: const Text(
        'Bağlantı Ekle',
        style: TextStyle(color: Colors.white),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: urlCtrl,
            autofocus: true,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              labelText: 'URL',
              labelStyle: TextStyle(color: Colors.white70),
              hintText: 'https://example.com',
              hintStyle: TextStyle(color: Colors.white54),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.white24),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.white),
              ),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: textCtrl,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              labelText: 'Bağlantı metni',
              labelStyle: TextStyle(color: Colors.white70),
              hintText: 'Haberi oku',
              hintStyle: TextStyle(color: Colors.white54),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.white24),
              ),
              focusedBorder: UnderlineInputBorder(
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
          child: const Text('İptal'),
        ),
        TextButton(
          style: TextButton.styleFrom(
            foregroundColor: Colors.white,
          ),
          onPressed: () {
            String url = urlCtrl.text.trim();
            if (url.isEmpty) return;
            if (!url.startsWith('http://') && !url.startsWith('https://')) {
              url = 'https://$url';
            }
            final uri = Uri.tryParse(url);
            if (uri == null || !uri.hasScheme || uri.host.isEmpty) return;

            final custom = textCtrl.text.trim();
            final display = custom.isEmpty ? _pretty(url) : custom;
            Get.back(result: _LinkData(url: url, text: display));
          },
          child: const Text('Bitti'),
        ),
      ],
    ),
  );
}
