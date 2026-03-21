import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:turqappv2/Core/Buttons/turq_app_button.dart';

import 'location_finder_view_controller.dart';

class LocationFinderView extends StatefulWidget {
  final String submitButtonTitle;
  final Function(LatLng) backLatLong;
  final Function(String) backAdres;

  const LocationFinderView({
    super.key,
    required this.submitButtonTitle,
    required this.backAdres,
    required this.backLatLong,
  });

  @override
  State<LocationFinderView> createState() => _LocationFinderViewState();
}

class _LocationFinderViewState extends State<LocationFinderView> {
  late final String _controllerTag;
  late final LocationFinderViewController controller;
  bool _ownsController = false;

  @override
  void initState() {
    super.initState();
    _controllerTag = 'location_finder_${identityHashCode(this)}';
    _ownsController =
        LocationFinderViewController.maybeFind(tag: _controllerTag) == null;
    controller = LocationFinderViewController.ensure(tag: _controllerTag);
  }

  @override
  void dispose() {
    if (_ownsController &&
        identical(
          LocationFinderViewController.maybeFind(tag: _controllerTag),
          controller,
        )) {
      Get.delete<LocationFinderViewController>(tag: _controllerTag);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Obx(() {
        final pos = controller.currentPosition.value;
        if (pos == null) {
          return const Center(child: CircularProgressIndicator());
        }

        return Stack(
          children: [
            GoogleMap(
              initialCameraPosition: CameraPosition(
                target: pos,
                zoom: 15,
              ),
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              onMapCreated: controller.onMapCreated,
              onCameraMove: controller.onCameraMove,
              onCameraIdle: controller.onCameraIdle,
            ),

            // Map pin
            Center(
              child: AnimatedPadding(
                duration: Duration(milliseconds: 200),
                padding: EdgeInsets.only(
                  bottom: controller.isDragging.value ? 50 : 0,
                ),
                child: Icon(
                  Icons.location_on,
                  size: 50,
                  color: Colors.red,
                ),
              ),
            ),

            // Adres göstergesi
            Positioned(
              top: 60,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      blurRadius: 8,
                      color: Colors.black12,
                      offset: Offset(0, 2),
                    )
                  ],
                ),
                child: Obx(() => Text(
                      controller.currentAddress.value.isEmpty
                          ? 'location.address_fetching'.tr
                          : controller.currentAddress.value,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 15,
                          color: Colors.black,
                          fontFamily: "MontserratMedium"),
                    )),
              ),
            ),

            // Konuma git butonu
            Positioned(
                bottom: 100,
                right: 20,
                child: TextButton(
                  style: TextButton.styleFrom(padding: EdgeInsets.zero),
                  onPressed: () {
                    controller.moveToCurrentLocation();
                  },
                  child: Container(
                    width: 60,
                    height: 60,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                        color: Colors.blueAccent, shape: BoxShape.circle),
                    child: Icon(
                      CupertinoIcons.location_fill,
                      color: Colors.white,
                    ),
                  ),
                )),

            Positioned(
                bottom: 100,
                left: 20,
                child: TextButton(
                  style: TextButton.styleFrom(padding: EdgeInsets.zero),
                  onPressed: () {
                    Get.back();
                  },
                  child: Container(
                    width: 60,
                    height: 60,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.grey)),
                    child: Icon(
                      CupertinoIcons.arrow_left,
                      color: Colors.black,
                      size: 25,
                    ),
                  ),
                )),

            // Paylaş butonu
            Positioned(
              bottom: 30,
              left: 20,
              right: 20,
              child: TurqAppButton(
                onTap: () {
                  widget.backLatLong(LatLng(
                    controller.currentPosition.value!.latitude,
                    controller.currentPosition.value!.longitude,
                  ));
                  widget.backAdres(controller.currentAddress.value.toString());
                  Get.back();
                },
                text: widget.submitButtonTitle,
              ),
            )
          ],
        );
      }),
    );
  }
}
