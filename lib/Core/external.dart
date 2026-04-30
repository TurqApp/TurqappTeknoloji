import 'dart:io';
import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:turqappv2/Core/Services/app_firestore.dart';
import 'package:turqappv2/Models/report_model.dart';
import 'package:turqappv2/Services/current_user_service.dart';
import 'package:turqappv2/Core/Utils/text_normalization_utils.dart';
import 'dart:ui' as ui;

part 'external_text_utils_part.dart';
part 'external_exam_data_part.dart';
part 'external_profession_data_part.dart';
part 'external_shared_data_part.dart';
