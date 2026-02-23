import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ImagePreview extends StatelessWidget {
  final List<String> imgs;
  final int startIndex;

  const ImagePreview({super.key, required this.imgs, required this.startIndex});

  @override
  Widget build(BuildContext context) {
    final PageController pageController = PageController(initialPage: startIndex);
    double dragStartY = 0;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: GestureDetector(
          onVerticalDragStart: (details) {
            dragStartY = details.localPosition.dy;
          },
          onVerticalDragUpdate: (details) {
            double dragDistance = details.localPosition.dy - dragStartY;

            // Eğer yeterince aşağı çekildiyse çık
            if (dragDistance > 100) {
              Get.back();
            }
          },
          child: Stack(
            alignment: Alignment.topCenter,
            children: [
              Column(
                children: [
                  Expanded(
                    child: PageView.builder(
                      controller: pageController,
                      itemCount: imgs.length,
                      itemBuilder: (context, index) {
                        return CachedNetworkImage(
                          imageUrl: imgs[index],
                          fit: BoxFit.contain,
                        );
                      },
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  TextButton(
                    onPressed: () {
                      Get.back();
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.all(12),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Icon(
                      CupertinoIcons.arrow_left,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
