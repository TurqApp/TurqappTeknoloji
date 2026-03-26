import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Core/Repositories/user_repository.dart';
import 'package:turqappv2/Core/Utils/email_utils.dart';
import 'package:turqappv2/Core/Utils/phone_utils.dart';
import 'package:turqappv2/Services/account_center_service.dart';
import 'package:turqappv2/Services/current_user_service.dart';

part 'editor_phone_number_controller_actions_part.dart';
part 'editor_phone_number_controller_class_part.dart';
part 'editor_phone_number_controller_facade_part.dart';
part 'editor_phone_number_controller_fields_part.dart';
part 'editor_phone_number_controller_runtime_part.dart';
