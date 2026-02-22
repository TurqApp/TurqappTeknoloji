import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class TestScreen extends StatefulWidget {
  const TestScreen({super.key});

  @override
  State<TestScreen> createState() => _TestScreenState();
}

class _TestScreenState extends State<TestScreen> {
  final List<_PostTimestampEntry> _entries = [];
  final List<String> _logs = [];
  final ScrollController _logController = ScrollController();
  final List<int> _batchSizes = const [2, 5, 10, 15, 20];

  bool _isLoading = true;
  bool _isUpdating = false;
  int _updatedCount = 0;
  int _currentBatchTarget = 0;

  @override
  void initState() {
    super.initState();
    _loadTimeStampEntries();
  }

  @override
  void dispose() {
    _logController.dispose();
    super.dispose();
  }

  Future<void> _loadTimeStampEntries() async {
    try {
      _appendLog('JSON dosyası yükleniyor...');
      final raw = await rootBundle.loadString('assets/data/timeStamp.json');
      final data = jsonDecode(raw);
      if (data is! List) {
        throw const FormatException('Beklenen liste yapısı bulunamadı.');
      }

      final parsedEntries = <_PostTimestampEntry>[];
      for (final item in data) {
        if (item is Map<String, dynamic>) {
          final entry = _PostTimestampEntry.tryParse(item);
          if (entry != null) {
            parsedEntries.add(entry);
          } else {
            _appendLog('Geçersiz kayıt atlandı: $item');
          }
        }
      }

      if (!mounted) return;
      setState(() {
        _entries
          ..clear()
          ..addAll(parsedEntries);
        _isLoading = false;
      });
      _appendLog('JSON yüklendi. Toplam ${parsedEntries.length} kayıt hazır.');
    } catch (e, st) {
      debugPrint('JSON okuma hatası: $e');
      debugPrintStack(stackTrace: st);
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      _appendLog('JSON yüklenemedi: $e');
    }
  }

  Future<void> _runUpdate(int limit) async {
    if (_isLoading) {
      _appendLog('Veri henüz yüklenmedi. Lütfen bekleyin.');
      return;
    }
    if (_isUpdating) {
      _appendLog('Güncelleme zaten devam ediyor.');
      return;
    }
    if (_entries.isEmpty) {
      _appendLog('İşlenecek kayıt bulunamadı.');
      return;
    }

    final int safeLimit =
        (limit <= 0 || limit > _entries.length) ? _entries.length : limit;
    if (safeLimit == 0) {
      _appendLog('Güncellenecek kayıt sayısı 0 olamaz.');
      return;
    }

    setState(() {
      _isUpdating = true;
      _updatedCount = 0;
      _currentBatchTarget = safeLimit;
    });
    _appendLog('Güncelleme başladı. Hedef kayıt: $safeLimit');

    final postsRef = FirebaseFirestore.instance.collection('Posts');

    for (var index = 0; index < safeLimit; index++) {
      final entry = _entries[index];
      try {
        await postsRef.doc(entry.postID).update({
          'timeStamp': entry.timeStamp,
        });
        _appendLog(
            '(${index + 1}/$safeLimit) ${entry.postID} -> ${entry.timeStamp}');
        if (mounted) {
          setState(() {
            _updatedCount = index + 1;
          });
        }
      } on FirebaseException catch (e) {
        _appendLog('Firebase hatası [${entry.postID}]: ${e.message ?? e.code}');
      } catch (e) {
        _appendLog('Beklenmeyen hata [${entry.postID}]: $e');
      }
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _isUpdating = false;
      _currentBatchTarget = 0;
    });
    _appendLog('Güncelleme tamamlandı. Başarıyla güncellenen: $_updatedCount');
  }

  void _appendLog(String message) {
    final timestamp = DateTime.now().toIso8601String();
    final line = '[$timestamp] $message';
    debugPrint(line);
    if (!mounted) {
      return;
    }
    setState(() {
      _logs.add(line);
      if (_logs.length > 500) {
        _logs.removeRange(0, _logs.length - 500);
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_logController.hasClients) {
        _logController.jumpTo(_logController.position.maxScrollExtent);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('TimeStamp Güncelleme Testi'),
      ),
      body: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_isLoading)
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CupertinoActivityIndicator(),
                    ),
                    SizedBox(width: 12),
                    Text('JSON yükleniyor...'),
                  ],
                )
              else
                Text(
                  'Toplam kayıt: ${_entries.length}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (final count in _batchSizes)
                    FilledButton(
                      onPressed: _isUpdating ? null : () => _runUpdate(count),
                      child: Text('İlk $count'),
                    ),
                  FilledButton.tonal(
                    onPressed:
                        _isUpdating ? null : () => _runUpdate(_entries.length),
                    child: const Text('Hepsi'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (_isUpdating)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LinearProgressIndicator(
                      value: _currentBatchTarget == 0
                          ? null
                          : _updatedCount / _currentBatchTarget,
                    ),
                    const SizedBox(height: 8),
                    Text('İlerleme: $_updatedCount/$_currentBatchTarget'),
                  ],
                )
              else
                Text('Son güncelleme: $_updatedCount kayıt'),
              const SizedBox(height: 16),
              Expanded(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color:
                        Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outlineVariant,
                    ),
                  ),
                  child: _logs.isEmpty
                      ? const Center(child: Text('Henüz log yok.'))
                      : Padding(
                          padding: const EdgeInsets.all(12),
                          child: ListView.builder(
                            controller: _logController,
                            itemCount: _logs.length,
                            itemBuilder: (context, index) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 4,
                                ),
                                child: Text(
                                  _logs[index],
                                  style: const TextStyle(fontSize: 12),
                                ),
                              );
                            },
                          ),
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

class _PostTimestampEntry {
  final String postID;
  final int timeStamp;

  const _PostTimestampEntry({required this.postID, required this.timeStamp});

  static _PostTimestampEntry? tryParse(Map<String, dynamic> map) {
    final rawId = map['postID'];
    if (rawId is! String || rawId.isEmpty) {
      return null;
    }
    final rawTs = map['timeStamp'] ?? map['TimeStamp'];
    if (rawTs == null) {
      return null;
    }

    int? ts;
    if (rawTs is int) {
      ts = rawTs;
    } else if (rawTs is num) {
      ts = rawTs.toInt();
    } else if (rawTs is String) {
      ts = int.tryParse(rawTs);
    }

    if (ts == null) {
      return null;
    }

    return _PostTimestampEntry(postID: rawId, timeStamp: ts);
  }
}
