import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { execFile } from "child_process";
import { promisify } from "util";
import * as path from "path";
import * as os from "os";
import * as fs from "fs";

const execFileAsync = promisify(execFile);

const db = admin.firestore();
const storage = admin.storage();

const CDN_DOMAIN = "cdn.turqapp.com";

const TURQ_CLEAN_VISION = Object.freeze({
  brightness: 0.05,
  contrast: 0.88,
  saturation: 1.06,
  gamma: 1.06,
  sharpenAmount: 0.65,
  bloomOpacity: 0.20,
  bloomSigma: 7,
});

const clampSegment = (value: unknown, fallback: number): number => {
  const n = Number(value);
  if (!Number.isFinite(n) || n <= 0) return fallback;
  return Math.max(1, Math.floor(n));
};

const getVideoDurationSeconds = async (inputPath: string): Promise<number> => {
  const { stdout } = await execFileAsync("ffprobe", [
    "-v",
    "error",
    "-show_entries",
    "format=duration",
    "-of",
    "default=noprint_wrappers=1:nokey=1",
    inputPath,
  ]);

  const duration = Number(String(stdout).trim());
  if (!Number.isFinite(duration) || duration <= 0) {
    throw new Error(`[HLS] Invalid video duration from ffprobe: ${stdout}`);
  }
  return duration;
};

// B2: Gerçek video FPS'ini tespit et — GOP hesabında 30fps varsayımı yerine
const getVideoFPS = async (inputPath: string): Promise<number> => {
  try {
    const { stdout } = await execFileAsync("ffprobe", [
      "-v", "error",
      "-select_streams", "v:0",
      "-show_entries", "stream=r_frame_rate",
      "-of", "default=noprint_wrappers=1:nokey=1",
      inputPath,
    ]);
    // Çıktı "30000/1001" gibi olabilir (NTSC) → eval et
    const raw = String(stdout).trim().split("\n")[0];
    const parts = raw.split("/");
    if (parts.length === 2) {
      const fps = Number(parts[0]) / Number(parts[1]);
      if (Number.isFinite(fps) && fps > 0 && fps <= 120) return Math.round(fps);
    }
    const fps = Number(raw);
    if (Number.isFinite(fps) && fps > 0 && fps <= 120) return Math.round(fps);
  } catch (_) {}
  return 30; // Güvenli varsayılan
};

const buildForceKeyFrames = (
  durationSeconds: number,
  firstSegmentSeconds: number,
  restSegmentSeconds: number
): string => {
  const marks: string[] = [];
  const epsilon = 0.25;

  for (
    let t = firstSegmentSeconds;
    t < durationSeconds - epsilon;
    t += restSegmentSeconds
  ) {
    marks.push(t.toFixed(3));
  }

  return marks.join(",");
};

const buildTurqCleanVisionFilterComplex = (
  renditionLabel: string,
  scaleFilter: string
): string => {
  const baseLabel = `${renditionLabel}base`;
  const bloomSourceLabel = `${renditionLabel}bloomsrc`;
  const bloomLabel = `${renditionLabel}bloom`;
  const outputLabel = `${renditionLabel}out`;

  const baseChain = [
    scaleFilter,
    `eq=brightness=${TURQ_CLEAN_VISION.brightness}:contrast=${TURQ_CLEAN_VISION.contrast}:saturation=${TURQ_CLEAN_VISION.saturation}:gamma=${TURQ_CLEAN_VISION.gamma}`,
    "curves=all='0/0.04 0.22/0.30 0.58/0.75 0.84/0.95 1/1'",
    "colorbalance=rs=-0.01:bs=0.02",
    `unsharp=5:5:${TURQ_CLEAN_VISION.sharpenAmount}:3:3:0.0`,
  ].join(",");

  const bloomIsolation = [
    "curves=all='0/0 0.70/0 0.80/0.42 0.90/0.82 1/1'",
    `gblur=sigma=${TURQ_CLEAN_VISION.bloomSigma}:steps=1`,
  ].join(",");

  return [
    `[0:v]${baseChain},split=2[${baseLabel}][${bloomSourceLabel}]`,
    `[${bloomSourceLabel}]${bloomIsolation}[${bloomLabel}]`,
    `[${baseLabel}][${bloomLabel}]blend=all_mode='screen':all_opacity=${TURQ_CLEAN_VISION.bloomOpacity}[${outputLabel}]`,
  ].join(";");
};

const buildTurqCleanVisionThumbnailFilter = (): string =>
  [
    `eq=brightness=${TURQ_CLEAN_VISION.brightness}:contrast=${TURQ_CLEAN_VISION.contrast}:saturation=${TURQ_CLEAN_VISION.saturation}:gamma=${TURQ_CLEAN_VISION.gamma}`,
    "curves=all='0/0 0.28/0.33 0.62/0.78 0.82/0.94 1/1'",
    "colorbalance=rs=-0.01:bs=0.02",
    `unsharp=5:5:${TURQ_CLEAN_VISION.sharpenAmount}:3:3:0.0`,
  ].join(",");

/**
 * Video tipi bilgisi: path pattern'e göre belirlenir.
 */
interface VideoTarget {
  type: "post" | "story";
  /** Temp dizin ve log için kullanılan benzersiz ID */
  id: string;
  /** HLS dosyalarının Storage'daki hedef dizini */
  hlsOutputPrefix: string;
  /** Firestore doküman yolu */
  firestoreDoc: string;
  /** Firestore'a yazılacak tamamlanma verileri */
  buildSuccessData: (hlsUrl: string, hlsSegmentCount: number, thumbnailUrl: string) => Record<string, unknown>;
  /** Firestore'a yazılacak hata verileri */
  buildFailData: () => Record<string, unknown>;
  /** Firestore'a yazılacak processing verileri */
  buildProcessingData: () => Record<string, unknown>;
  /** Thumbnail üretilip Storage'a yüklensin mi? */
  generateThumbnail: boolean;
  /** Thumbnail Storage yolu (generateThumbnail true ise) */
  thumbnailStoragePath?: string;
  /** Story tipi için uid */
  storyUid?: string;
  /** Story tipi için story id */
  storyId?: string;
}

function resolveTarget(filePath: string): VideoTarget | null {
  // Pattern 1: Posts (mevcut)
  const postMatch = filePath.match(/^posts\/([^/]+)\/video[^/]*\.mp4$/i);
  if (postMatch) {
    const docID = postMatch[1];
    return {
      type: "post",
      id: docID,
      hlsOutputPrefix: `Posts/${docID}/hls`,
      firestoreDoc: `Posts/${docID}`,
      generateThumbnail: true,
      thumbnailStoragePath: `Posts/${docID}/thumbnail.jpg`,
      buildProcessingData: () => ({
        hlsStatus: "processing",
        isUploading: true,
        hlsUpdatedAt: Date.now(),
      }),
      buildSuccessData: (hlsUrl, hlsSegmentCount, thumbnailUrl) => ({
        hlsMasterUrl: hlsUrl,
        hlsSegmentCount,
        hlsStatus: "ready",
        isUploading: false,
        hlsUpdatedAt: Date.now(),
        video: hlsUrl,
        thumbnail: thumbnailUrl,
      }),
      buildFailData: () => ({
        hlsStatus: "failed",
        isUploading: false,
        hlsUpdatedAt: Date.now(),
      }),
    };
  }

  // Pattern 2: Story videosu
  const storyMatch = filePath.match(
    /^stories\/([^/]+)\/([^/]+)\/[^/]+\.(mp4|mov|m4v|webm)$/i
  );
  if (storyMatch) {
    const uid = storyMatch[1];
    const storyID = storyMatch[2];
    return {
      type: "story",
      id: `story_${storyID}`,
      hlsOutputPrefix: `stories/${uid}/${storyID}/hls`,
      firestoreDoc: `stories/${storyID}`,
      storyUid: uid,
      storyId: storyID,
      generateThumbnail: false,
      buildProcessingData: () => ({
        hlsStatus: "processing",
      }),
      buildSuccessData: (hlsUrl) => ({
        hlsVideoUrl: hlsUrl,
        hlsStatus: "ready",
      }),
      buildFailData: () => ({
        hlsStatus: "failed",
      }),
    };
  }

  return null;
}

/**
 * Storage trigger: video yüklendiğinde tetiklenir.
 * Posts, Chat mesajları ve Story videoları için HLS dönüşümü yapar.
 */
export const onVideoUpload = functions
  .runWith({ memory: "2GB", timeoutSeconds: 540 })
  .storage.object()
  .onFinalize(async (object) => {
    const filePath = object.name;
    if (!filePath) return;

    const target = resolveTarget(filePath);
    if (!target) return;

    const bucket = storage.bucket(object.bucket);

    console.log(`[HLS] Processing video for ${target.type}`);

    // Firestore'da processing durumunu set et.
    await db.doc(target.firestoreDoc).set(
      target.buildProcessingData(),
      { merge: true }
    );

    const tempDir = path.join(os.tmpdir(), `hls_${target.id}`);

    try {
      // Segment konfigürasyonu oku
      // B2: segment1 (ilk segment) varsayılanı 2→1 → daha hızlı TTFF
      // Not: adminConfig/hlsSegment.segment1 override edebilir (0 deploy gerek yok)
      const configSnap = await db.doc("adminConfig/hlsSegment").get();
      const segment1 = clampSegment(configSnap.data()?.segment1, 1); // B2: 2→1
      const segment2 = clampSegment(configSnap.data()?.segment2, 2);

      console.log(
        `[HLS] Segment config: first=${segment1}s, rest=${segment2}s`
      );

      // Temp dizini oluştur
      fs.mkdirSync(tempDir, { recursive: true });

      const inputPath = path.join(tempDir, "input.mp4");
      const outputDir = path.join(tempDir, "hls");
      fs.mkdirSync(outputDir, { recursive: true });

      // Video'yu indir
      console.log(`[HLS] Downloading video...`);
      await bucket.file(filePath).download({ destination: inputPath });

      // B2: FPS tespiti ve duration paralel al
      const [durationSeconds, videoFPS] = await Promise.all([
        getVideoDurationSeconds(inputPath),
        getVideoFPS(inputPath),
      ]);
      const forceKeyFrames = buildForceKeyFrames(
        durationSeconds,
        segment1,
        segment2
      );
      console.log(
        `[HLS] duration=${durationSeconds.toFixed(2)}s, fps=${videoFPS}, forced_keyframes=${forceKeyFrames || "none"}`
      );

      // ABR multi-rendition ladder
      // Kaynak çözünürlüğünü al
      const probeResult = await execFileAsync("ffprobe", [
        "-v", "error",
        "-select_streams", "v:0",
        "-show_entries", "stream=width,height",
        "-of", "csv=p=0",
        inputPath,
      ]);
      const [srcW, srcH] = String(probeResult.stdout).trim().split(",").map(Number);
      const srcHeight = Math.max(srcW || 0, srcH || 0) > 0 ? Math.min(srcW || 720, srcH || 720) : 720;
      // Eğer kaynak dikey (portrait) ise width'i baz al
      const isPortrait = (srcH || 0) > (srcW || 0);
      const srcShortSide = isPortrait ? (srcW || 720) : (srcH || 720);

      // B2: ABR ladder — 1080p rendition eklendi, bufsize 2x bitrate (daha sıkı ABR)
      // bufsize = 2x bitrate → ABR geçiş tepkisi iyileşir
      const renditions = [
        { height: 360,  bitrate: 800,  maxrate: 856,  bufsize: 1600,  label: "360p"  },
        { height: 480,  bitrate: 1400, maxrate: 1498, bufsize: 2800,  label: "480p"  },
        { height: 720,  bitrate: 2800, maxrate: 2996, bufsize: 5600,  label: "720p"  },
        { height: 1080, bitrate: 5000, maxrate: 5350, bufsize: 10000, label: "1080p" },
      ].filter((r) => r.height <= srcShortSide + 50); // +50 tolerans

      // Kaynak çok düşükse en az 1 rendition olsun
      if (renditions.length === 0) {
        renditions.push({ height: 360, bitrate: 800, maxrate: 856, bufsize: 1600, label: "360p" });
      }

      // B2: Gerçek FPS kullan — GOP = segment_duration × actual_fps
      const gopSize = Math.round(segment2 * videoFPS);
      const masterPlaylist = path.join(outputDir, "master.m3u8");

      console.log(`[HLS] Starting ABR transcode (${renditions.map(r => r.label).join(", ")})...`);

      // Her rendition için ayrı dizin oluştur
      for (const r of renditions) {
        fs.mkdirSync(path.join(outputDir, r.label), { recursive: true });
      }

      // ffmpeg multi-output ABR encoding
      const ffmpegArgs = ["-i", inputPath];
      const filterComplexParts: string[] = [];
      const outputArgs: string[] = [];

      for (let i = 0; i < renditions.length; i++) {
        const r = renditions[i];
        const scale = isPortrait
          ? `scale=${r.height}:-2:flags=lanczos`
          : `scale=-2:${r.height}:flags=lanczos`;
        const renditionLabel = `r${i}`;
        filterComplexParts.push(
          buildTurqCleanVisionFilterComplex(renditionLabel, scale)
        );
        outputArgs.push(
          "-map", `[${renditionLabel}out]`, "-map", "0:a:0?",
          `-c:v:${i}`, "libx264",
          `-b:v:${i}`, `${r.bitrate}k`,
          `-maxrate:v:${i}`, `${r.maxrate}k`,
          `-bufsize:v:${i}`, `${r.bufsize}k`,
          `-pix_fmt`, "yuv420p",
          `-profile:v:${i}`, "main",
          `-preset`, "fast",
          `-g:v:${i}`, String(gopSize),
          `-keyint_min:v:${i}`, String(gopSize),
          `-sc_threshold:v:${i}`, "0",
          `-c:a:${i}`, "aac",
          `-b:a:${i}`, "128k",
          `-ar:${i}`, "48000",
        );
      }

      ffmpegArgs.push("-filter_complex", filterComplexParts.join(";"));
      ffmpegArgs.push(...outputArgs);

      // forceKeyFrames tüm stream'lere
      if (forceKeyFrames) {
        ffmpegArgs.push("-force_key_frames", forceKeyFrames);
      }

      // HLS muxer ayarları
      const varStreamMap = renditions
        .map((_, i) => `v:${i},a:${i}`)
        .join(" ");

      ffmpegArgs.push(
        "-f", "hls",
        "-hls_time", String(segment2),
        "-hls_init_time", String(segment1),
        "-hls_list_size", "0",
        "-hls_playlist_type", "vod",
        "-hls_flags", "independent_segments+temp_file",
        "-hls_segment_type", "mpegts",
        "-master_pl_name", "master.m3u8",
        "-var_stream_map", varStreamMap,
        "-hls_segment_filename", path.join(outputDir, "%v/seg_%03d.ts"),
        path.join(outputDir, "%v/playlist.m3u8"),
      );

      await execFileAsync("ffmpeg", ffmpegArgs, { maxBuffer: 50 * 1024 * 1024 });

      console.log(`[HLS] Transcode complete. Uploading HLS files...`);

      // HLS dosyalarını Storage'a yükle (nested rendition dizinleri dahil)
      const uploadPromises: Promise<unknown>[] = [];
      let hlsSegmentCount = 0;

      const walkDir = (dir: string, prefix: string) => {
        for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
          if (entry.isDirectory()) {
            walkDir(path.join(dir, entry.name), `${prefix}${entry.name}/`);
          } else {
            const localPath = path.join(dir, entry.name);
            const remotePath = `${target.hlsOutputPrefix}/${prefix}${entry.name}`;
            const isPlaylist = entry.name.endsWith(".m3u8");
            const isMaster = entry.name === "master.m3u8";
            if (entry.name.endsWith(".ts")) hlsSegmentCount++;

            // Segmentler immutable → uzun cache. Master playlist kısa cache (ABR switch).
            const cacheControl = isPlaylist
              ? isMaster
                ? "public, max-age=300, s-maxage=300"
                : "public, max-age=86400, s-maxage=86400"
              : "public, max-age=31536000, s-maxage=31536000, immutable";

            uploadPromises.push(
              bucket.upload(localPath, {
                destination: remotePath,
                metadata: {
                  contentType: isPlaylist
                    ? "application/vnd.apple.mpegurl"
                    : "video/mp2t",
                  cacheControl,
                },
              })
            );
          }
        }
      };
      walkDir(outputDir, "");
      await Promise.all(uploadPromises);

      // Thumbnail üret (sadece post tipi için)
      // B9: WebP + JPEG çift format — tarayıcı/istemci desteğine göre seç
      let thumbnailUrl = "";
      if (target.generateThumbnail && target.thumbnailStoragePath) {
        const thumbnailJpgPath = path.join(tempDir, "thumbnail.jpg");
        const thumbnailWebpPath = path.join(tempDir, "thumbnail.webp");
        const thumbnailWebpStoragePath = target.thumbnailStoragePath.replace(
          /\.(jpg|jpeg)$/i,
          ".webp"
        );
        try {
          // JPEG thumbnail (geri uyumluluk)
          await execFileAsync("ffmpeg", [
            "-i", inputPath,
            "-ss", "1",
            "-vframes", "1",
            "-vf", buildTurqCleanVisionThumbnailFilter(),
            "-q:v", "2",
            thumbnailJpgPath,
          ]);

          // B9: WebP thumbnail — JPEG'den dönüştür (ffmpeg + libwebp veya sharp)
          await execFileAsync("ffmpeg", [
            "-i", thumbnailJpgPath,
            "-c:v", "libwebp",
            "-quality", "82",    // JPEG 85 eşdeğeri kalite
            "-preset", "photo",
            "-y",
            thumbnailWebpPath,
          ]);

          // Her iki formatı paralel yükle
          const [jpgResult] = await Promise.all([
            bucket.upload(thumbnailJpgPath, {
              destination: target.thumbnailStoragePath,
              metadata: {
                contentType: "image/jpeg",
                cacheControl: "public, max-age=86400, s-maxage=86400",
              },
            }),
            // WebP thumbnail (istemciler Accept: image/webp ile tercih edebilir)
            bucket.upload(thumbnailWebpPath, {
              destination: thumbnailWebpStoragePath,
              metadata: {
                contentType: "image/webp",
                cacheControl: "public, max-age=86400, s-maxage=86400",
              },
            }).catch((e: unknown) => console.warn("[HLS] WebP thumbnail upload failed (non-fatal):", e)),
          ]);

          thumbnailUrl = `https://${CDN_DOMAIN}/${target.thumbnailStoragePath}`;
          console.log(`[HLS] Thumbnails uploaded: JPEG + WebP`);
        } catch (thumbErr) {
          console.warn(`[HLS] Thumbnail generation failed: ${thumbErr}`);
        }
      }

      // Firestore güncelle
      const hlsUrl = `https://${CDN_DOMAIN}/${target.hlsOutputPrefix}/master.m3u8`;

      await db.doc(target.firestoreDoc).set(
        target.buildSuccessData(hlsUrl, hlsSegmentCount, thumbnailUrl),
        { merge: true }
      );

      // Story'de ilgili video element URL'sini HLS master URL'e çevir.
      // Böylece dokümanda MP4 URL kalmaz.
      if (target.type === "story" && target.storyUid && target.storyId) {
        try {
          const sourceFileName = path.posix.basename(filePath).toLowerCase();
          const storyPathNeedle =
            `/stories/${target.storyUid}/${target.storyId}/`.toLowerCase();
          const storySnap = await db.doc(target.firestoreDoc).get();
          const data = storySnap.data() as { elements?: unknown } | undefined;
          const elements = Array.isArray(data?.elements) ? data?.elements : [];

          let changed = false;
          const updated = elements.map((raw) => {
            if (!raw || typeof raw !== "object") return raw;
            const e = raw as Record<string, unknown>;
            const type = String(e.type || "").toLowerCase();
            const content = String(e.content || "");
            if (type !== "video" || !content) return raw;

            const lcContent = content.toLowerCase();
            if (
              lcContent.includes(storyPathNeedle) &&
              lcContent.includes(sourceFileName)
            ) {
              changed = true;
              return { ...e, content: hlsUrl };
            }
            return raw;
          });

          if (changed) {
            await db.doc(target.firestoreDoc).set(
              {
                elements: updated,
              },
              { merge: true }
            );
          }
        } catch (storyPatchErr) {
          console.warn(
            `[HLS] Story element URL patch failed (ignored): ${storyPatchErr}`
          );
        }
      }

      console.log(`[HLS] Complete for ${target.type}`);

      // Story için orijinal video dosyasını tutma: HLS hazır olduktan sonra sil.
      if (target.type === "story") {
        try {
          await bucket.file(filePath).delete({ ignoreNotFound: true });
          console.log("[HLS] Story source deleted");
        } catch (deleteErr) {
          console.warn(
            `[HLS] Story source delete failed (ignored): ${deleteErr}`
          );
        }
      }

      // Temp dosyaları temizle
      fs.rmSync(tempDir, { recursive: true, force: true });
    } catch (error) {
      console.error(
        `[HLS] Error processing ${target.type}:${target.id}:`,
        error
      );

      await db.doc(target.firestoreDoc).set(
        target.buildFailData(),
        { merge: true }
      );

      // Temp temizle
      if (fs.existsSync(tempDir)) {
        fs.rmSync(tempDir, { recursive: true, force: true });
      }
    }
  });
