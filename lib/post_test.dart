import 'package:flutter/material.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

class PostTest extends StatefulWidget {
  const PostTest({super.key});

  @override
  State<PostTest> createState() => _PostTestState();
}

class _PostTestState extends State<PostTest> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _limitController = TextEditingController();

  bool _isProcessing = false;
  int _processedCount = 0;
  int _totalCount = 0;
  String _status = "Hazır";
  final int _timestampToAdd = 647096509;

  @override
  void dispose() {
    _limitController.dispose();
    super.dispose();
  }

  Future<void> _updateTimestamps(int limit) async {
    print("\n🚀 [PostTest] Güncelleme başlatılıyor - Limit: $limit");

    setState(() {
      _isProcessing = true;
      _processedCount = 0;
      _totalCount = 0;
      _status = "Başlatılıyor...";
    });

    try {
      print("📡 [PostTest] Firebase'den dokümanlar getiriliyor...");

      // Posts koleksiyonundan limit kadar doküman al
      QuerySnapshot snapshot = await _firestore
          .collection('Posts')
          .orderBy('timeStamp', descending: true)
          .limit(limit)
          .get();

      _totalCount = snapshot.docs.length;
      print("✅ [PostTest] $_totalCount doküman bulundu");

      if (_totalCount == 0) {
        print("⚠️ [PostTest] Hiç doküman bulunamadı!");
        setState(() {
          _status = "⚠️ Hiç doküman bulunamadı";
          _isProcessing = false;
        });
        return;
      }

      setState(() {
        _status = "$_totalCount doküman bulundu. Güncelleniyor...";
      });

      print("🔄 [PostTest] Batch işlemi başlatılıyor...");

      // Her dokümanı güncelle
      WriteBatch batch = _firestore.batch();
      int batchCount = 0;
      int currentBatchNumber = 1;

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final currentTimestamp = data['timeStamp'] as int?;

        if (currentTimestamp != null) {
          final newTimestamp = currentTimestamp + _timestampToAdd;

          print("  📝 [${_processedCount + 1}/$_totalCount] DocID: ${doc.id}");
          print("     Eski: $currentTimestamp → Yeni: $newTimestamp");

          batch.update(doc.reference, {'timeStamp': newTimestamp});
          batchCount++;

          // Firebase batch limiti 500, her 500'de commit et
          if (batchCount >= 500) {
            print(
                "💾 [PostTest] Batch #$currentBatchNumber commit ediliyor (500 doküman)...");
            await batch.commit();
            print(
                "✅ [PostTest] Batch #$currentBatchNumber başarıyla commit edildi");
            batch = _firestore.batch();
            batchCount = 0;
            currentBatchNumber++;
          }

          setState(() {
            _processedCount++;
            _status = "Güncelleniyor: $_processedCount/$_totalCount";
          });
        } else {
          print("  ⚠️ [PostTest] DocID: ${doc.id} - timestamp değeri null!");
        }
      }

      // Kalan batch'i commit et
      if (batchCount > 0) {
        print(
            "💾 [PostTest] Son batch commit ediliyor ($batchCount doküman)...");
        await batch.commit();
        print("✅ [PostTest] Son batch başarıyla commit edildi");
      }

      print(
          "🎉 [PostTest] Tüm işlem tamamlandı! $_processedCount doküman güncellendi");

      setState(() {
        _status = "✅ Tamamlandı! $_processedCount doküman güncellendi.";
        _isProcessing = false;
      });

      // Başarı mesajı
      AppSnackbar(
        "Başarılı",
        "$_processedCount dokümanın timestamp değeri güncellendi",
        backgroundColor: Colors.green.withValues(alpha: 0.8),
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    } catch (e) {
      print("❌ [PostTest] HATA OLUŞTU: $e");
      print("❌ [PostTest] Stack Trace: ${StackTrace.current}");

      setState(() {
        _status = "❌ Hata: $e";
        _isProcessing = false;
      });

      AppSnackbar(
        "Hata",
        "Güncelleme sırasında hata: $e",
        backgroundColor: Colors.red.withValues(alpha: 0.8),
        colorText: Colors.white,
        duration: const Duration(seconds: 5),
      );
    }
  }

  Future<void> _updateAllTimestamps() async {
    print("\n⚠️ [PostTest] TÜM DOKÜMANLAR GÜNCELLEME TALEBİ");

    // Onay dialogu
    final bool? confirm = await Get.dialog<bool>(
      AlertDialog(
        title: const Text("Tüm Dokümanları Güncelle"),
        content: const Text(
          "TÜM Posts koleksiyonundaki dokümanların timestamp değerini güncellemek istediğinizden emin misiniz?\n\nBu işlem geri alınamaz!",
          style: TextStyle(height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text("İptal"),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text("Evet, Güncelle"),
          ),
        ],
      ),
    );

    if (confirm != true) {
      print("❌ [PostTest] Kullanıcı işlemi iptal etti");
      return;
    }

    print("✅ [PostTest] Kullanıcı onayladı, işlem başlıyor...");

    setState(() {
      _isProcessing = true;
      _processedCount = 0;
      _totalCount = 0;
      _status = "Tüm dokümanlar yükleniyor...";
    });

    try {
      print("📡 [PostTest] TÜM dokümanlar Firebase'den getiriliyor...");

      // Önce toplam doküman sayısını al
      QuerySnapshot countSnapshot = await _firestore.collection('Posts').get();
      _totalCount = countSnapshot.docs.length;

      print("✅ [PostTest] TOPLAM $_totalCount doküman bulundu!");
      print("🔥 [PostTest] Bu çok büyük bir işlem! Her doküman loglanacak...");

      setState(() {
        _status = "$_totalCount doküman bulundu. Güncelleme başlıyor...";
      });

      // Batch işlemi ile tüm dokümanları güncelle
      WriteBatch batch = _firestore.batch();
      int batchCount = 0;
      int currentBatchNumber = 1;

      for (var doc in countSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final currentTimestamp = data['timeStamp'] as int?;

        if (currentTimestamp != null) {
          final newTimestamp = currentTimestamp + _timestampToAdd;

          print("  📝 [${_processedCount + 1}/$_totalCount] DocID: ${doc.id}");
          print("     Eski: $currentTimestamp → Yeni: $newTimestamp");

          batch.update(doc.reference, {'timeStamp': newTimestamp});
          batchCount++;

          // Firebase batch limiti 500
          if (batchCount >= 500) {
            print(
                "💾 [PostTest] Batch #$currentBatchNumber commit ediliyor (500 doküman)...");
            await batch.commit();
            print(
                "✅ [PostTest] Batch #$currentBatchNumber başarıyla commit edildi");
            batch = _firestore.batch();
            batchCount = 0;
            currentBatchNumber++;
          }

          setState(() {
            _processedCount++;
            _status = "Güncelleniyor: $_processedCount/$_totalCount";
          });
        } else {
          print("  ⚠️ [PostTest] DocID: ${doc.id} - timestamp değeri null!");
        }
      }

      // Kalan batch'i commit et
      if (batchCount > 0) {
        print(
            "💾 [PostTest] SON BATCH commit ediliyor ($batchCount doküman)...");
        await batch.commit();
        print("✅ [PostTest] SON BATCH başarıyla commit edildi");
      }

      print(
          "🎉🎉🎉 [PostTest] TÜM İŞLEM TAMAMLANDI! $_processedCount doküman güncellendi");
      print("📊 [PostTest] Toplam Batch Sayısı: $currentBatchNumber");

      setState(() {
        _status = "✅ Tamamlandı! $_processedCount doküman güncellendi.";
        _isProcessing = false;
      });

      AppSnackbar(
        "Başarılı",
        "TÜM DOKÜMANLAR GÜNCELLENDİ: $_processedCount doküman",
        backgroundColor: Colors.green.withValues(alpha: 0.8),
        colorText: Colors.white,
        duration: const Duration(seconds: 5),
      );
    } catch (e) {
      print("❌❌❌ [PostTest] KRİTİK HATA: $e");
      print("❌ [PostTest] Stack Trace: ${StackTrace.current}");

      setState(() {
        _status = "❌ Hata: $e";
        _isProcessing = false;
      });

      AppSnackbar(
        "Hata",
        "Güncelleme sırasında hata: $e",
        backgroundColor: Colors.red.withValues(alpha: 0.8),
        colorText: Colors.white,
        duration: const Duration(seconds: 5),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Posts Timestamp Güncelleme",
          style: TextStyle(fontFamily: "MontserratBold"),
        ),
        backgroundColor: Colors.blueGrey,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Bilgi Kartı
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "ℹ️ Bilgi",
                      style: TextStyle(
                        fontSize: 18,
                        fontFamily: "MontserratBold",
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Her dokümanın timeStamp değerine +$_timestampToAdd eklenecek",
                      style: const TextStyle(
                        fontSize: 14,
                        fontFamily: "MontserratMedium",
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      "Örnek: 1768399680453 → 1769046776962",
                      style: TextStyle(
                        fontSize: 12,
                        fontFamily: "MontserratMedium",
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Test Butonları
              const Text(
                "Test Güncelleme",
                style: TextStyle(
                  fontSize: 16,
                  fontFamily: "MontserratBold",
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildTestButton(2),
                  _buildTestButton(5),
                  _buildTestButton(10),
                  _buildTestButton(20),
                ],
              ),
              const SizedBox(height: 16),

              // Özel Limit
              const Text(
                "Özel Limit",
                style: TextStyle(
                  fontSize: 16,
                  fontFamily: "MontserratBold",
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _limitController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: "Doküman sayısı girin",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      enabled: !_isProcessing,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _isProcessing
                        ? null
                        : () {
                            final limit = int.tryParse(_limitController.text);
                            if (limit != null && limit > 0) {
                              _updateTimestamps(limit);
                            } else {
                              AppSnackbar(
                                "Hata",
                                "Lütfen geçerli bir sayı girin",
                                backgroundColor:
                                    Colors.orange.withValues(alpha: 0.8),
                                colorText: Colors.white,
                              );
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    child: const Text("Güncelle"),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Tüm Dokümanları Güncelle
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                ),
                child: Column(
                  children: [
                    const Text(
                      "⚠️ UYARI",
                      style: TextStyle(
                        fontSize: 18,
                        fontFamily: "MontserratBold",
                        color: Colors.red,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Bu buton TÜM Posts koleksiyonunu güncelleyecek!",
                      style: TextStyle(
                        fontSize: 14,
                        fontFamily: "MontserratMedium",
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isProcessing ? null : _updateAllTimestamps,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text(
                          "TÜM DOKÜMANLARI GÜNCELLE",
                          style: TextStyle(
                            fontSize: 16,
                            fontFamily: "MontserratBold",
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Status Display
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Durum",
                      style: TextStyle(
                        fontSize: 16,
                        fontFamily: "MontserratBold",
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _status,
                      style: const TextStyle(
                        fontSize: 14,
                        fontFamily: "MontserratMedium",
                        height: 1.5,
                      ),
                    ),
                    if (_isProcessing) ...[
                      const SizedBox(height: 12),
                      LinearProgressIndicator(
                        value: _totalCount > 0
                            ? _processedCount / _totalCount
                            : null,
                        backgroundColor: Colors.grey.withValues(alpha: 0.2),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTestButton(int limit) {
    return ElevatedButton(
      onPressed: _isProcessing ? null : () => _updateTimestamps(limit),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blueGrey,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
      child: Text(
        "$limit Doküman",
        style: const TextStyle(
          fontFamily: "MontserratMedium",
        ),
      ),
    );
  }
}
