/**
 * TurqApp — Aggregation Counter Sharding
 *
 * Problem: Tek bir Post belgesine saniyede binlerce view/like yazısı
 *          Firestore'u 1 write/s limiti nedeniyle kilitler → ContentionError
 *
 * Çözüm: Distributed Counter Pattern
 *   - Her post için N (= SHARD_COUNT) alt belge (shard)
 *   - Yazı: rastgele shard'a FieldValue.increment
 *   - Okuma: scheduled CF shard toplamlarını ana belgeye yazar (1/dk)
 *
 * Koleksiyon yapısı:
 *   Posts/{postId}/_counters/{0..N-1}   → { viewCount: n, likeCount: n }
 *
 * Avantaj:
 *   - N=5 → 5x throughput (5 write/s yerine 5x5=25 write/s)
 *   - Ana belge yalnızca scheduled agregasyon günceller → okuma tutarlı
 *   - Client SDK "firestore-counter" paketsiz, CF-only implementasyon
 */

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

const db = admin.firestore();

// Shard sayısı — arttırmak throughput'u artırır, agregasyon maliyetini de artırır
const SHARD_COUNT = 5;

// Desteklenen counter alanları
type CounterField = "goruntulenmeSayisi" | "begeniSayisi";

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// 📊 CALLABLE: Tek view kaydı (client'tan batched olarak çağrılır)
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

/**
 * recordViewBatch — client'tan toplu view kaydı.
 * Input: { items: Array<{ postId: string; count: number }> }
 * Güvenlik: max 50 item/çağrı, count 1–100 arası
 */
export const recordViewBatch = functions
  .region("europe-west1")
  .https.onCall(async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError("unauthenticated", "Auth required");
    }

    const items: Array<{ postId: string; count: number }> =
      Array.isArray(data?.items) ? data.items : [];

    if (items.length === 0 || items.length > 50) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "items: 1-50 arası"
      );
    }

    const batch = db.batch();

    for (const item of items) {
      const postId = String(item.postId ?? "").trim();
      const count = Math.max(1, Math.min(100, Number(item.count) || 1));
      if (!postId) continue;

      // Rastgele shard seç
      const shardIdx = Math.floor(Math.random() * SHARD_COUNT);
      const shardRef = db
        .collection("Posts")
        .doc(postId)
        .collection("_counters")
        .doc(String(shardIdx));

      batch.set(
        shardRef,
        { goruntulenmeSayisi: admin.firestore.FieldValue.increment(count) },
        { merge: true }
      );
    }

    await batch.commit();
    return { ok: true, processed: items.length };
  });

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// ⏱️ SCHEDULED: Shard toplamlarını her dakika ana belgeye yaz
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

/**
 * aggregateCounterShards — her dakika dirty shard'ları toplar.
 *
 * Strateji:
 *   1. Son 70 saniyede yazılan shard belgelerini sorgula (recentlyUpdated index)
 *   2. Her post için tüm shard toplamını hesapla
 *   3. Ana Posts belgesini batch update et, shard'ları sıfırla
 *
 * Not: Büyük ölçekte (>100K DAU) bu fonksiyon her post için shard
 *      okuma maliyeti taşır. Alternatif: sadece "dirty" shard'ları işle.
 */
export const aggregateCounterShards = functions
  .region("europe-west1")
  .pubsub.schedule("every 1 minutes")
  .onRun(async () => {
    const now = Date.now();
    const windowMs = 70 * 1000; // 70s — biraz fazla tutarak kesim kaçırma önlenir
    const cutoff = admin.firestore.Timestamp.fromMillis(now - windowMs);

    const fields: CounterField[] = ["goruntulenmeSayisi", "begeniSayisi"];

    // Dirty shard'ları bul (updatedAt son 70s içinde)
    const dirtySnaps = await db
      .collectionGroup("_counters")
      .where("updatedAt", ">=", cutoff)
      .limit(500)
      .get();

    if (dirtySnaps.empty) return null;

    // postId → { field → toplam }
    const totals = new Map<string, Record<CounterField, number>>();
    const shardRefs: admin.firestore.DocumentReference[] = [];

    for (const doc of dirtySnaps.docs) {
      // doc.ref.parent.parent = Posts/{postId}
      const postRef = doc.ref.parent.parent;
      if (!postRef) continue;
      const postId = postRef.id;

      if (!totals.has(postId)) {
        totals.set(postId, { goruntulenmeSayisi: 0, begeniSayisi: 0 });
      }
      const agg = totals.get(postId)!;
      const d = doc.data();
      for (const f of fields) {
        agg[f] += typeof d[f] === "number" ? d[f] : 0;
      }
      shardRefs.push(doc.ref);
    }

    // Batch: ana belgeye increment, shard'ları sıfırla
    // Firestore batch limiti 500 — büyük sonuçlar için chunk'la
    const BATCH_LIMIT = 250; // 2 op/shard (increment + reset) → 250 shard = 500 op
    const chunks: admin.firestore.DocumentReference[][] = [];
    for (let i = 0; i < shardRefs.length; i += BATCH_LIMIT) {
      chunks.push(shardRefs.slice(i, i + BATCH_LIMIT));
    }

    for (const chunk of chunks) {
      const wb = db.batch();
      const processedPostIds = new Set<string>();

      for (const shardRef of chunk) {
        const postId = shardRef.parent.parent!.id;
        const postRef = db.collection("Posts").doc(postId);
        const agg = totals.get(postId);
        if (!agg) continue;

        // Sadece ilk shard işlendiğinde ana belgeyi güncelle
        if (!processedPostIds.has(postId)) {
          processedPostIds.add(postId);
          const update: Record<string, admin.firestore.FieldValue> = {};
          for (const f of fields) {
            if (agg[f] > 0) {
              update[f] = admin.firestore.FieldValue.increment(agg[f]);
            }
          }
          if (Object.keys(update).length > 0) {
            wb.update(postRef, update);
          }
        }

        // Shard'ı sıfırla + updatedAt damgasını kaldır
        const reset: Record<string, number | admin.firestore.FieldValue> = {};
        for (const f of fields) {
          reset[f] = 0;
        }
        reset.updatedAt = admin.firestore.FieldValue.delete() as any;
        wb.set(shardRef, reset, { merge: true });
      }

      await wb.commit();
    }

    console.log(
      `aggregateCounterShards: ${totals.size} post güncellendi, ${shardRefs.length} shard sıfırlandı`
    );
    return null;
  });

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// 🛠️ HELPER: Shard başlatma (post oluşturulduğunda çağrılır)
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

/**
 * initCounterShards — yeni post oluşturulduğunda shard belgelerini başlat.
 * Firestore trigger: Posts/{postId} onCreate
 */
export const initCounterShards = functions
  .region("europe-west1")
  .firestore.document("Posts/{postId}")
  .onCreate(async (snap) => {
    const batch = db.batch();
    for (let i = 0; i < SHARD_COUNT; i++) {
      const shardRef = snap.ref.collection("_counters").doc(String(i));
      batch.set(shardRef, { goruntulenmeSayisi: 0, begeniSayisi: 0 });
    }
    await batch.commit();
  });
