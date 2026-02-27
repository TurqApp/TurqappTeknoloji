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

/**
 * Video tipi bilgisi: path pattern'e göre belirlenir.
 */
interface VideoTarget {
  type: "post" | "chat" | "story";
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

  // Pattern 2: Chat mesaj videosu
  const chatMatch = filePath.match(
    /^ChatAssets\/([^/]+)\/messages\/([^/]+)\/video\.mp4$/i
  );
  if (chatMatch) {
    const chatID = chatMatch[1];
    const msgID = chatMatch[2];
    return {
      type: "chat",
      id: `chat_${chatID}_${msgID}`,
      hlsOutputPrefix: `ChatAssets/${chatID}/messages/${msgID}/hls`,
      firestoreDoc: `conversations/${chatID}/messages/${msgID}`,
      generateThumbnail: false,
      buildProcessingData: () => ({
        hlsStatus: "processing",
      }),
      buildSuccessData: (hlsUrl) => ({
        videoUrl: hlsUrl,
        hlsMasterUrl: hlsUrl,
        hlsStatus: "ready",
      }),
      buildFailData: () => ({
        hlsStatus: "failed",
      }),
    };
  }

  // Pattern 3: Story videosu
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

    console.log(
      `[HLS] Processing video for ${target.type}: ${target.id}`
    );

    // Firestore'da processing durumunu set et.
    await db.doc(target.firestoreDoc).set(
      target.buildProcessingData(),
      { merge: true }
    );

    const tempDir = path.join(os.tmpdir(), `hls_${target.id}`);

    try {
      // Segment konfigürasyonu oku
      const configSnap = await db.doc("adminConfig/hlsSegment").get();
      const segment1 = clampSegment(configSnap.data()?.segment1, 2);
      const segment2 = clampSegment(configSnap.data()?.segment2, 6);

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

      const durationSeconds = await getVideoDurationSeconds(inputPath);
      const forceKeyFrames = buildForceKeyFrames(
        durationSeconds,
        segment1,
        segment2
      );
      console.log(
        `[HLS] duration=${durationSeconds.toFixed(
          2
        )}s, forced_keyframes=${forceKeyFrames || "none"}`
      );

      // ffmpeg ile HLS üret
      const masterPlaylist = path.join(outputDir, "master.m3u8");

      console.log(`[HLS] Starting ffmpeg transcode...`);
      const ffmpegArgs = [
        "-i",
        inputPath,
        "-c:v",
        "libx264",
        "-pix_fmt",
        "yuv420p",
        "-profile:v",
        "main",
        "-level:v",
        "4.1",
        "-flags",
        "+cgop",
        "-preset",
        "fast",
        "-crf",
        "23",
        "-r",
        "30",
        "-c:a",
        "aac",
        "-profile:a",
        "aac_low",
        "-ar",
        "48000",
        "-b:a",
        "128k",
        "-g",
        String(segment2 * 30), // GOP size = segment duration * fps
        "-keyint_min",
        String(segment2 * 30),
        "-sc_threshold",
        "0",
        "-x264-params",
        `keyint=${segment2 * 30}:min-keyint=${
          segment2 * 30
        }:scenecut=0:open-gop=0:repeat-headers=1`,
        "-bsf:v",
        "h264_mp4toannexb",
        ...(forceKeyFrames ? ["-force_key_frames", forceKeyFrames] : []),
        "-start_number",
        "0",
        "-hls_init_time",
        String(segment1),
        "-hls_time",
        String(segment2),
        "-hls_list_size",
        "0",
        "-hls_playlist_type",
        "vod",
        "-hls_flags",
        "independent_segments+temp_file",
        "-hls_segment_type",
        "mpegts",
        "-mpegts_flags",
        "+resend_headers",
        "-muxpreload",
        "0",
        "-muxdelay",
        "0",
        "-max_muxing_queue_size",
        "2048",
        "-hls_segment_filename",
        path.join(outputDir, "seg_%03d.ts"),
        "-f",
        "hls",
        masterPlaylist,
      ];
      await execFileAsync("ffmpeg", ffmpegArgs);

      console.log(`[HLS] Transcode complete. Uploading HLS files...`);

      // HLS dosyalarını Storage'a yükle
      const hlsFiles = fs.readdirSync(outputDir);
      const hlsSegmentCount = hlsFiles.filter(
        (file) => file.startsWith("seg_") && file.endsWith(".ts")
      ).length;
      const uploadPromises = hlsFiles.map((file) => {
        const localPath = path.join(outputDir, file);
        const remotePath = `${target.hlsOutputPrefix}/${file}`;
        return bucket.upload(localPath, {
          destination: remotePath,
          metadata: {
            contentType: file.endsWith(".m3u8")
              ? "application/vnd.apple.mpegurl"
              : "video/mp2t",
          },
        });
      });
      await Promise.all(uploadPromises);

      // Thumbnail üret (sadece post tipi için)
      let thumbnailUrl = "";
      if (target.generateThumbnail && target.thumbnailStoragePath) {
        const thumbnailPath = path.join(tempDir, "thumbnail.jpg");
        try {
          await execFileAsync("ffmpeg", [
            "-i",
            inputPath,
            "-ss",
            "1",
            "-vframes",
            "1",
            "-q:v",
            "2",
            thumbnailPath,
          ]);

          await bucket.upload(thumbnailPath, {
            destination: target.thumbnailStoragePath,
            metadata: { contentType: "image/jpeg" },
          });
          thumbnailUrl = `https://${CDN_DOMAIN}/${target.thumbnailStoragePath}`;
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

      console.log(
        `[HLS] Complete for ${target.type}:${target.id}. HLS URL: ${hlsUrl}`
      );

      // Story için orijinal video dosyasını tutma: HLS hazır olduktan sonra sil.
      if (target.type === "story") {
        try {
          await bucket.file(filePath).delete({ ignoreNotFound: true });
          console.log(`[HLS] Story source deleted: ${filePath}`);
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
