import 'package:flutter/material.dart';
import 'package:get/get.dart';

class EditableTextBox {
  Rx<Offset> position;
  TextEditingController controller;
  RxBool isEditing;
  EditableTextBox({
    required this.position,
    required this.controller,
    required this.isEditing,
  });
}
