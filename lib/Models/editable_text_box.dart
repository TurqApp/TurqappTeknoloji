import 'package:flutter/material.dart';
import 'package:get/get.dart';

class EditableTextBox {
  Rx<Offset> position;
  TextEditingController controller;
  RxBool isEditing;
  EditableTextBox(this.position, this.controller, this.isEditing);
}
