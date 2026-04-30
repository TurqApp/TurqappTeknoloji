import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Buttons/back_buttons.dart';
import 'package:turqappv2/Core/Services/app_firebase_storage.dart';
import 'package:turqappv2/Core/Services/app_firestore.dart';
import 'package:turqappv2/Core/Services/app_image_picker_service.dart';
import 'package:turqappv2/Core/Services/webp_upload_service.dart';
import 'package:turqappv2/Core/Slider/slider_catalog.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Utils/empty_padding.dart';

part 'slider_admin_view_actions_part.dart';
part 'slider_admin_view_content_part.dart';

class SliderAdminView extends StatefulWidget {
  const SliderAdminView({
    super.key,
    required this.sliderId,
    required this.title,
  });

  final String sliderId;
  final String title;

  @override
  State<SliderAdminView> createState() => _SliderAdminViewState();
}

class _SliderAdminViewState extends State<SliderAdminView> {
  bool _isBusy = false;

  DocumentReference<Map<String, dynamic>> get _sliderMeta =>
      AppFirestore.instance.collection('sliders').doc(widget.sliderId);

  CollectionReference<Map<String, dynamic>> get _sliderItems =>
      _sliderMeta.collection('items');

  List<String> get _defaults => SliderCatalog.defaultImagesFor(widget.sliderId);

  Future<void> _ensureSliderMeta() {
    return _sliderMeta.set({
      'title': widget.title,
      'updatedDate': DateTime.now().millisecondsSinceEpoch,
    }, SetOptions(merge: true));
  }

  void _updateViewState(VoidCallback fn) {
    if (mounted) {
      setState(fn);
    }
  }

  @override
  Widget build(BuildContext context) => _buildPage(context);
}
