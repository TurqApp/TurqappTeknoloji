import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

/*
 Stale-While-Revalidate (SWR) GetX Controller Base

 Kullanım adımları:
 1. loadFromCache — önce disk/LRU cache'ten hızlı göster
 2. fetchFromNetwork — arka planda taze veriyi çek
 3. mergeItems — taze veriyi mevcut listeyle birleştir
*/

part 'swr_controller_base_part.dart';
part 'swr_controller_class_part.dart';
part 'swr_controller_facade_part.dart';
part 'swr_controller_fields_part.dart';
part 'swr_controller_runtime_part.dart';
