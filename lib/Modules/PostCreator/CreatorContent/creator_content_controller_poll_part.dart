part of 'creator_content_controller.dart';

extension CreatorContentControllerPollPart on CreatorContentController {
  Future<void> _performOpenPollComposer() async {
    final existing = pollData.value;
    final questionCtrl = TextEditingController(
      text: existing?['question']?.toString() ?? '',
    );
    final optionCtrls = <TextEditingController>[];
    if (existing != null && existing['options'] is List) {
      final opts = existing['options'] as List;
      for (final o in opts) {
        optionCtrls.add(
          TextEditingController(text: (o['text'] ?? '').toString()),
        );
      }
    }
    while (optionCtrls.length < 2) {
      optionCtrls.add(TextEditingController());
    }
    if (optionCtrls.length > 5) {
      optionCtrls.removeRange(5, optionCtrls.length);
    }

    InputDecoration fieldDecoration(String hint, {String? prefixText}) =>
        InputDecoration(
          hintText: hint,
          prefixText: prefixText,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 10,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey.shade400),
          ),
          counterText: '',
        );

    int selectedDurationHours =
        (existing?['durationHours'] is num) ? existing!['durationHours'] : 24;
    String durationLabel(int hours) {
      switch (hours) {
        case 6:
          return 'post_creator.poll_option_6h'.tr;
        case 12:
          return 'post_creator.poll_option_12h'.tr;
        case 24:
          return 'post_creator.poll_option_1d'.tr;
        case 72:
          return 'post_creator.poll_option_3d'.tr;
        case 168:
          return 'post_creator.poll_option_7d'.tr;
        default:
          return 'post_creator.poll_option_1d'.tr;
      }
    }

    await Get.bottomSheet(
      StatefulBuilder(
        builder: (context, setState) {
          return Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                Row(
                  children: [
                    Text(
                      'post_creator.poll_title'.tr,
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontFamily: "MontserratBold",
                      ),
                    ),
                    const Spacer(),
                    Text(
                      durationLabel(selectedDurationHours),
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 12,
                        fontFamily: "MontserratMedium",
                      ),
                    ),
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: () async {
                        final picked = await Get.bottomSheet<int>(
                          Container(
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(12),
                                topRight: Radius.circular(12),
                              ),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const SizedBox(height: 8),
                                Text(
                                  'post_creator.poll_time_options'.tr,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontFamily: "MontserratBold",
                                  ),
                                ),
                                const SizedBox(height: 8),
                                ListTile(
                                  title: Text('post_creator.poll_option_6h'.tr),
                                  onTap: () => Get.back(result: 6),
                                ),
                                ListTile(
                                  title:
                                      Text('post_creator.poll_option_12h'.tr),
                                  onTap: () => Get.back(result: 12),
                                ),
                                ListTile(
                                  title: Text('post_creator.poll_option_1d'.tr),
                                  onTap: () => Get.back(result: 24),
                                ),
                                ListTile(
                                  title: Text('post_creator.poll_option_3d'.tr),
                                  onTap: () => Get.back(result: 72),
                                ),
                                ListTile(
                                  title: Text('post_creator.poll_option_7d'.tr),
                                  onTap: () => Get.back(result: 168),
                                ),
                                const SizedBox(height: 8),
                              ],
                            ),
                          ),
                        );
                        if (picked != null) {
                          setState(() {
                            selectedDurationHours = picked;
                          });
                        }
                      },
                      child: const Icon(
                        CupertinoIcons.clock,
                        size: 18,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                for (int i = 0; i < optionCtrls.length; i++) ...[
                  TextField(
                    controller: optionCtrls[i],
                    maxLines: 1,
                    maxLength: 25,
                    inputFormatters: [LengthLimitingTextInputFormatter(25)],
                    decoration: fieldDecoration(
                      'post_creator.poll_option'.trParams({
                        'index': '${i + 1}',
                      }),
                      prefixText: '${String.fromCharCode(65 + i)}) ',
                    ),
                  ),
                  const SizedBox(height: 6),
                ],
                TextButton(
                  onPressed: optionCtrls.length >= 5
                      ? null
                      : () {
                          setState(() {
                            optionCtrls.add(TextEditingController());
                          });
                        },
                  child: Text('post_creator.poll_add_option'.tr),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    TextButton(
                      onPressed: () {
                        pollData.value = null;
                        Get.back();
                      },
                      child: Text('common.remove'.tr),
                    ),
                    const Spacer(),
                    ElevatedButton(
                      onPressed: () {
                        final options = optionCtrls
                            .map((c) => c.text.trim())
                            .where((t) => t.isNotEmpty)
                            .toList();
                        if (options.length < 2) {
                          AppSnackbar(
                            'common.error'.tr,
                            'post_creator.poll_min_options'.tr,
                          );
                          return;
                        }
                        pollData.value = {
                          'question': questionCtrl.text.trim(),
                          'durationHours': selectedDurationHours,
                          'options': options
                              .map((t) => {'text': t, 'votes': 0})
                              .toList(),
                        };
                        Get.back();
                      },
                      child: Text('common.create'.tr),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
      isScrollControlled: true,
    );
  }
}
