import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:svg_flutter/svg.dart';
import 'package:turqappv2/Core/Formatters.dart';
import 'package:turqappv2/Models/Education/BookletModel.dart';
import 'package:turqappv2/Modules/Education/AnswerKey/AnswerKeyContent/AnswerKeyContentController.dart';

class AnswerKeyContent extends StatelessWidget {
  final BookletModel model;
  final Function(bool) onUpdate;

  const AnswerKeyContent({
    required this.model,
    required this.onUpdate,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(
      AnswerKeyContentController(model, onUpdate),
      tag: model.docID,
    );

    return Obx(
      () => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.all(Radius.circular(8)),
          border: Border.all(color: Colors.grey.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize:
              MainAxisSize.min, // Solution 1: Use minimum space needed
          children: [
            _buildHeader(context, controller),
            Flexible(
              // Solution 2: Make image flexible
              child: _buildImage(context, controller),
            ),
            _buildContent(context, controller),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    AnswerKeyContentController controller,
  ) {
    return Container(
      height: 40,
      padding: EdgeInsets.only(left: 10, right: 5),
      child: Row(
        children: [
          GestureDetector(
            child: ClipRRect(
              borderRadius: BorderRadius.all(Radius.circular(12)),
              child: SizedBox(
                width: 23,
                height: 23,
                child: controller.pfImage.value.isNotEmpty
                    ? Image.network(
                        controller.pfImage.value,
                        fit: BoxFit.cover,
                      )
                    : Center(child: CupertinoActivityIndicator()),
              ),
            ),
          ),
          SizedBox(width: 7),
          Expanded(
            child: GestureDetector(
              child: Text(
                controller.nickname.value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 12,
                  fontFamily: "MontserratBold",
                ),
              ),
            ),
          ),
          GestureDetector(
            onTap: () => controller.showBottomSheet(context),
            child: Icon(Icons.more_vert, color: Colors.grey, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildImage(
    BuildContext context,
    AnswerKeyContentController controller,
  ) {
    return GestureDetector(
      onTap: () => controller.navigateToPreview(context),
      child: AspectRatio(
        aspectRatio: 1 / 1.3,
        child: ClipRRect(
          borderRadius: BorderRadius.all(Radius.circular(8)),
          child: Image.network(controller.model.cover, fit: BoxFit.cover),
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    AnswerKeyContentController controller,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 7, horizontal: 7),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize:
            MainAxisSize.min, // Solution 3: Use minimum space in content column
        children: [
          SizedBox(
            height: 40,
            child: Text(
              controller.model.baslik,
              maxLines: 2,
              style: TextStyle(
                color: Colors.black,
                fontSize: 15,
                fontFamily: "MontserratBold",
              ),
            ),
          ),
          SizedBox(height: 3),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  controller.model.sinavTuru,
                  style: TextStyle(
                    color: Colors.indigo,
                    fontSize: 13,
                    fontFamily: "MontserratMedium",
                  ),
                ),
              ),
              Text(
                NumberFormatter.format(controller.model.goruntuleme.length * 3),
                style: TextStyle(color: Colors.black, fontSize: 13),
              ),
              SizedBox(width: 3),
              SvgPicture.asset(
                "assets/icons/statsyeni.svg",
                height: 20,
                color: Colors.black,
              ),
              SizedBox(width: 3),
              GestureDetector(
                onTap: controller.toggleBookmark,
                child: Icon(
                  controller.isBookmarked.value
                      ? CupertinoIcons.bookmark_fill
                      : CupertinoIcons.bookmark,
                  color: controller.isBookmarked.value
                      ? Colors.orange
                      : Colors.black,
                  size: 20,
                ),
              ),
            ],
          ),
          SizedBox(height: 3),
          Text(
            controller.model.yayinEvi,
            style: TextStyle(
              color: Colors.grey,
              fontSize: 13,
              fontFamily: "MontserratBold",
            ),
          ),
          SizedBox(height: 3),
          GestureDetector(
            onTap: () => controller.navigateToPreview(context),
            child: Container(
              height: 30,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.pink,
                borderRadius: BorderRadius.all(Radius.circular(8)),
              ),
              child: Text(
                "Hemen Başla",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontFamily: "MontserratBold",
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
