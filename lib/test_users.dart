import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

class TestUsers extends StatefulWidget {
  const TestUsers({super.key});

  @override
  State<TestUsers> createState() => _TestUsersState();
}

class _TestUsersState extends State<TestUsers> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseFunctions _functions =
      FirebaseFunctions.instanceFor(region: 'europe-west1');
  final List<String> _logs = <String>[];

  bool _isProcessing = false;

  static const Set<String> _protectedCollections = <String>{
    'TakipEdilenler',
    'Takipciler',
    'SosyalMedyaLinkleri',
  };

  void _log(String message) {
    final now = DateTime.now();
    final formattedTimestamp =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}.${now.millisecond.toString().padLeft(3, '0')}';
    final entry = '[$formattedTimestamp] $message';

    debugPrint(entry);
    if (!mounted) {
      return;
    }

    setState(() {
      _logs.insert(0, entry);
      if (_logs.length > 200) {
        _logs.removeLast();
      }
    });
  }

  Future<void> _handleCleanup({int? limit}) async {
    if (_isProcessing) {
      _log('İşlem devam ediyor; yeni istek yok sayıldı.');
      return;
    }

    if (mounted) {
      setState(() {
        _isProcessing = true;
      });
    } else {
      _isProcessing = true;
    }

    final label = limit == null ? 'tüm dokümanlar' : '$limit doküman';
    _log('Temizleme işlemi başlatıldı ($label).');
    _log('Korunan alt koleksiyonlar: '
        '${_protectedCollections.join(', ')}');

    try {
      await _cleanSubcollections(limit: limit);
      _log('Temizleme işlemi tamamlandı ($label).');
    } catch (error, stackTrace) {
      _log('Hata oluştu: $error');
      debugPrint(stackTrace.toString());
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      } else {
        _isProcessing = false;
      }
    }
  }

  Future<void> _cleanSubcollections({int? limit}) async {
    final baseQuery = _firestore.collection('users');
    final querySnapshot = limit != null
        ? await baseQuery.limit(limit).get()
        : await baseQuery.get();

    if (querySnapshot.docs.isEmpty) {
      _log('users koleksiyonunda temizlenecek doküman bulunamadı.');
      return;
    }

    final totalDocs = querySnapshot.docs.length;
    _log('$totalDocs doküman incelenecek.');

    var processedDocs = 0;
    var totalDeletedDocs = 0;
    final Map<String, int> subcollectionDeleteSummary = <String, int>{};
    final Map<String, int> failureSummary = <String, int>{};

    for (final docSnapshot in querySnapshot.docs) {
      processedDocs++;
      final docId = docSnapshot.id;
      _log('Doküman $processedDocs/$totalDocs işleniyor (ID: $docId).');
      try {
        final purgeResult =
            await _purgeStudentCollections(docSnapshot.reference);

        if (!purgeResult.found) {
          _log('  Doküman mevcut değil (atlandı).');
          continue;
        }

        if (!purgeResult.ok) {
          _log('  Sunucu "ok" dönmedi: ${purgeResult.message ?? 'bilinmiyor'}');
          continue;
        }

        if (purgeResult.failedDetails.isNotEmpty) {
          for (final failure in purgeResult.failedDetails) {
            _log('  ${failure.name} alt koleksiyonunda hata: '
                '${failure.message}');
            failureSummary.update(
              failure.name,
              (value) => value + 1,
              ifAbsent: () => 1,
            );
          }
        }

        if (purgeResult.deletedDetails.isEmpty) {
          if (purgeResult.skippedCollections.isNotEmpty) {
            _log('  Korunan koleksiyonlar: '
                '${purgeResult.skippedCollections.join(', ')}');
          }
          _log('  Silinecek alt koleksiyon bulunamadı.');
        } else {
          for (final detail in purgeResult.deletedDetails) {
            _log('  ${detail.name} alt koleksiyonundan '
                '${detail.deletedDocuments} doküman silindi.');
            subcollectionDeleteSummary.update(
              detail.name,
              (value) => value + detail.deletedDocuments,
              ifAbsent: () => detail.deletedDocuments,
            );
          }
          if (purgeResult.totalDeletedDocuments > 0) {
            _log(
                '  Toplam ${purgeResult.totalDeletedDocuments} doküman silindi.');
            totalDeletedDocs += purgeResult.totalDeletedDocuments;
          }
          if (purgeResult.skippedCollections.isNotEmpty) {
            _log('  Korunan koleksiyonlar: '
                '${purgeResult.skippedCollections.join(', ')}');
          }
        }
      } catch (error, stackTrace) {
        if (error is FirebaseFunctionsException) {
          if (error.code == 'not-found') {
            _log('  purgeStudentSubcollections fonksiyonu bulunamadı. '
                'Firebase Functions dağıtımını kontrol edin.');
          } else {
            _log('  Firebase Functions hatası: ${error.code} - '
                '${error.message ?? 'bilinmiyor'}');
          }
        } else {
          _log('  Doküman ${docSnapshot.id} üzerinde hata: $error');
        }
        debugPrint(stackTrace.toString());
      }
    }

    _log('--- Özet ---');
    _log('İşlenen doküman: $processedDocs/$totalDocs');
    _log('Toplam silinen doküman: $totalDeletedDocs');

    if (subcollectionDeleteSummary.isEmpty) {
      _log('Alt koleksiyon silme özeti: değişiklik yok.');
    } else {
      _log('Alt koleksiyon silme özeti:');
      final entries = subcollectionDeleteSummary.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      for (final entry in entries) {
        _log('  ${entry.key}: ${entry.value} doküman');
      }
    }

    if (failureSummary.isNotEmpty) {
      _log('Hata alınan koleksiyonlar:');
      final entries = failureSummary.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      for (final entry in entries) {
        _log('  ${entry.key}: ${entry.value} doküman');
      }
    }
  }

  Future<_PurgeResponse> _purgeStudentCollections(
    DocumentReference<Map<String, dynamic>> docRef,
  ) async {
    Future<_PurgeResponse> invoke(FirebaseFunctions functions) async {
      final callable = functions.httpsCallable(
        'purgeStudentSubcollections',
        options: HttpsCallableOptions(timeout: const Duration(minutes: 2)),
      );

      final result = await callable.call<Map<String, dynamic>>({
        'docPath': docRef.path,
      });

      return _PurgeResponse.fromMap(result.data);
    }

    try {
      return await invoke(_functions);
    } on FirebaseFunctionsException catch (error) {
      if (error.code == 'not-found') {
        _log('  purgeStudentSubcollections fonksiyonu bulunamadı. '
            'Varsayılan bölgeden yeniden denenecek.');
        final fallback = FirebaseFunctions.instance;
        if (!identical(fallback, _functions)) {
          try {
            return await invoke(fallback);
          } on FirebaseFunctionsException catch (secondError) {
            _log('  Varsayılan bölgede de fonksiyon bulunamadı: '
                '${secondError.message}');
            rethrow;
          }
        }
      }

      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    const buttons = <_CleanupConfig>[
      _CleanupConfig(label: '2 Doküman', limit: 2),
      _CleanupConfig(label: '5 Doküman', limit: 5),
      _CleanupConfig(label: '10 Doküman', limit: 10),
      _CleanupConfig(label: '20 Doküman', limit: 20),
      _CleanupConfig(label: 'Tümü', limit: null),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Users'),
        actions: [
          IconButton(
            onPressed: _isProcessing
                ? null
                : () {
                    if (!mounted) {
                      return;
                    }

                    setState(() {
                      _logs.clear();
                    });
                    _log('Log geçmişi temizlendi.');
                  },
            tooltip: 'Logları temizle',
            icon: const Icon(Icons.clear_all),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: buttons
                    .map(
                      (config) => ElevatedButton.icon(
                        icon: const Icon(Icons.cleaning_services_outlined),
                        label: Text(config.label),
                        onPressed: _isProcessing
                            ? null
                            : () => _handleCleanup(limit: config.limit),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 16),
              if (_isProcessing)
                const LinearProgressIndicator(
                  minHeight: 3,
                ),
              const SizedBox(height: 16),
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color:
                        Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: _logs.isEmpty
                      ? const Center(
                          child: Text(
                            'Henüz log kaydı yok.',
                            style: TextStyle(fontSize: 13),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: _logs.length,
                          itemBuilder: (context, index) {
                            final log = _logs[index];
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: SelectableText(
                                log,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CleanupConfig {
  const _CleanupConfig({required this.label, this.limit});

  final String label;
  final int? limit;
}

class _PurgeResponse {
  _PurgeResponse({
    required this.ok,
    required this.found,
    required this.deletedDetails,
    required this.skippedCollections,
    required this.failedDetails,
    this.totalDeletedDocuments = 0,
    this.message,
  });

  final bool ok;
  final bool found;
  final List<_PurgeDetail> deletedDetails;
  final List<String> skippedCollections;
  final List<_PurgeFailure> failedDetails;
  final int totalDeletedDocuments;
  final String? message;

  factory _PurgeResponse.fromMap(dynamic data) {
    if (data is! Map) {
      return _PurgeResponse(
        ok: false,
        found: false,
        deletedDetails: const <_PurgeDetail>[],
        skippedCollections: const <String>[],
        failedDetails: const <_PurgeFailure>[],
        message: 'Beklenmeyen yanıt formatı',
      );
    }

    final map = Map<String, dynamic>.from(
      data as Map<Object?, Object?>,
    );
    final deleted = (map['deletedSubcollections'] as List?)
            ?.map((item) => _PurgeDetail.fromMap(item))
            .whereType<_PurgeDetail>()
            .toList() ??
        <_PurgeDetail>[];

    final skipped = (map['skippedCollections'] as List?)
            ?.map((e) => e?.toString())
            .whereType<String>()
            .toList() ??
        <String>[];

    final failures = (map['failedSubcollections'] as List?)
            ?.map((item) => _PurgeFailure.fromMap(item))
            .whereType<_PurgeFailure>()
            .toList() ??
        <_PurgeFailure>[];

    return _PurgeResponse(
      ok: map['ok'] == true,
      found: map['found'] != false,
      deletedDetails: deleted,
      skippedCollections: skipped,
      failedDetails: failures,
      totalDeletedDocuments: map['totalDeletedDocuments'] is int
          ? map['totalDeletedDocuments'] as int
          : (map['totalDeletedDocuments'] is num
              ? (map['totalDeletedDocuments'] as num).round()
              : 0),
      message: map['message']?.toString(),
    );
  }
}

class _PurgeDetail {
  _PurgeDetail({required this.name, required this.deletedDocuments});

  final String name;
  final int deletedDocuments;

  factory _PurgeDetail.fromMap(dynamic data) {
    if (data is! Map) {
      return _PurgeDetail(name: 'unknown', deletedDocuments: 0);
    }

    final map = Map<String, dynamic>.from(
      data as Map<Object?, Object?>,
    );
    return _PurgeDetail(
      name: map['name']?.toString() ?? 'unknown',
      deletedDocuments: map['deletedDocuments'] is int
          ? map['deletedDocuments'] as int
          : (map['deletedDocuments'] is num
              ? (map['deletedDocuments'] as num).round()
              : 0),
    );
  }
}

class _PurgeFailure {
  _PurgeFailure({required this.name, required this.message});

  final String name;
  final String message;

  factory _PurgeFailure.fromMap(dynamic data) {
    if (data is! Map) {
      return _PurgeFailure(name: 'unknown', message: 'Bilinmeyen hata');
    }

    final map = Map<String, dynamic>.from(
      data as Map<Object?, Object?>,
    );

    return _PurgeFailure(
      name: map['name']?.toString() ?? 'unknown',
      message: map['message']?.toString() ?? 'Bilinmeyen hata',
    );
  }
}
