import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Models/job_model.dart';
import 'package:turqappv2/Modules/JobFinder/JobContent/job_content_controller.dart';
import 'package:turqappv2/Modules/JobFinder/JobDetails/job_details.dart';

import '../job_finder_controller.dart';

class JobContent extends StatelessWidget {
  final bool isGrid;
  final JobModel model;
  JobContent({super.key, required this.model, required this.isGrid});
  late final JobContentController controller;
  @override
  Widget build(BuildContext context) {
    controller = Get.put(JobContentController(), tag: model.docID);
    controller.checkSaved(model.docID);
    return isGrid ? gridView() : listingView();
  }

  Widget listingView() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 15, right: 15, bottom: 6, top: 6),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.all(Radius.circular(8)),
                child: SizedBox(width: 65, height: 65, child: CachedNetworkImage(imageUrl: model.logo, fit: BoxFit.cover,)),
              ),
              SizedBox(width: 12,),
              Expanded(
                child: GestureDetector(
                  onTap: () async {
                    await Get.to(() => JobDetails(model: model));
                    final finderController = Get.find<JobFinderController>();
                    await finderController.refreshJob(model.docID);
                  },
                  child: Container(
                    color: Colors.transparent,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                model.meslek,
                                style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 15,
                                    fontFamily: "MontserratBold"
                                ),
                              ),
                            ),

                            Text(
                              model.calismaTuru.length <= 1
                                  ? model.calismaTuru.join(", ")
                                  : "${model.calismaTuru.take(1).join(", ")} +${model.calismaTuru.length - 1}",
                              maxLines: 1,
                              style: TextStyle(
                                color: Colors.pinkAccent,
                                fontSize: 14,
                                fontFamily: "MontserratMedium",
                              ),
                            ),
                          ],
                        ),

                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    model.brand,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                        color: Colors.blueAccent,
                                        fontSize: 15,
                                        fontFamily: "MontserratMedium"
                                    ),
                                  ),

                                  Text(
                                    "${model.kacKm == 0 ? "" : "${model.kacKm.toStringAsFixed(2)} km • "}${model.city}, ${model.town}",
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 13,
                                      fontFamily: "Montserrat",
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            Obx((){
                              return Transform.translate(
                                offset: Offset(10, 0),
                                child: IconButton(
                                  onPressed: (){
                                    controller.toggleSave(model.docID);
                                  },
                                  icon: Icon(
                                    controller.saved.value ? CupertinoIcons.bookmark_fill : CupertinoIcons.bookmark,
                                    color: controller.saved.value ? Colors.orange : Colors.grey,
                                    size: 22,
                                  ),
                                  padding: EdgeInsets.zero, // padding'i sıfırla
                                  constraints: BoxConstraints(
                                    minWidth: 0,
                                    minHeight: 0,
                                  ), // minimum boyut sınırını kaldır
                                  visualDensity: VisualDensity.compact, // daha sıkı yerleşim
                                  style: ButtonStyle(
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    fixedSize: WidgetStateProperty.all(Size(35, 35)), // ikon boyutuna sabitle
                                    alignment: Alignment.center,
                                  ),
                                ),
                              );
                            })
                          ],
                        )
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 15, left: 90),
          child: SizedBox(height: 1, child: Divider(color: Colors.grey.withAlpha(20),),),
        )
      ],
    );
  }

  Widget gridView() {
    return GestureDetector(
      onTap: () => Get.to(JobDetails(model: model)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          border: Border.all(color: Colors.grey.withAlpha(50))
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: ClipRRect(
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(8),
                  topLeft: Radius.circular(8)
                ),
                child: CachedNetworkImage(imageUrl: model.logo, fit: BoxFit.cover,),
              ),
            ),

           Padding(
             padding: const EdgeInsets.all(8.0),
             child: Column(
               crossAxisAlignment: CrossAxisAlignment.start,
               children: [
                 Text(
                   model.meslek,
                   maxLines: 1,
                   style: TextStyle(
                       color: Colors.black,
                       fontSize: 13,
                       fontFamily: "MontserratBold"
                   ),
                 ),

                 Text(
                   model.calismaTuru.length <= 1
                       ? model.calismaTuru.join(", ")
                       : "${model.calismaTuru.take(1).join(", ")} +${model.calismaTuru.length - 1}",
                   maxLines: 1,
                   style: TextStyle(
                     color: Colors.pinkAccent,
                     fontSize: 14,
                     fontFamily: "MontserratMedium",
                   ),
                 ),


                 Text(
                   model.brand,
                   maxLines: 1,
                   overflow: TextOverflow.ellipsis,
                   style: TextStyle(
                       color: Colors.blueAccent,
                       fontSize: 13,
                       fontFamily: "MontserratMedium"
                   ),
                 ),

                 Text(
                   "${model.kacKm.toStringAsFixed(2)} km\n${model.city}, ${model.town}",
                   maxLines: 2,
                   overflow: TextOverflow.ellipsis,
                   style: TextStyle(
                     color: Colors.black,
                     fontSize: 13,
                     fontFamily: "MontserratMedium",
                   ),
                 ),
               ],
             ),
           )
          ],
        ),
      ),
    );
  }
}
