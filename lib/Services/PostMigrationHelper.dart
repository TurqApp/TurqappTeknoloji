import 'package:cloud_firestore/cloud_firestore.dart';

/// Eski post verilerini yeni yapıya migrate etmek için helper sınıf
class PostMigrationHelper {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Tek bir postu yeni yapıya migrate et
  static Future<bool> migratePost(String postId) async {
    try {
      print('Migrating post: $postId');

      final postDoc = await _firestore.collection('Posts').doc(postId).get();
      if (!postDoc.exists) {
        print('Post not found: $postId');
        return false;
      }

      final data = postDoc.data()!;

      // Eski kayitEdenler listesini yeni saveds alt koleksiyonuna taşı
      if (data.containsKey('kayitEdenler')) {
        final kayitEdenler = List<String>.from(data['kayitEdenler'] ?? []);
        print('Found ${kayitEdenler.length} saved users for post: $postId');

        // Batch işlem oluştur
        final batch = _firestore.batch();

        // Her kayıt eden için saveds alt koleksiyonunda dokuman oluştur
        for (final userId in kayitEdenler) {
          final savedRef = _firestore
              .collection('Posts')
              .doc(postId)
              .collection('saveds')
              .doc(userId);

          batch.set(savedRef, {
            'userID': userId,
            'timestamp': DateTime.now().millisecondsSinceEpoch, // Geçmiş tarih verileri yok
          });
        }

        await batch.commit();
        print('Migrated ${kayitEdenler.length} saved records');
      }

      // Eski yapıdaki ayrı stat field'larını stats objesi altına taşı
      final updates = <String, dynamic>{};

      // Önce stats objesi olup olmadığını kontrol et
      final existingStats = data['stats'] as Map<String, dynamic>?;

      if (existingStats == null || existingStats.isEmpty) {
        // Stats objesi yok, eski field'lardan oluştur
        final stats = <String, dynamic>{
          'commentCount': data['commentCount'] ?? 0,
          'likeCount': data['likeCount'] ?? 0,
          'reportedCount': data['reportedCount'] ?? 0,
          'retryCount': data['retryCount'] ?? 0,
          'savedCount': data['savedCount'] ?? 0,
          'statsCount': data['statsCount'] ?? 0,
        };

        updates['stats'] = stats;
        print('Created stats object with values: $stats');
      } else {
        print('Stats object already exists, values: $existingStats');
      }

      // Eski field'ları sil (stats objesi var olsun ya da olmasın)
      if (data.containsKey('commentCount')) {
        updates['commentCount'] = FieldValue.delete();
      }
      if (data.containsKey('likeCount')) {
        updates['likeCount'] = FieldValue.delete();
      }
      if (data.containsKey('reportedCount')) {
        updates['reportedCount'] = FieldValue.delete();
      }
      if (data.containsKey('retryCount')) {
        updates['retryCount'] = FieldValue.delete();
      }
      if (data.containsKey('savedCount')) {
        updates['savedCount'] = FieldValue.delete();
      }
      if (data.containsKey('statsCount')) {
        updates['statsCount'] = FieldValue.delete();
      }
      if (data.containsKey('kayitEdenler')) {
        updates['kayitEdenler'] = FieldValue.delete();
      }

      // Eski sharedAsPost field'ını sil (artık kullanılmıyor)
      if (data.containsKey('sharedAsPost')) {
        updates['sharedAsPost'] = FieldValue.delete();
      }

      await _firestore.collection('Posts').doc(postId).update(updates);
      print('Post migrated successfully: $postId');

      return true;
    } catch (e) {
      print('Migration error for post $postId: $e');
      return false;
    }
  }

  /// Tüm postları batch'ler halinde migrate et
  static Future<void> migrateAllPosts({int batchSize = 50}) async {
    print('Starting migration of all posts...');

    Query query = _firestore.collection('Posts').limit(batchSize);
    DocumentSnapshot? lastDoc;

    int totalMigrated = 0;
    int totalFailed = 0;

    do {
      QuerySnapshot querySnapshot;
      if (lastDoc != null) {
        querySnapshot = await query.startAfterDocument(lastDoc).get();
      } else {
        querySnapshot = await query.get();
      }

      if (querySnapshot.docs.isEmpty) break;

      print('Processing batch of ${querySnapshot.docs.length} posts...');

      for (final doc in querySnapshot.docs) {
        final success = await migratePost(doc.id);
        if (success) {
          totalMigrated++;
        } else {
          totalFailed++;
        }

        // Rate limiting
        await Future.delayed(Duration(milliseconds: 100));
      }

      lastDoc = querySnapshot.docs.last;
      print('Batch completed. Migrated: $totalMigrated, Failed: $totalFailed');

      // Batch arası bekleme
      await Future.delayed(Duration(seconds: 1));

    } while (true);

    print('Migration completed. Total Migrated: $totalMigrated, Total Failed: $totalFailed');
  }

  /// Belirli kullanıcının postlarını migrate et
  static Future<void> migrateUserPosts(String userId) async {
    print('Migrating posts for user: $userId');

    final querySnapshot = await _firestore
        .collection('Posts')
        .where('userID', isEqualTo: userId)
        .get();

    print('Found ${querySnapshot.docs.length} posts for user: $userId');

    int migrated = 0;
    int failed = 0;

    for (final doc in querySnapshot.docs) {
      final success = await migratePost(doc.id);
      if (success) {
        migrated++;
      } else {
        failed++;
      }

      // Rate limiting
      await Future.delayed(Duration(milliseconds: 100));
    }

    print('User migration completed. Migrated: $migrated, Failed: $failed');
  }

  /// Migration'ın gerekli olup olmadığını kontrol et
  static Future<bool> needsMigration(String postId) async {
    try {
      final doc = await _firestore.collection('Posts').doc(postId).get();
      if (!doc.exists) return false;

      final data = doc.data()!;

      // Eski yapı field'ları varsa migration gerekiyor
      final hasOldFields = data.containsKey('kayitEdenler') ||
          data.containsKey('commentCount') ||
          data.containsKey('likeCount') ||
          data.containsKey('reportedCount') ||
          data.containsKey('retryCount') ||
          data.containsKey('savedCount') ||
          data.containsKey('statsCount') ||
          data.containsKey('sharedAsPost');

      final hasNoStats = !data.containsKey('stats');

      return hasOldFields || hasNoStats;
    } catch (e) {
      print('Migration check error: $e');
      return false;
    }
  }

  /// Migration progress'ini takip et
  static Future<Map<String, int>> getMigrationProgress() async {
    try {
      final allPosts = await _firestore.collection('Posts').get();
      int needsMigration = 0;
      int alreadyMigrated = 0;

      for (final doc in allPosts.docs) {
        final data = doc.data();
        if (data.containsKey('kayitEdenler') || !data.containsKey('stats')) {
          needsMigration++;
        } else {
          alreadyMigrated++;
        }
      }

      return {
        'total': allPosts.docs.length,
        'needsMigration': needsMigration,
        'alreadyMigrated': alreadyMigrated,
      };
    } catch (e) {
      print('Progress check error: $e');
      return {'total': 0, 'needsMigration': 0, 'alreadyMigrated': 0};
    }
  }
}

/// Migration'u başlatmak için helper fonksiyonlar
class MigrationRunner {
  static Future<void> runMigration() async {
    print('🚀 Starting Post Migration...');

    // İlk olarak progress kontrol et
    final progress = await PostMigrationHelper.getMigrationProgress();
    print('Migration Progress: ${progress.toString()}');

    if (progress['needsMigration']! > 0) {
      print('Starting migration for ${progress['needsMigration']} posts...');
      await PostMigrationHelper.migrateAllPosts();
    } else {
      print('All posts are already migrated! 🎉');
    }
  }

  /// Test için tek post migrate et
  static Future<void> testMigration(String postId) async {
    print('🧪 Testing migration for post: $postId');

    final needsMigration = await PostMigrationHelper.needsMigration(postId);
    print('Needs migration: $needsMigration');

    if (needsMigration) {
      final success = await PostMigrationHelper.migratePost(postId);
      print('Migration result: ${success ? 'SUCCESS' : 'FAILED'}');
    }
  }
}