import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';

class TestFirebase extends StatefulWidget {
  const TestFirebase({super.key});

  @override
  State<TestFirebase> createState() => _TestFirebaseState();
}

class _TestFirebaseState extends State<TestFirebase> {
  final List<_DeleteOption> _options = const <_DeleteOption>[
    _DeleteOption(label: 'First 2 Docs', limit: 2),
    _DeleteOption(label: 'First 5 Docs', limit: 5),
    _DeleteOption(label: 'First 10 Docs', limit: 10),
    _DeleteOption(label: 'First 20 Docs', limit: 20),
    _DeleteOption(label: 'All Documents', limit: null),
  ];

  final List<String> _logMessages = <String>[];
  final ScrollController _logScrollController = ScrollController();

  bool _isProcessing = false;
  int? _activeLimit;
  int _totalDocsToProcess = 0;
  int _processedDocs = 0;

  static const List<String> _statKeys = <String>[
    'commentCount',
    'likeCount',
    'reportedCount',
    'retryCount',
    'statsCount',
    'savedCount',
  ];

  @override
  void dispose() {
    _logScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Posts Subcollection Cleaner'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Choose how many documents to scan. Every run removes subcollections only and streams detailed logs here and in the debug console.',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: _options.map((opt) {
                  final bool isActive =
                      _activeLimit == opt.limit && _isProcessing;
                  return ElevatedButton.icon(
                    onPressed:
                        _isProcessing ? null : () => _startCleanup(opt.limit),
                    icon: Icon(
                      isActive ? Icons.hourglass_top : Icons.play_arrow,
                    ),
                    label: Text(opt.label),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              if (_isProcessing)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    LinearProgressIndicator(
                      value: _totalDocsToProcess > 0
                          ? _processedDocs / _totalDocsToProcess
                          : null,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Progress: $_processedDocs / $_totalDocsToProcess documents processed',
                      style: theme.textTheme.labelLarge,
                    ),
                  ],
                )
              else if (_processedDocs > 0)
                Text(
                  'Last run completed: $_processedDocs documents inspected.',
                  style: theme.textTheme.labelLarge,
                ),
              const SizedBox(height: 16),
              Row(
                children: <Widget>[
                  ElevatedButton.icon(
                    onPressed: _isProcessing ? null : _clearLogs,
                    icon: const Icon(Icons.cleaning_services_outlined),
                    label: const Text('Clear Logs'),
                  ),
                  const SizedBox(width: 12),
                  if (_isProcessing)
                    Text(
                      'Active runs cannot be cancelled.',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: theme.colorScheme.error),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: theme.dividerColor),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: _logMessages.isEmpty
                        ? Center(
                            child: Text(
                              'No logs yet. Start a run to monitor progress.',
                              style: theme.textTheme.bodyMedium,
                              textAlign: TextAlign.center,
                            ),
                          )
                        : ListView.builder(
                            controller: _logScrollController,
                            itemCount: _logMessages.length,
                            itemBuilder: (BuildContext context, int index) {
                              return Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 4),
                                child: Text(
                                  _logMessages[index],
                                  style: theme.textTheme.bodySmall
                                      ?.copyWith(fontFamily: 'monospace'),
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

  Future<void> _startCleanup(int? limit) async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
      _activeLimit = limit;
      _processedDocs = 0;
      _totalDocsToProcess = 0;
    });

    _log(
        '--- Run started (${limit == null ? 'ALL DOCUMENTS' : 'FIRST $limit DOCUMENTS'}) ---');

    try {
      final FirebaseFirestore firestore = FirebaseFirestore.instance;
      Query<Map<String, dynamic>> query =
          firestore.collection('Posts').orderBy(FieldPath.documentId);

      if (limit != null) {
        query = query.limit(limit);
      }

      final QuerySnapshot<Map<String, dynamic>> snapshot = await query.get();
      final List<QueryDocumentSnapshot<Map<String, dynamic>>> docs =
          snapshot.docs;

      if (!mounted) return;

      setState(() {
        _totalDocsToProcess = docs.length;
      });

      if (docs.isEmpty) {
        _log('No documents found in Posts. Nothing to do.');
        return;
      }

      for (int index = 0; index < docs.length; index++) {
        final QueryDocumentSnapshot<Map<String, dynamic>> doc = docs[index];
        final DocumentReference<Map<String, dynamic>> docRef = doc.reference;

        _log(
            '[${index + 1}/${docs.length}] Processing document: ${docRef.path}');

        final String docLabel = '[${index + 1}/${docs.length}]';
        _log('$docLabel Start processing ${docRef.path}');

        bool cleanupSucceeded = false;
        bool statsSucceeded = false;

        try {
          await _deleteSubcollectionsOf(docRef, docLabel);
          cleanupSucceeded = true;
          _log('$docLabel Subcollections cleared');
        } catch (e, stackTrace) {
          _log('$docLabel Warning - subcollection cleanup failed: $e');
          debugPrint('Detailed error (${docRef.path}): $e');
          debugPrint('StackTrace:\n$stackTrace');
        }

        try {
          await _resetStats(docRef);
          statsSucceeded = true;
          _log('$docLabel Stats zeroed and kayitEdenler removed');
        } catch (e, stackTrace) {
          _log('$docLabel Warning - stats reset failed: $e');
          debugPrint('Stats reset error (${docRef.path}): $e');
          debugPrint('StackTrace:\n$stackTrace');
        }

        if (cleanupSucceeded && statsSucceeded) {
          _log('$docLabel Completed');
        }

        if (!mounted) return;
        setState(() {
          _processedDocs = index + 1;
        });
      }

      _log('--- Run completed. $_processedDocs documents inspected. ---');
    } catch (e, stackTrace) {
      _log('Run aborted due to fatal error: $e');
      debugPrint('StackTrace:\n$stackTrace');
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Future<void> _deleteSubcollectionsOf(
    DocumentReference<Map<String, dynamic>> document,
    String docLabel,
  ) async {
    try {
      final HttpsCallable callable = FirebaseFunctions.instanceFor(
        region: 'europe-west1',
      ).httpsCallable('purgePostSubcollections');
      final HttpsCallableResult<dynamic> response =
          await callable.call(<String, dynamic>{'docPath': document.path});

      final Object? rawData = response.data;
      if (rawData case final Map<dynamic, dynamic> rawMap) {
        final Map<String, dynamic> data = rawMap.map(
          (dynamic key, dynamic value) => MapEntry(key.toString(), value),
        );
        final List<dynamic> deletedRaw = List<dynamic>.from(
            data['deletedSubcollections'] as List? ?? const []);
        final int totalDeleted = _asInt(data['totalDeletedDocuments']);

        if (deletedRaw.isEmpty) {
          _log('$docLabel No subcollections found');
          return;
        }

        _log(
            '$docLabel Cloud function removed ${deletedRaw.length} subcollections (total docs: $totalDeleted)');
        if (totalDeleted >= 0) {
          _log('$docLabel Total documents deleted: $totalDeleted');
        }

        for (final dynamic entry in deletedRaw) {
          if (entry case final Map<dynamic, dynamic> rawDetail) {
            final Map<String, dynamic> detail = rawDetail.map(
              (dynamic key, dynamic value) => MapEntry(key.toString(), value),
            );
            final String name = detail['name'] as String? ?? 'unknown';
            final int count = _asInt(detail['deletedDocuments']);
            _log('$docLabel   [$name] deleted documents: $count');
          } else {
            _log('$docLabel   $entry');
          }
        }
        return;
      }

      _log('$docLabel Unexpected response: $rawData');
      return;
    } on FirebaseFunctionsException catch (e, stackTrace) {
      _log(
        '$docLabel Cloud function purgePostSubcollections failed: ${e.message ?? e.code}',
      );
      debugPrint(
          'Cloud function error (${document.path}): ${e.code} - ${e.message}');
      debugPrint('StackTrace:\n$stackTrace');
      rethrow;
    } catch (e, stackTrace) {
      _log('$docLabel purgePostSubcollections threw: $e');
      debugPrint('Cloud function unexpected error (${document.path}): $e');
      debugPrint('StackTrace:\n$stackTrace');
      rethrow;
    }
  }

  int _asInt(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.round();
    }
    return -1;
  }

  Future<void> _resetStats(
      DocumentReference<Map<String, dynamic>> reference) async {
    final Map<String, Object?> zeroStats = <String, Object?>{
      for (final String key in _statKeys) key: 0,
    };

    final Map<String, Object?> payload = <String, Object?>{
      'stats': zeroStats,
    };

    for (final String key in _statKeys) {
      payload[key] = FieldValue.delete();
    }

    payload['kayitEdenler'] = FieldValue.delete();

    await reference.set(payload, SetOptions(merge: true));
  }

  void _log(String message) {
    final String timestamp = DateTime.now().toIso8601String();
    final String entry = '[$timestamp] $message';

    debugPrint(entry);

    if (!mounted) {
      return;
    }

    setState(() {
      _logMessages.add(entry);
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_logScrollController.hasClients) {
        _logScrollController
            .jumpTo(_logScrollController.position.maxScrollExtent);
      }
    });
  }

  void _clearLogs() {
    setState(() {
      _logMessages.clear();
      _processedDocs = 0;
      _totalDocsToProcess = 0;
      _activeLimit = null;
    });
  }
}

class _DeleteOption {
  const _DeleteOption({required this.label, required this.limit});

  final String label;
  final int? limit;
}
