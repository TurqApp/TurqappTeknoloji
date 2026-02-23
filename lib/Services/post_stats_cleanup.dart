import 'package:cloud_firestore/cloud_firestore.dart';

/// Firebase'deki postlardaki eski count field'larını temizlemek için özel servis
class PostStatsCleanup {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Tek bir posttaki eski count field'larını sil ve stats'a taşı
  static Future<bool> cleanupPost(String postId) async {
    try {
      print('🧹 Cleaning up post: $postId');

      final postRef = _firestore.collection('Posts').doc(postId);
      final doc = await postRef.get();

      if (!doc.exists) {
        print('❌ Post not found: $postId');
        return false;
      }

      final data = doc.data()!;
      final updates = <String, dynamic>{};

      // Stats objesi kontrolü
      final existingStats = data['stats'] as Map<String, dynamic>?;

      if (existingStats == null || existingStats.isEmpty) {
        // Eski field'lardan stats objesi oluştur
        final stats = {
          'commentCount': data['commentCount'] ?? 0,
          'likeCount': data['likeCount'] ?? 0,
          'reportedCount': data['reportedCount'] ?? 0,
          'retryCount': data['retryCount'] ?? 0,
          'savedCount': data['savedCount'] ?? 0,
          'statsCount': data['statsCount'] ?? 0,
        };

        updates['stats'] = stats;
        print('📊 Created stats object: $stats');
      }

      // Eski field'ları temizle
      final oldFields = [
        'commentCount',
        'likeCount',
        'reportedCount',
        'retryCount',
        'savedCount',
        'statsCount',
        'kayitEdenler',
        'sharedAsPost'
      ];

      for (final field in oldFields) {
        if (data.containsKey(field)) {
          updates[field] = FieldValue.delete();
          print('🗑️ Removing old field: $field');
        }
      }

      if (updates.isNotEmpty) {
        await postRef.update(updates);
        print('✅ Post cleanup completed: $postId');
        return true;
      } else {
        print('ℹ️ No cleanup needed for post: $postId');
        return true;
      }
    } catch (e) {
      print('❌ Cleanup error for post $postId: $e');
      return false;
    }
  }

  /// Tüm postları temizle
  static Future<void> cleanupAllPosts({int batchSize = 50}) async {
    print('🚀 Starting cleanup of all posts...');

    Query query = _firestore.collection('Posts').limit(batchSize);
    DocumentSnapshot? lastDoc;

    int totalCleaned = 0;
    int totalFailed = 0;

    do {
      QuerySnapshot querySnapshot;
      if (lastDoc != null) {
        querySnapshot = await query.startAfterDocument(lastDoc).get();
      } else {
        querySnapshot = await query.get();
      }

      if (querySnapshot.docs.isEmpty) break;

      print('🔄 Processing batch of ${querySnapshot.docs.length} posts...');

      for (final doc in querySnapshot.docs) {
        final success = await cleanupPost(doc.id);
        if (success) {
          totalCleaned++;
        } else {
          totalFailed++;
        }

        // Rate limiting
        await Future.delayed(Duration(milliseconds: 100));
      }

      lastDoc = querySnapshot.docs.last;
      print('📊 Batch completed. Cleaned: $totalCleaned, Failed: $totalFailed');

      // Batch arası bekleme
      await Future.delayed(Duration(seconds: 1));
    } while (true);

    print(
        '🎉 Cleanup completed! Total Cleaned: $totalCleaned, Total Failed: $totalFailed');
  }

  /// Belirli bir kullanıcının postlarını temizle
  static Future<void> cleanupUserPosts(String userId) async {
    print('👤 Cleaning posts for user: $userId');

    final querySnapshot = await _firestore
        .collection('Posts')
        .where('userID', isEqualTo: userId)
        .get();

    print('📝 Found ${querySnapshot.docs.length} posts for user: $userId');

    int cleaned = 0;
    int failed = 0;

    for (final doc in querySnapshot.docs) {
      final success = await cleanupPost(doc.id);
      if (success) {
        cleaned++;
      } else {
        failed++;
      }

      // Rate limiting
      await Future.delayed(Duration(milliseconds: 100));
    }

    print('✅ User cleanup completed. Cleaned: $cleaned, Failed: $failed');
  }

  /// Cleanup progress kontrolü
  static Future<Map<String, int>> getCleanupProgress() async {
    try {
      final allPosts = await _firestore.collection('Posts').get();

      int needsCleanup = 0;
      int alreadyCleaned = 0;

      for (final doc in allPosts.docs) {
        final data = doc.data();

        // Eski field'lar var mı?
        final hasOldFields = data.containsKey('commentCount') ||
            data.containsKey('likeCount') ||
            data.containsKey('kayitEdenler') ||
            data.containsKey('sharedAsPost');

        if (hasOldFields) {
          needsCleanup++;
        } else {
          alreadyCleaned++;
        }
      }

      return {
        'total': allPosts.docs.length,
        'needsCleanup': needsCleanup,
        'alreadyCleaned': alreadyCleaned,
      };
    } catch (e) {
      print('❌ Progress check error: $e');
      return {'total': 0, 'needsCleanup': 0, 'alreadyCleaned': 0};
    }
  }
}

/// Cleanup çalıştırma helper'ları
class StatsCleanupRunner {
  /// Production cleanup başlat
  static Future<void> runCleanup() async {
    print('🧹 Starting Post Stats Cleanup...');

    // İlk olarak progress kontrol et
    final progress = await PostStatsCleanup.getCleanupProgress();
    print('📊 Cleanup Progress: ${progress.toString()}');

    if (progress['needsCleanup']! > 0) {
      print('🚀 Starting cleanup for ${progress['needsCleanup']} posts...');
      await PostStatsCleanup.cleanupAllPosts();
    } else {
      print('✅ All posts are already cleaned! 🎉');
    }
  }

  /// Test için tek post cleanup
  static Future<void> testCleanup(String postId) async {
    print('🧪 Testing cleanup for post: $postId');
    final success = await PostStatsCleanup.cleanupPost(postId);
    print('🎯 Cleanup result: ${success ? 'SUCCESS' : 'FAILED'}');
  }
}
