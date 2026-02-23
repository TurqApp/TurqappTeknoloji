import 'package:flutter/material.dart';
import 'package:get/get.dart';

class TextBoxModel {
  final TextEditingController controller = TextEditingController();
  final Rx<Offset> position = Offset(100, 100).obs;
  final RxBool isEditing = true.obs;

  // Ekle:
  final RxDouble scale = 1.0.obs;
  final RxDouble rotation = 0.0.obs;

  // Gesture başlangıç değerleri için geçici değişkenler:
  double startScale = 1.0;
  double startRotation = 0.0;
  Offset startFocalPoint = Offset.zero;
  Offset startPosition = Offset.zero;
}
