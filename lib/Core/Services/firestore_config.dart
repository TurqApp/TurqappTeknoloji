// 🔥 Firestore Configuration Service
// Configures Firestore cache, persistence, and optimization settings

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class FirestoreConfig {
  static bool _initialized = false;

  /// Initialize Firestore with optimized settings
  /// Call this once during app startup
  static Future<void> initialize() async {
    if (_initialized) return;

    try {
      final firestore = FirebaseFirestore.instance;

      // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
      // 📦 CACHE SETTINGS
      // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

      final settings = Settings(
        // ✅ Enable offline persistence (automatic cache)
        persistenceEnabled: true,

        // ✅ Cache size: 100 MB (SDK upper limit)
        cacheSizeBytes: 100 * 1024 * 1024,

        // ✅ SSL validation
        sslEnabled: true,
      );

      firestore.settings = settings;

      _initialized = true;

      if (kDebugMode) {
        print('✅ Firestore initialized with optimized settings');
        print('   - Persistence: enabled');
        print('   - Cache size: 100 MB');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Firestore initialization error: $e');
      }
    }
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 🔧 HELPER METHODS
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  /// Get data with cache-first strategy
  /// Tries cache first, falls back to network
  static Future<DocumentSnapshot<Map<String, dynamic>>> getDocWithCache(
    DocumentReference<Map<String, dynamic>> docRef,
  ) async {
    try {
      // Try cache first
      final cached = await docRef.get(const GetOptions(source: Source.cache));
      if (cached.exists) {
        return cached;
      }
    } catch (_) {
      // Cache miss or error - fallback to server
    }

    // Fallback to server
    return await docRef.get(const GetOptions(source: Source.server));
  }

  /// Get collection with cache-first strategy
  static Future<QuerySnapshot<Map<String, dynamic>>> getCollectionWithCache(
    Query<Map<String, dynamic>> query,
  ) async {
    try {
      // Try cache first
      final cached = await query.get(const GetOptions(source: Source.cache));
      if (cached.docs.isNotEmpty) {
        return cached;
      }
    } catch (_) {
      // Cache miss or error - fallback to server
    }

    // Fallback to server
    return await query.get(const GetOptions(source: Source.server));
  }

  /// Clear Firestore cache
  /// Use sparingly - only when absolutely needed
  static Future<void> clearCache() async {
    try {
      await FirebaseFirestore.instance.clearPersistence();
      if (kDebugMode) {
        print('✅ Firestore cache cleared');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to clear Firestore cache: $e');
      }
    }
  }
}
