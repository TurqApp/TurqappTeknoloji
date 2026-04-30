import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Repositories/job_repository.dart';
import 'package:turqappv2/Core/Services/job_saved_store.dart';
import 'package:turqappv2/Core/Services/silent_refresh_gate.dart';
import 'package:turqappv2/Models/job_model.dart';
import 'package:turqappv2/Services/current_user_service.dart';

part 'saved_job_controller_constants_part.dart';
part 'saved_job_controller_data_part.dart';
part 'saved_job_controller_facade_part.dart';
part 'saved_job_controller_runtime_part.dart';
