import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/job_collection_helper.dart';
import 'package:turqappv2/Core/Repositories/job_repository.dart';
import 'package:turqappv2/Core/Services/silent_refresh_gate.dart';
import 'package:turqappv2/Services/current_user_service.dart';

import '../../../Models/job_model.dart';

part 'my_job_ads_controller_data_part.dart';
part 'my_job_ads_controller_base_part.dart';
part 'my_job_ads_controller_runtime_part.dart';
part 'my_job_ads_controller_class_part.dart';
part 'my_job_ads_controller_facade_part.dart';
