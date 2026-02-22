import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Models/Education/IndividualScholarshipsModel.dart';

class PersonalizedController extends GetxController {
  // Observable lists
  final RxList<IndividualScholarshipsModel> list = <IndividualScholarshipsModel>[].obs;
  final RxList<IndividualScholarshipsModel> vitrin = <IndividualScholarshipsModel>[].obs;

  // User data observables
  final RxString ikametSehir = "".obs;
  final RxString nufusSehir = "".obs;
  final RxString ikametIlce = "".obs;
  final RxString nufusIlce = "".obs;
  final RxString locationSehir = "".obs;
  final RxString universite = "".obs;
  final RxString ortaokul = "".obs;
  final RxString lise = "".obs;
  final RxString cinsiyet = "".obs;

  // UI state observables
  final RxBool showSearch = false.obs;
  final RxInt count = 0.obs;
  final RxInt currentIndex = 0.obs;
  final RxBool isLoading = false.obs;
  final RxBool isInitialLoading = true.obs;
  final RxBool isUserDataLoaded = false.obs;

  // Controllers and listeners
  final ScrollController scrollController = ScrollController();
  StreamSubscription<QuerySnapshot>? _burslarSubscription;

  @override
  void onInit() {
    super.onInit();
    _initializeData();
    _setupScrollListener();
  }

  @override
  void onClose() {
    _burslarSubscription?.cancel();
    scrollController.dispose();
    super.onClose();
  }

  // Initialize all data loading
  Future<void> _initializeData() async {
    try {
      // Load user data first
      await _loadUserData();

      // Load location data
      await getUserLocation();

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
          await FirebaseFirestore.instance
              .collection("users")
              .doc(uid)
              .get();

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
    FirebaseFirestore.instance
        .collection("BireyselBurslar")
        .orderBy("timeStamp", descending: true)
        .limit(10)
        .get()
        .then((QuerySnapshot snap) {
          if (snap.docs.isNotEmpty) {
            final tempList = snap.docs
                .map((doc) => IndividualScholarshipsModel.fromJson(doc.data() as Map<String, dynamic>))
                .toList();
            vitrin.value = tempList;
          }
        })
        .catchError((error) {
          print('Error loading vitrin data: $error');
        });
  }

  // Load scholarships data with stream
  Future<void> _loadScholarshipsData() async {
    if (!isUserDataLoaded.value) return;

    _burslarSubscription?.cancel();
    _burslarSubscription = FirebaseFirestore.instance
        .collection("BireyselBurslar")
        .orderBy("timeStamp", descending: true)
        .limit(50)
        .snapshots()
        .listen(
          (snapshot) {
            _processScholarshipsData(snapshot.docs);
          },
          onError: (error) {
            print('Error loading scholarships data: $error');
            isLoading.value = false;
          },
        );
  }

  // Process scholarships data
  void _processScholarshipsData(List<QueryDocumentSnapshot> docs) {
    try {
      final tempList = docs
          .map((doc) => IndividualScholarshipsModel.fromJson(doc.data() as Map<String, dynamic>))
          .where(_shouldIncludeScholarship)
          .toList();

      list.value = tempList;
      count.value = tempList.length;
      isLoading.value = false;
    } catch (e) {
      print('Error processing scholarships data: $e');
      isLoading.value = false;
    }
  }

  // Check if scholarship should be included based on user criteria
  bool _shouldIncludeScholarship(IndividualScholarshipsModel item) {
    // Basitleştirilmiş kişiselleştirme: şehir/ilçe/üniversite eşleşmesi veya ülke
    final matchSehir = item.sehirler.contains(ikametSehir.value) ||
        item.liseOrtaOkulSehirler.contains(ikametSehir.value);
    final matchIlce = item.ilceler.contains(ikametIlce.value) ||
        item.liseOrtaOkulIlceler.contains(ikametIlce.value);
    final matchUni = item.universiteler.contains(universite.value);
    final matchUlke = item.ulke.isNotEmpty ? item.ulke == 'Türkiye' : true;
    return matchSehir || matchIlce || matchUni || matchUlke;
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
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
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
}
