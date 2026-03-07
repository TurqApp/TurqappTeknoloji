import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Models/posts_model.dart';
import 'package:turqappv2/Modules/Social/PhotoShorts/photo_short_content.dart';
import 'package:turqappv2/Modules/Social/PhotoShorts/photo_shorts_controller.dart';

class PhotoShorts extends StatefulWidget {
  final List<PostsModel> fetchedList;
  final PostsModel startModel;
  const PhotoShorts(
      {super.key, required this.fetchedList, required this.startModel});

  @override
  State<PhotoShorts> createState() => _PhotoShortsState();
}

class _PhotoShortsState extends State<PhotoShorts> {
  late final PhotoShortsController controller;
  late final PageController pageController;

  @override
  void initState() {
    super.initState();
    controller = Get.put(PhotoShortsController());

    // fetchedList'i kopyala ve gerekirse startModel'i başa ekle
    final List<PostsModel> initialList =
        List<PostsModel>.from(widget.fetchedList);
    if (!initialList.any((e) => e.docID == widget.startModel.docID)) {
      initialList.insert(0, widget.startModel);
    }

    // Başlangıç index'ini bul (her durumda >= 0 dönecek)
    final int initialIndex =
        initialList.indexWhere((e) => e.docID == widget.startModel.docID);

    pageController = PageController(initialPage: initialIndex);

    // Build aşamasında Obx tetiklenmesini önlemek için post-frame'de listeyi ata
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.addToList(initialList);
    });
  }

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Obx(() {
        return controller.list.isNotEmpty
            ? PageView.builder(
                controller: pageController,
                scrollDirection: Axis.vertical,
                itemCount: controller.list.length,
                itemBuilder: (context, index) {
                  return PhotoShortContent(model: controller.list[index]);
                },
              )
            : const Center(
                child: CupertinoActivityIndicator(color: Colors.white),
              );
      }),
    );
  }
}
