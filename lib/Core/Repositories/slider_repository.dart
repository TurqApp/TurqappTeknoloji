import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

part 'slider_repository_class_part.dart';
part 'slider_repository_facade_part.dart';

class SliderRemoteData {
  const SliderRemoteData({
    required this.meta,
    required this.items,
  });

  final DocumentSnapshot<Map<String, dynamic>> meta;
  final QuerySnapshot<Map<String, dynamic>> items;
}
