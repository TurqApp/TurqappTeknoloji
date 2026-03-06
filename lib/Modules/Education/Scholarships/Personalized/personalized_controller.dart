import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:turqappv2/Core/Services/scholarship_firestore_path.dart';
import 'package:turqappv2/Models/Education/individual_scholarships_model.dart';

class PersonalizedController extends GetxController {
  // Observable lists
  final RxList<IndividualScholarshipsModel> list =
      <IndividualScholarshipsModel>[].obs;
  final RxList<IndividualScholarshipsModel> vitrin =
      <IndividualScholarshipsModel>[].obs;

  // User data observables
  final RxString ikametSehir = "".obs;
  final RxString nufusSehir = "".obs;
  final RxString ikametIlce = "".obs;
  final RxString nufusIlce = "".obs;
  final RxString locationSehir = "".obs;
  final RxString schoolCity = "".obs;
  final RxString universite = "".obs;
  final RxString ortaokul = "".obs;
  final RxString lise = "".obs;
  final RxString cinsiyet = "".obs;
  final RxBool hasSchoolInfo = false.obs;
  final RxString educationLevel = "".obs;

  // docId lookup by timeStamp (since model doesn't carry docId)
  final Map<int, String> docIdByTimestamp = {};

  // UI state observables
  final RxBool showSearch = false.obs;
  final RxInt count = 0.obs;
  final RxInt currentIndex = 0.obs;
  final RxBool isLoading = false.obs;
  final RxBool isInitialLoading = true.obs;
  final RxBool isUserDataLoaded = false.obs;
  final RxBool usedFallback = false.obs;

  static const String _cacheKey = 'personalized_scholarships_cache_v1';
  static const int _cacheLimit = 30;

  // Controllers and listeners
  final ScrollController scrollController = ScrollController();

  @override
  void onInit() {
    super.onInit();
    _initializeData();
    _setupScrollListener();
  }

  @override
  void onClose() {
    scrollController.dispose();
    super.onClose();
  }

  // Initialize all data loading
  Future<void> _initializeData() async {
    try {
      await _loadCachedList();
      // Load user data first
      await _loadUserData();

      // Load location data only if no school info
      if (!hasSchoolInfo.value) {
        await getUserLocation();
      }

      // Load vitrin data (parallel)
      _loadVitrinData();

      // Load scholarships data
      await _loadScholarshipsData();
    } catch (e) {
      print('Error initializing data: $e');
    } finally {
      isInitialLoading.value = false;
    }
  }

  // Setup scroll listener for pagination
  void _setupScrollListener() {
    scrollController.addListener(() {
      if (scrollController.position.pixels >=
              scrollController.position.maxScrollExtent - 200 &&
          !isLoading.value) {
        _loadMoreData();
      }
    });
  }

  // Load more data for pagination
  void _loadMoreData() {
    if (!isLoading.value && isUserDataLoaded.value) {
      isLoading.value = true;
      // This will trigger the existing stream listener
      Future.delayed(const Duration(milliseconds: 500), () {
        isLoading.value = false;
      });
    }
  }

  // Load user data from Firestore
  Future<void> _loadUserData() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      final doc =
          await FirebaseFirestore.instance.collection("users").doc(uid).get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        _updateUserData(data);
        isUserDataLoaded.value = true;
      }
    } catch (e) {
      print('Error loading user data: $e');
    }
  }

  // Update user data observables
  void _updateUserData(Map<String, dynamic> data) {
    final educationLevel = (data['educationLevel'] ?? '').toString();
    final uni = (data['universite'] ?? '').toString();
    final hs = (data['lise'] ?? '').toString();
    final ms = (data['ortaOkul'] ?? '').toString();
    final il = (data['il'] ?? '').toString();

    hasSchoolInfo.value = educationLevel.isNotEmpty ||
        uni.isNotEmpty ||
        hs.isNotEmpty ||
        ms.isNotEmpty;
    schoolCity.value = hasSchoolInfo.value ? il : '';
    this.educationLevel.value = educationLevel;

    ikametSehir.value = data['ikametSehir'] ?? '';
    ikametIlce.value = data['ikametIlce'] ?? '';
    nufusSehir.value = data['nufusSehir'] ?? '';
    nufusIlce.value = data['nufusIlce'] ?? '';
    universite.value = data['universite'] ?? '';
    ortaokul.value = data['ortaOkul'] ?? '';
    lise.value = data['lise'] ?? '';
    cinsiyet.value = data['cinsiyet'] ?? '';
    locationSehir.value = data['locationSehir'] ?? '';
  }

  // Load vitrin data
  void _loadVitrinData() {
    ScholarshipFirestorePath.collection()
        .orderBy("timeStamp", descending: true)
        .limit(10)
        .get()
        .then((QuerySnapshot snap) {
      if (snap.docs.isNotEmpty) {
        final tempList = snap.docs
            .map((doc) => IndividualScholarshipsModel.fromJson(
                doc.data() as Map<String, dynamic>))
            .toList();
        vitrin.value = tempList;
      }
    }).catchError((error) {
      print('Error loading vitrin data: $error');
    });
  }

  // Load scholarships data (pull-based)
  Future<void> _loadScholarshipsData() async {
    if (!isUserDataLoaded.value) return;

    try {
      final snapshot = await ScholarshipFirestorePath.collection()
          .orderBy("timeStamp", descending: true)
          .limit(50)
          .get();
      _processScholarshipsData(snapshot.docs);
    } catch (error) {
      print('Error loading scholarships data: $error');
      isLoading.value = false;
    }
  }

  // Process scholarships data
  void _processScholarshipsData(List<QueryDocumentSnapshot> docs) {
    try {
      final allItems = <IndividualScholarshipsModel>[];
      for (final doc in docs) {
        final model = IndividualScholarshipsModel.fromJson(
            doc.data() as Map<String, dynamic>);
        allItems.add(model);
        docIdByTimestamp[model.timeStamp] = doc.id;
      }

      final scored = allItems
          .map((item) => MapEntry(item, _scoreScholarship(item)))
          .where((e) => e.value > 0)
          .toList();

      scored.sort((a, b) => b.value.compareTo(a.value));
      final filtered = scored.map((e) => e.key).toList();

      if (filtered.isEmpty && allItems.isNotEmpty) {
        list.value = allItems;
        usedFallback.value = true;
      } else {
        list.value = filtered;
        usedFallback.value = false;
      }

      _saveCachedList(allItems);
      count.value = list.length;
      isLoading.value = false;
    } catch (e) {
      print('Error processing scholarships data: $e');
      isLoading.value = false;
    }
  }

  // Score by priority: location (3), school (2), target audience (1)
  int _scoreScholarship(IndividualScholarshipsModel item) {
    int score = 0;
    final locationCity = locationSehir.value.isNotEmpty
        ? locationSehir.value
        : ikametSehir.value;
    final hasLocation = locationCity.trim().isNotEmpty;
    final hasSchoolCity = hasSchoolInfo.value && schoolCity.value.isNotEmpty;

    if (hasLocation && _matchesTargetCity(item, locationCity)) {
      score += 3;
    }
    if (hasSchoolCity && _matchesTargetCity(item, schoolCity.value)) {
      score += 2;
    }
    if (_matchesTargetAudience(item)) {
      score += 1;
    }

    return score;
  }

  String _normalizeCity(String input) {
    var s = input.toLowerCase().trim();
    s = s
        .replaceAll('ç', 'c')
        .replaceAll('ğ', 'g')
        .replaceAll('ı', 'i')
        .replaceAll('i̇', 'i')
        .replaceAll('ö', 'o')
        .replaceAll('ş', 's')
        .replaceAll('ü', 'u');
    s = s.replaceAll(' province', '');
    s = s.replaceAll(' ili', '');
    s = s.replaceAll(' il', '');
    s = s.replaceAll(' sehri', '');
    s = s.replaceAll(' şehir', '');
    s = s.replaceAll(RegExp(r'\s+'), ' ').trim();
    return s;
  }

  bool _matchesTargetCity(IndividualScholarshipsModel item, String city) {
    final normalizedTarget = _normalizeCity(city);

    bool cityMatch(List<String> list) {
      for (final raw in list) {
        final normalized = _normalizeCity(raw);
        if (normalized == normalizedTarget) return true;
        if (normalized.contains(normalizedTarget) ||
            normalizedTarget.contains(normalized)) {
          return true;
        }
      }
      return false;
    }

    return cityMatch(item.sehirler) || cityMatch(item.liseOrtaOkulSehirler);
  }

  bool _matchesTargetAudience(IndividualScholarshipsModel item) {
    final level = educationLevel.value.trim();
    if (level.isEmpty) return false;

    final normLevel = _normalizeCity(level);
    final hedef = _normalizeCity(item.hedefKitle);
    if (hedef.contains(normLevel) || normLevel.contains(hedef)) return true;

    final egitim = _normalizeCity(item.egitimKitlesi);
    if (egitim.contains(normLevel) || normLevel.contains(egitim)) return true;

    for (final alt in item.altEgitimKitlesi) {
      final n = _normalizeCity(alt);
      if (n.contains(normLevel) || normLevel.contains(n)) return true;
    }

    return false;
  }

  // Get user location
  Future<void> getUserLocation() async {
    try {
      final permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        print("Konum izni verilmedi.");
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final place = placemarks[0];
        await _updateLocationData(place);
      }
    } catch (e) {
      print("Konum bilgisi alınırken hata oluştu: $e");
    }
  }

  // Update location data
  Future<void> _updateLocationData(Placemark place) async {
    final newLocationSehir = place.administrativeArea ?? '';
    final newIkametSehir = place.administrativeArea ?? '';
    final newIkametIlce = place.subAdministrativeArea ?? '';

    // Update observables
    ikametSehir.value = newIkametSehir;
    ikametIlce.value = newIkametIlce;
    nufusSehir.value = newIkametSehir;
    nufusIlce.value = newIkametIlce;
    locationSehir.value = newLocationSehir;

    // Update in Firestore
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        await FirebaseFirestore.instance.collection("users").doc(uid).set({
          "locationSehir": newLocationSehir,
          "ikametSehir": newIkametSehir,
          "ikametIlce": newIkametIlce,
          "nufusSehir": newIkametSehir,
          "nufusIlce": newIkametIlce,
        }, SetOptions(merge: true));
      }
    } catch (e) {
      print('Error updating location in Firestore: $e');
    }
  }

  // Refresh list
  Future<void> refreshList() async {
    list.clear();
    vitrin.clear();
    isInitialLoading.value = true;

    await _initializeData();
    print("List refreshed!");
  }

  Future<void> _loadCachedList() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_cacheKey);
      if (raw == null || raw.isEmpty) return;
      final decoded = json.decode(raw) as List<dynamic>;
      final items = decoded
          .whereType<Map>()
          .map((e) => IndividualScholarshipsModel.fromJson(
              Map<String, dynamic>.from(e)))
          .toList();
      if (items.isNotEmpty) {
        list.value = items;
        count.value = items.length;
      }
    } catch (_) {
      // ignore cache errors
    }
  }

  Future<void> _saveCachedList(
      List<IndividualScholarshipsModel> allItems) async {
    try {
      if (allItems.isEmpty) return;
      final sorted = List<IndividualScholarshipsModel>.from(allItems)
        ..sort((a, b) => b.timeStamp.compareTo(a.timeStamp));
      final top = sorted.take(_cacheLimit).map((e) => e.toJson()).toList();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cacheKey, json.encode(top));
    } catch (_) {
      // ignore cache errors
    }
  }
}
