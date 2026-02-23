import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/formatters.dart';
import 'package:turqappv2/Modules/Agenda/PostLikeListing/PostLikeContent/post_like_content.dart';
import 'package:turqappv2/Utils/empty_padding.dart';

import 'post_like_listing_controller.dart';

class PostLikeListing extends StatelessWidget {
  final String postID;
  PostLikeListing({super.key, required this.postID});
  late final PostLikeListingController controller;

  @override
  Widget build(BuildContext context) {
    controller = Get.put(PostLikeListingController(postID: postID), tag: postID);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [

              Container(
                height: 3,
                width: 70,
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha(50),
                  borderRadius: BorderRadius.all(Radius.circular(12))
                ),
              ),

              SizedBox(height: 12,),

              header(),

              Expanded(
                child: Obx((){
                  return ListView.builder(
                    itemCount: controller.list.length,
                    itemBuilder: (context, index){
                      return PostLikeContent(userID: controller.list[index]);
                    },
                  );
                }),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget header () {
    return Obx((){
      return Row(
        children: [
          Expanded(
            child: Divider(color: Colors.grey.withAlpha(50),),
          ),

          12.pw,

          Text(
            "Beğenenler ${NumberFormatter.format(controller.list.length)}",
            style: TextStyle(
                color: Colors.black,
                fontSize: 15,
                fontFamily: "MontserratBold"
            ),
          ),

          12.pw,

          Expanded(
            child: Divider(color: Colors.grey.withAlpha(50),),
          )
        ],
      );
    });
  }
}
