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
 * Storage trigger: posts/{docID}/video.mp4 yüklendiğinde tetiklenir.
 * Video'yu HLS formatına dönüştürür ve Firestore'u günceller.
 */
export const onVideoUpload = functions
  .runWith({ memory: "2GB", timeoutSeconds: 540 })
  .storage.object()
  .onFinalize(async (object) => {
    const filePath = object.name;
    if (!filePath) return;

    // Sadece posts/{docID}/video*.mp4 dosyalarını işle
    const match = filePath.match(/^posts\/([^/]+)\/video[^/]*\.mp4$/i);
    if (!match) return;

    const docID = match[1];
    const bucket = storage.bucket(object.bucket);

    console.log(`[HLS] Processing video for post: ${docID}`);

    // Firestore'da processing durumunu set et.
    // Not: Bazı akışlarda video upload, post dokümanından önce gelebilir.
    // update() NOT_FOUND verir; merge set ile race condition kırılır.
    await db.doc(`Posts/${docID}`).set(
      {
        hlsStatus: "processing",
        isUploading: true,
        hlsUpdatedAt: Date.now(),
      },
      { merge: true }
    );

    try {
      // Segment konfigürasyonu oku
      const configSnap = await db.doc("adminConfig/hlsSegment").get();
      const segment1 = clampSegment(configSnap.data()?.segment1, 2);
      const segment2 = clampSegment(configSnap.data()?.segment2, 6);

      console.log(
        `[HLS] Segment config: first=${segment1}s, rest=${segment2}s`
      );

      // Temp dizini oluştur
      const tempDir = path.join(os.tmpdir(), `hls_${docID}`);
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
      const hlsSegmentCount = hlsFiles.filter((file) =>
        file.startsWith("seg_") && file.endsWith(".ts")
      ).length;
      const uploadPromises = hlsFiles.map((file) => {
        const localPath = path.join(outputDir, file);
        const remotePath = `Posts/${docID}/hls/${file}`;
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

      // Thumbnail üret (1. saniyeden frame)
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
          destination: `Posts/${docID}/thumbnail.jpg`,
          metadata: { contentType: "image/jpeg" },
        });
      } catch (thumbErr) {
        console.warn(`[HLS] Thumbnail generation failed: ${thumbErr}`);
      }

      // Firestore güncelle
      const hlsUrl = `https://${CDN_DOMAIN}/Posts/${docID}/hls/master.m3u8`;
      const thumbnailUrl = `https://${CDN_DOMAIN}/Posts/${docID}/thumbnail.jpg`;

      await db.doc(`Posts/${docID}`).set(
        {
          hlsMasterUrl: hlsUrl,
          hlsSegmentCount,
          hlsStatus: "ready",
          isUploading: false,
          hlsUpdatedAt: Date.now(),
          video: hlsUrl,
          thumbnail: thumbnailUrl,
        },
        { merge: true }
      );

      console.log(`[HLS] Complete for ${docID}. HLS URL: ${hlsUrl}`);

      // Temp dosyaları temizle
      fs.rmSync(tempDir, { recursive: true, force: true });
    } catch (error) {
      console.error(`[HLS] Error processing ${docID}:`, error);

      await db.doc(`Posts/${docID}`).set(
        {
          hlsStatus: "failed",
          isUploading: false,
          hlsUpdatedAt: Date.now(),
        },
        { merge: true }
      );

      // Temp temizle
      const tempDir = path.join(os.tmpdir(), `hls_${docID}`);
      if (fs.existsSync(tempDir)) {
        fs.rmSync(tempDir, { recursive: true, force: true });
      }
    }
  });
