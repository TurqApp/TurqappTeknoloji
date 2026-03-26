import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:turqappv2/Core/Services/qa_lab_bridge.dart';
import 'package:turqappv2/Core/Utils/text_normalization_utils.dart';
import 'package:turqappv2/Core/app_snackbar.dart';

part 'error_handling_service_base_part.dart';
part 'error_handling_service_class_part.dart';
part 'error_handling_service_facade_part.dart';
part 'error_handling_service_fields_part.dart';
part 'error_handling_service_history_part.dart';
part 'error_handling_service_models_part.dart';
part 'error_handling_service_processing_part.dart';
