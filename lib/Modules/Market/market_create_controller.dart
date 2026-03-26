import 'dart:io';

import 'package:geocoding/geocoding.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Repositories/market_repository.dart';
import 'package:turqappv2/Core/Services/app_image_picker_service.dart';
import 'package:turqappv2/Core/Services/city_directory_service.dart';
import 'package:turqappv2/Core/Services/optimized_nsfw_service.dart';
import 'package:turqappv2/Core/Services/user_moderation_guard.dart';
import 'package:turqappv2/Core/Services/webp_upload_service.dart';
import 'package:turqappv2/Core/Utils/text_normalization_utils.dart';
import 'package:turqappv2/Core/Utils/turkish_sort.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Models/cities_model.dart';
import 'package:turqappv2/Models/market_item_model.dart';
import 'package:turqappv2/Modules/Market/market_category_utils.dart';
import 'package:turqappv2/Services/current_user_service.dart';

import 'market_schema_service.dart';

part 'market_create_controller_class_part.dart';
part 'market_create_controller_form_part.dart';
part 'market_create_controller_submission_part.dart';
part 'market_create_controller_fields_part.dart';
part 'market_create_controller_models_part.dart';
part 'market_create_controller_support_part.dart';
