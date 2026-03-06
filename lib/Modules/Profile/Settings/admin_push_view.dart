import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/BottomSheets/list_bottom_sheet.dart';
import 'package:turqappv2/Core/Services/admin_access_service.dart';
import 'package:turqappv2/Core/job_categories.dart';

class AdminPushView extends StatefulWidget {
  const AdminPushView({super.key});

  @override
  State<AdminPushView> createState() => _AdminPushViewState();
}

class _AdminPushViewState extends State<AdminPushView> {
  static const int _pushTargetCutoffMs = 1772409600000;
  final _uidController = TextEditingController();
  final _konumController = TextEditingController();
  final _genderController = TextEditingController();
  final _minAgeController = TextEditingController();
  final _maxAgeController = TextEditingController();
  final _titleController = TextEditingController(text: "TurqApp");
  final _bodyController = TextEditingController();
  final List<String> _pushTypes = const [
    "posts",
    "follow",
    "comment",
    "message",
    "like",
    "reshared_posts",
    "shared_as_posts",
  ];
  String _selectedType = "posts";
  String _selectedMeslek = "";
  bool _sending = false;
  bool _checkingAccess = true;
  bool _canManagePush = false;
  String _lastReport = "";

  CollectionReference<Map<String, dynamic>> _reportsRef() {
    return FirebaseFirestore.instance
        .collection("adminConfig")
        .doc("admin")
        .collection("pushReports");
  }

  @override
  void initState() {
    super.initState();
    _checkAdminAccess();
  }

  Future<void> _checkAdminAccess() async {
    final allowed = await AdminAccessService.canManageSliders();
    if (!mounted) return;
    setState(() {
      _canManagePush = allowed;
      _checkingAccess = false;
    });
  }

  @override
  void dispose() {
    _uidController.dispose();
    _konumController.dispose();
    _genderController.dispose();
    _minAgeController.dispose();
    _maxAgeController.dispose();
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _showMeslekSelector() async {
    await Get.bottomSheet(
      ListBottomSheet(
        list: allJobs,
        title: "Meslek Seç",
        startSelection: _selectedMeslek,
        onBackData: (v) {
          if (v is String) {
            setState(() {
              _selectedMeslek = v;
            });
          }
        },
      ),
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
      ),
    );
  }

  List<String> _collectLocationValues(Map<String, dynamic> data) {
    final values = <String>[];
    for (final key in const [
      "city",
      "il",
      "ilce",
      "locationSehir",
      "ikametSehir"
    ]) {
      final value = (data[key] ?? "").toString().trim().toLowerCase();
      if (value.isNotEmpty) values.add(value);
    }
    return values;
  }

  int? _extractAge(Map<String, dynamic> data) {
    final raw = (data["dogumTarihi"] ?? "").toString().trim();
    if (raw.isEmpty) return null;

    DateTime? birthDate;
    final asInt = int.tryParse(raw);
    if (asInt != null) {
      final ms = raw.length >= 13 ? asInt : asInt * 1000;
      birthDate = DateTime.fromMillisecondsSinceEpoch(ms);
    } else {
      birthDate = DateTime.tryParse(raw);
      if (birthDate == null && raw.contains("/")) {
        final parts = raw.split("/");
        if (parts.length == 3) {
          final d = int.tryParse(parts[0]);
          final m = int.tryParse(parts[1]);
          final y = int.tryParse(parts[2]);
          if (d != null && m != null && y != null) {
            birthDate = DateTime(y, m, d);
          }
        }
      }
    }
    if (birthDate == null) return null;

    final now = DateTime.now();
    var age = now.year - birthDate.year;
    final hadBirthday = (now.month > birthDate.month) ||
        (now.month == birthDate.month && now.day >= birthDate.day);
    if (!hadBirthday) age--;
    return age < 0 ? null : age;
  }

  bool _isEligiblePushTarget(String userId, Map<String, dynamic> data) {
    final rawCreatedDate = data['createdDate'];
    final createdAtMs = rawCreatedDate is num
        ? rawCreatedDate.toInt()
        : int.tryParse(rawCreatedDate?.toString() ?? '') ?? 0;
    return createdAtMs >= _pushTargetCutoffMs;
  }

  Future<List<String>> _resolveTargetUids({
    required String uid,
    required String meslek,
    required String konum,
    required String gender,
    required int? minAge,
    required int? maxAge,
  }) async {
    if (uid.isNotEmpty) {
      final userDoc =
          await FirebaseFirestore.instance.collection("users").doc(uid).get();
      if (!userDoc.exists) return <String>[];
      final data = userDoc.data() ?? const <String, dynamic>{};
      return _isEligiblePushTarget(uid, data) ? [uid] : <String>[];
    }

    final meslekLc = meslek.toLowerCase();
    final konumLc = konum.toLowerCase();
    final genderLc = gender.toLowerCase();
    final targets = <String>[];
    final seen = <String>{};

    bool matchesFilters(String userId, Map<String, dynamic> data) {
      if (seen.contains(userId)) return false;
      if (!_isEligiblePushTarget(userId, data)) return false;
      final userMeslek =
          (data["meslekKategori"] ?? "").toString().trim().toLowerCase();
      final userGender =
          (data["cinsiyet"] ?? "").toString().trim().toLowerCase();
      final locations = _collectLocationValues(data);
      final age = _extractAge(data);
      final meslekOk = meslekLc.isEmpty || userMeslek == meslekLc;
      final konumOk = konumLc.isEmpty || locations.any((v) => v == konumLc);
      final genderOk = genderLc.isEmpty || userGender == genderLc;
      final minAgeOk = minAge == null || (age != null && age >= minAge);
      final maxAgeOk = maxAge == null || (age != null && age <= maxAge);
      final ok = meslekOk && konumOk && genderOk && minAgeOk && maxAgeOk;
      if (ok) seen.add(userId);
      return ok;
    }

    const pageSize = 350;
    Query<Map<String, dynamic>> query = FirebaseFirestore.instance
        .collection("users")
        .where("createdDate", isGreaterThanOrEqualTo: _pushTargetCutoffMs)
        .orderBy("createdDate")
        .limit(pageSize);

    while (true) {
      final users = await query.get();
      if (users.docs.isEmpty) break;

      for (final doc in users.docs) {
        final data = doc.data();
        if (matchesFilters(doc.id, data)) {
          targets.add(doc.id);
        }
      }

      if (users.docs.length < pageSize) break;
      query = FirebaseFirestore.instance
          .collection("users")
          .where("createdDate", isGreaterThanOrEqualTo: _pushTargetCutoffMs)
          .orderBy("createdDate")
          .startAfterDocument(users.docs.last)
          .limit(pageSize);
    }

    return targets;
  }

  Future<void> _sendPush() async {
    if (!_canManagePush) {
      Get.snackbar(
        "Yetki Yok",
        "Push gondermek icin admin hesabi gerekli.",
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    FocusManager.instance.primaryFocus?.unfocus();
    final uid = _uidController.text.trim();
    final meslek = _selectedMeslek.trim();
    final konum = _konumController.text.trim();
    final gender = _genderController.text.trim();
    final minAge = int.tryParse(_minAgeController.text.trim());
    final maxAge = int.tryParse(_maxAgeController.text.trim());
    final title = _titleController.text.trim();
    final body = _bodyController.text.trim();
    final type = _selectedType;

    if (title.isEmpty || body.isEmpty) {
      Get.snackbar(
        "Eksik Bilgi",
        "Başlık ve mesaj zorunlu.",
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    if (minAge != null && maxAge != null && minAge > maxAge) {
      Get.snackbar(
        "Yaş Aralığı Hatalı",
        "Min yaş, max yaştan büyük olamaz.",
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    setState(() {
      _sending = true;
    });

    try {
      final targetUids = await _resolveTargetUids(
        uid: uid,
        meslek: meslek,
        konum: konum,
        gender: gender,
        minAge: minAge,
        maxAge: maxAge,
      );
      if (targetUids.isEmpty) {
        Get.snackbar(
          "Sonuç Yok",
          "Bu filtreye uyan kullanıcı bulunamadı.",
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }

      final senderUid = FirebaseAuth.instance.currentUser?.uid ?? "admin";
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      const batchSize = 400;

      for (var i = 0; i < targetUids.length; i += batchSize) {
        final batch = FirebaseFirestore.instance.batch();
        final chunk = targetUids.skip(i).take(batchSize);
        for (final targetUid in chunk) {
          final docRef = FirebaseFirestore.instance
              .collection("users")
              .doc(targetUid)
              .collection("notifications")
              .doc();
          batch.set(docRef, {
            "type": type,
            "title": title,
            "body": body,
            "fromUserID": senderUid,
            "postID": "admin-manual-push",
            "adminPush": true,
            "hideInAppInbox": true,
            "timeStamp": nowMs,
            "read": false,
          });
        }
        await batch.commit();
      }

      if (!mounted) return;
      setState(() {
        final now = DateTime.now();
        _lastReport =
            "Saat ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}\n"
            "Hedef: ${targetUids.length} kullanıcı\n"
            "Tür: $type\n"
            "UID: ${uid.isEmpty ? '-' : uid}\n"
            "Meslek: ${meslek.isEmpty ? '-' : meslek}\n"
            "Konum: ${konum.isEmpty ? '-' : konum}\n"
            "Cinsiyet: ${gender.isEmpty ? '-' : gender}\n"
            "Yaş: ${minAge?.toString() ?? '-'} - ${maxAge?.toString() ?? '-'}";
      });
      try {
        await _reportsRef().add({
          "senderUid": senderUid,
          "title": title,
          "body": body,
          "type": type,
          "targetCount": targetUids.length,
          "filters": {
            "uid": uid,
            "meslek": meslek,
            "konum": konum,
            "cinsiyet": gender,
            "minAge": minAge,
            "maxAge": maxAge,
          },
          "createdDate": DateTime.now().millisecondsSinceEpoch,
        });
      } on FirebaseException catch (e) {
        if (e.code != 'permission-denied') rethrow;
      }
      Get.snackbar(
        "Gönderildi",
        "${targetUids.length} kullanıcı için bildirim kuyruğa alındı.",
        snackPosition: SnackPosition.BOTTOM,
      );
      _bodyController.clear();
    } catch (e) {
      if (!mounted) return;
      Get.snackbar(
        "Hata",
        "Gönderilemedi: $e",
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      if (mounted) {
        setState(() {
          _sending = false;
        });
      }
    }
  }

  InputDecoration _input(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(fontFamily: "MontserratMedium"),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.black),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_checkingAccess) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (!_canManagePush) {
      return Scaffold(
        appBar: AppBar(
          title: const Text(
            "Push Gonder",
            style: TextStyle(
              color: Colors.black,
              fontFamily: "MontserratSemiBold",
              fontSize: 20,
            ),
          ),
        ),
        body: const SafeArea(
          child: Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                "Bu ekran sadece admin yetkisine sahip hesaplarda kullanilabilir.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: "MontserratMedium",
                  fontSize: 14,
                  color: Colors.black87,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Push Gonder",
          style: TextStyle(
            color: Colors.black,
            fontFamily: "MontserratSemiBold",
            fontSize: 20,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              "Başlık ve mesaj zorunlu. Filtreleri boş bırakırsan herkese gider.",
              style: TextStyle(
                fontFamily: "MontserratMedium",
                fontSize: 13,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 12),
            const SizedBox(height: 12),
            TextField(
              controller: _titleController,
              decoration: _input("Başlık"),
              style: const TextStyle(fontFamily: "MontserratMedium"),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _bodyController,
              maxLines: 4,
              decoration: _input("Mesaj"),
              style: const TextStyle(fontFamily: "MontserratMedium"),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _selectedType,
              decoration: _input("Tür"),
              items: _pushTypes
                  .map(
                    (e) => DropdownMenuItem<String>(
                      value: e,
                      child: Text(
                        e,
                        style: const TextStyle(fontFamily: "MontserratMedium"),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (v) {
                if (v == null) return;
                setState(() {
                  _selectedType = v;
                });
              },
            ),
            const SizedBox(height: 8),
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: const Text(
                "Opsiyonel Filtreler",
                style: TextStyle(
                  fontFamily: "MontserratSemiBold",
                  color: Colors.black,
                  fontSize: 14,
                ),
              ),
              childrenPadding: const EdgeInsets.only(bottom: 8),
              children: [
                TextField(
                  controller: _uidController,
                  decoration: _input("Hedef UID (tek kullanıcı)"),
                  style: const TextStyle(fontFamily: "MontserratMedium"),
                ),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: _showMeslekSelector,
                  child: AbsorbPointer(
                    child: TextField(
                      decoration: _input("Meslek"),
                      controller: TextEditingController(
                        text: _selectedMeslek,
                      ),
                      style: const TextStyle(fontFamily: "MontserratMedium"),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _konumController,
                  decoration: _input("Konum (city / il / ilce)"),
                  style: const TextStyle(fontFamily: "MontserratMedium"),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _genderController,
                  decoration: _input("Cinsiyet"),
                  style: const TextStyle(fontFamily: "MontserratMedium"),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _minAgeController,
                        keyboardType: TextInputType.number,
                        decoration: _input("Min Yaş"),
                        style: const TextStyle(fontFamily: "MontserratMedium"),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _maxAgeController,
                        keyboardType: TextInputType.number,
                        decoration: _input("Max Yaş"),
                        style: const TextStyle(fontFamily: "MontserratMedium"),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (_lastReport.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.black12),
                  color: Colors.grey.shade100,
                ),
                child: Text(
                  _lastReport,
                  style: const TextStyle(
                    fontFamily: "MontserratMedium",
                    fontSize: 12,
                    color: Colors.black87,
                  ),
                ),
              ),
            const SizedBox(height: 14),
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: const Text(
                "Kalıcı Raporlar",
                style: TextStyle(
                  fontFamily: "MontserratSemiBold",
                  color: Colors.black,
                  fontSize: 14,
                ),
              ),
              childrenPadding: const EdgeInsets.only(bottom: 8),
              children: [
                StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: _reportsRef()
                      .orderBy("createdDate", descending: true)
                      .limit(20)
                      .snapshots(),
                  builder: (context, snap) {
                    if (!snap.hasData) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 10),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    final docs = snap.data!.docs;
                    if (docs.isEmpty) {
                      return Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.black12),
                        ),
                        child: const Text(
                          "Henüz rapor yok.",
                          style: TextStyle(
                            fontFamily: "MontserratMedium",
                            fontSize: 12,
                            color: Colors.black54,
                          ),
                        ),
                      );
                    }
                    return Column(
                      children: docs.map((d) {
                        final data = d.data();
                        final filters =
                            (data["filters"] as Map<String, dynamic>? ??
                                <String, dynamic>{});
                        final ts = data["createdDate"];
                        DateTime? dt;
                        if (ts is Timestamp) dt = ts.toDate();
                        final timeText = dt == null
                            ? "-"
                            : "${dt.day.toString().padLeft(2, "0")}.${dt.month.toString().padLeft(2, "0")} "
                                "${dt.hour.toString().padLeft(2, "0")}:${dt.minute.toString().padLeft(2, "0")}";
                        return Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.black12),
                            color: Colors.grey.shade100,
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  "$timeText | ${data["type"] ?? "-"} | ${data["targetCount"] ?? 0} kişi\n"
                                  "Başlık: ${data["title"] ?? "-"}\n"
                                  "Mesaj: ${(data["body"] ?? "-").toString()}\n"
                                  "Filtre: meslek=${(filters["meslek"] ?? "-").toString().isEmpty ? "-" : filters["meslek"]}, "
                                  "konum=${(filters["konum"] ?? "-").toString().isEmpty ? "-" : filters["konum"]}, "
                                  "cinsiyet=${(filters["cinsiyet"] ?? "-").toString().isEmpty ? "-" : filters["cinsiyet"]}",
                                  style: const TextStyle(
                                    fontFamily: "MontserratMedium",
                                    fontSize: 12,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                              IconButton(
                                onPressed: () async {
                                  await d.reference.delete();
                                },
                                icon: const Icon(
                                  Icons.delete_outline,
                                  color: Colors.black54,
                                  size: 20,
                                ),
                                tooltip: "Raporu Sil",
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: _sending ? null : _sendPush,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _sending
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        "Gönder",
                        style: TextStyle(fontFamily: "MontserratSemiBold"),
                      ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
