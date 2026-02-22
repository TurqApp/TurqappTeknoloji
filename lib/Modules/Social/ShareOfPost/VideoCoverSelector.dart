import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Modules/Social/ShareOfPost/ThumbnailData.dart';

class VideoCoverSelector extends StatelessWidget {
  final int listCount;
  final List<ThumbnailData> list;
  final Function(ThumbnailData) onBackData;

  VideoCoverSelector(
      {super.key,
      required this.listCount,
      required this.list,
      required this.onBackData});
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Expanded(
                child: Divider(
                  color: Colors.grey.withAlpha(50),
                ),
              ),
              SizedBox(
                width: 12,
              ),
              Text(
                "Izgara Fotoğrafı Seç",
                style: TextStyle(
                    color: Colors.black,
                    fontSize: 18,
                    fontFamily: "MontserratBold"),
              ),
              SizedBox(
                width: 12,
              ),
              Expanded(
                child: Divider(
                  color: Colors.grey.withAlpha(50),
                ),
              )
            ],
          ),
        ),
        Expanded(
          child: GridView.builder(
            key: UniqueKey(),
            itemCount: listCount,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 1,
              crossAxisSpacing: 1,
            ),
            itemBuilder: (context, index) {
              final thumb = list[index];
              return GestureDetector(
                onTap: () {
                  onBackData(thumb);
                  Get.back();
                },
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.file(thumb.file, fit: BoxFit.cover),
                  ],
                ),
              );
            },
          ),
        )
      ],
    );
  }
}
