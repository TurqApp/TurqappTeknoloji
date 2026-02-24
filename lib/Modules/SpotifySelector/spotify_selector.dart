import 'package:flutter/material.dart';
import 'package:turqappv2/Core/Buttons/back_buttons.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/functions.dart';
import 'package:turqappv2/Core/page_line_bar.dart';
import 'package:turqappv2/Modules/SpotifySelector/spotify_selector_controller.dart';

class SpotifySelector extends StatelessWidget {
  final Function(String) url;

  SpotifySelector({super.key, required this.url});
  final controller = Get.put(SpotifySelectorController());
  final page = Get.put(
    PageLineBarController(pageName: 'Spotify'),
    tag: "Spotify",
  );
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            BackButtons(text: "Müzik Seç"),
            PageLineBar(
              barList: ["Favoriler", "Kaydedilenler"],
              pageName: "TurqApp",
              pageController: controller.pageController,
            ),
            Expanded(
              child: PageView(
                controller: controller.pageController,
                onPageChanged: (v) {
                  page.selection.value = v;
                },
                children: [
                  Obx(() {
                    return ListView.builder(
                      itemCount: controller.list.length,
                      itemBuilder: (context, index) {
                        final model = controller.list[index];

                        return Padding(
                          padding: EdgeInsets.only(top: index == 0 ? 12 : 0),
                          child: Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 5,
                                  horizontal: 15,
                                ),
                                child: Row(
                                  children: [
                                    // 🔊 Müzik adına tıklanınca da çalsın
                                    Expanded(
                                      child: TextButton(
                                        onPressed: () =>
                                            Get.back(result: model.url),
                                        style: TextButton.styleFrom(
                                          padding: EdgeInsets.zero,
                                          alignment: Alignment.centerLeft,
                                          tapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                        ),
                                        child: Row(
                                          children: [
                                            SizedBox(
                                              width: 30,
                                              height: 30,
                                              child: Image.asset(
                                                "assets/icons/spotify_s.webp",
                                              ),
                                            ),
                                            SizedBox(width: 12),
                                            Expanded(
                                              child: Text(
                                                getMusicNameFromURL(model.url),
                                                overflow: TextOverflow.ellipsis,
                                                maxLines: 1,
                                                style: const TextStyle(
                                                  color: Colors.black,
                                                  fontSize: 15,
                                                  fontFamily:
                                                      "MontserratMedium",
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),

                                    SizedBox(width: 12),

                                    // ▶️ İkonla kontrol

                                    Obx(() {
                                      final isPlaying =
                                          controller.currentPlayingUrl.value ==
                                              model.url;
                                      return IconButton(
                                        icon: Icon(
                                          isPlaying
                                              ? Icons.pause_circle
                                              : Icons.play_circle,
                                          color: isPlaying
                                              ? Colors.blueAccent
                                              : Colors.black,
                                          size: 35,
                                        ),
                                        onPressed: () =>
                                            controller.playMusic(model.url),
                                        splashRadius: 22,
                                        padding: EdgeInsets.zero,
                                        constraints:
                                            const BoxConstraints(), // Sadece ikon kadar alan
                                      );
                                    })
                                  ],
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 15,
                                ),
                                child: SizedBox(
                                  height: 2,
                                  child: Divider(
                                    color: Colors.grey.withAlpha(50),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  }),
                  Obx(() {
                    return ListView.builder(
                      itemCount: controller.list.length,
                      itemBuilder: (context, index) {
                        final model = controller.list[index];
                        return Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 5,
                                horizontal: 15,
                              ),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 30,
                                    height: 30,
                                    child: Image.asset(
                                      "assets/icons/spotify_s.webp",
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          getMusicNameFromURL(model.url),
                                          style: TextStyle(
                                            color: Colors.black,
                                            fontSize: 15,
                                            fontFamily: "MontserratMedium",
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 15,
                              ),
                              child: SizedBox(
                                height: 2,
                                child: Divider(
                                  color: Colors.grey.withAlpha(50),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
