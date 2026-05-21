import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

Future<T> runTracedTransaction<T>(
  FirebaseFirestore firestore,
  String name,
  Future<T> Function(Transaction transaction) action,
) async {
  final id = '${DateTime.now().millisecondsSinceEpoch}';
  _traceTransaction('tx_start name=$name id=$id');
  try {
    final result = await firestore.runTransaction<T>((transaction) async {
      _traceTransaction('tx_enter name=$name id=$id');
      final value = await action(transaction);
      _traceTransaction('tx_callback_done name=$name id=$id');
      return value;
    });
    _traceTransaction('tx_done name=$name id=$id');
    return result;
  } catch (error, stackTrace) {
    _traceTransaction('tx_error name=$name id=$id error=$error');
    unawaited(
      FirebaseCrashlytics.instance.recordError(
        error,
        stackTrace,
        fatal: false,
        reason: 'firestore_transaction_trace:$name',
      ),
    );
    rethrow;
  }
}

void traceTransactionWrite(String name, String operation) {
  _traceTransaction('tx_write name=$name op=$operation');
}

void _traceTransaction(String message) {
  final line = '[FirestoreTxTrace] $message';
  if (kDebugMode) {
    debugPrint(line);
  }
  try {
    unawaited(FirebaseCrashlytics.instance.log(line));
  } catch (_) {}
}
