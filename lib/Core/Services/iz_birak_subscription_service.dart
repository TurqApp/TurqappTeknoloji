import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Services/current_user_service.dart';

part 'iz_birak_subscription_service_runtime_part.dart';

class IzBirakSubscriptionService extends GetxService {
  static IzBirakSubscriptionService? maybeFind() =>
      _maybeFindIzBirakSubscriptionService();

  static IzBirakSubscriptionService ensure() =>
      _ensureIzBirakSubscriptionService();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final RxSet<String> subscribedPostIds = <String>{}.obs;
  final Set<String> _loadingPostIds = <String>{};

  bool isSubscribed(String postId) => _isIzBirakSubscribed(this, postId);

  Future<bool> subscribe(String postId) =>
      _subscribeToIzBirakPost(this, postId);
}
