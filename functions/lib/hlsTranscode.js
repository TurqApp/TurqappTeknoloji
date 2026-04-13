"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.onVideoUpload = void 0;
const functions = require("firebase-functions");
const admin = require("firebase-admin");
const child_process_1 = require("child_process");
const util_1 = require("util");
const path = require("path");
const os = require("os");
const fs = require("fs");
const execFileAsync = (0, util_1.promisify)(child_process_1.execFile);
if (admin.apps.length === 0) {
    admin.initializeApp();
}
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
const clampSegment = (value, fallback) => {
    const n = Number(value);
    if (!Number.isFinite(n) || n <= 0)
        return fallback;
    return Math.max(1, Math.floor(n));
};
const clampEvenDimension = (value, fallback) => {
    const n = Number(value);
    const base = Number.isFinite(n) && n > 0 ? Math.floor(n) : fallback;
    const safe = Math.max(2, base);
    return safe % 2 === 0 ? safe : safe - 1;
};
const getVideoDurationSeconds = async (inputPath) => {
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
const getVideoFPS = async (inputPath) => {
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
            if (Number.isFinite(fps) && fps > 0 && fps <= 120)
                return Math.round(fps);
        }
        const fps = Number(raw);
        if (Number.isFinite(fps) && fps > 0 && fps <= 120)
            return Math.round(fps);
    }
    catch (_) { }
    return 30; // Güvenli varsayılan
};
const hasAudioStream = async (inputPath) => {
    try {
        const { stdout } = await execFileAsync("ffprobe", [
            "-v",
            "error",
            "-select_streams",
            "a:0",
            "-show_entries",
            "stream=index",
            "-of",
            "default=noprint_wrappers=1:nokey=1",
            inputPath,
        ]);
        return String(stdout).trim().length > 0;
    }
    catch (_) {
        return false;
    }
};
const buildForceKeyFrames = (durationSeconds, firstSegmentSeconds, restSegmentSeconds) => {
    const marks = [];
    const epsilon = 0.25;
    for (let t = firstSegmentSeconds; t < durationSeconds - epsilon; t += restSegmentSeconds) {
        marks.push(t.toFixed(3));
    }
    return marks.join(",");
};
const buildTurqCleanVisionFilterComplex = (renditionLabel, scaleFilter) => {
    const outputLabel = `${renditionLabel}out`;
    return `[0:v]${scaleFilter}[${outputLabel}]`;
};
function resolveTarget(filePath) {
    // Pattern 1: Posts (mevcut)
    const postMatch = filePath.match(/^posts\/([^/]+)\/video[^/]*\.mp4$/i);
    if (postMatch) {
        const docID = postMatch[1];
        return {
            type: "post",
            id: docID,
            hlsOutputPrefix: `Posts/${docID}/hls`,
            firestoreDoc: `Posts/${docID}`,
            buildProcessingData: () => ({
                hlsStatus: "processing",
                isUploading: true,
                hlsUpdatedAt: Date.now(),
            }),
            buildSuccessData: (hlsUrl, hlsSegmentCount) => ({
                hlsMasterUrl: hlsUrl,
                hlsSegmentCount,
                hlsStatus: "ready",
                isUploading: false,
                hlsUpdatedAt: Date.now(),
                video: hlsUrl,
            }),
            buildFailData: () => ({
                hlsStatus: "failed",
                isUploading: false,
                hlsUpdatedAt: Date.now(),
            }),
        };
    }
    // Pattern 2: Story videosu
    const storyMatch = filePath.match(/^stories\/([^/]+)\/([^/]+)\/[^/]+\.(mp4|mov|m4v|webm)$/i);
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
exports.onVideoUpload = functions
    .runWith({ memory: "2GB", timeoutSeconds: 540 })
    .storage.object()
    .onFinalize(async (object) => {
    const filePath = object.name;
    if (!filePath)
        return;
    const target = resolveTarget(filePath);
    if (!target)
        return;
    const bucket = storage.bucket(object.bucket);
    const migrationMode = target.type === "post" &&
        String(object.metadata?.migrationMode || "").toLowerCase() === "true";
    console.log(`[HLS] Processing video for ${target.type}`);
    if (migrationMode) {
        console.log("[HLS] Migration mode enabled: Firestore writes disabled");
    }
    // Firestore'da processing durumunu set et.
    if (!migrationMode) {
        await db.doc(target.firestoreDoc).set(target.buildProcessingData(), { merge: true });
    }
    const tempDir = path.join(os.tmpdir(), `hls_${target.id}`);
    try {
        // Segment konfigürasyonu oku
        // B2: segment1 (ilk segment) varsayılanı 2→1 → daha hızlı TTFF
        // Not: adminConfig/hlsSegment.segment1 override edebilir (0 deploy gerek yok)
        const configSnap = await db.doc("adminConfig/hlsSegment").get();
        const segment1 = clampSegment(configSnap.data()?.segment1, 1); // B2: 2→1
        const segment2 = clampSegment(configSnap.data()?.segment2, 2);
        console.log(`[HLS] Segment config: first=${segment1}s, rest=${segment2}s`);
        // Temp dizini oluştur
        fs.mkdirSync(tempDir, { recursive: true });
        const inputPath = path.join(tempDir, "input.mp4");
        const outputDir = path.join(tempDir, "hls");
        fs.mkdirSync(outputDir, { recursive: true });
        // Video'yu indir
        console.log(`[HLS] Downloading video...`);
        await bucket.file(filePath).download({ destination: inputPath });
        // B2: FPS tespiti ve duration paralel al
        const [durationSeconds, videoFPS, videoHasAudio] = await Promise.all([
            getVideoDurationSeconds(inputPath),
            getVideoFPS(inputPath),
            hasAudioStream(inputPath),
        ]);
        const forceKeyFrames = buildForceKeyFrames(durationSeconds, segment1, segment2);
        console.log(`[HLS] duration=${durationSeconds.toFixed(2)}s, fps=${videoFPS}, forced_keyframes=${forceKeyFrames || "none"}`);
        // Kaynak çözünürlüğünü al
        const probeResult = await execFileAsync("ffprobe", [
            "-v", "error",
            "-select_streams", "v:0",
            "-show_entries", "stream=width,height",
            "-of", "csv=p=0",
            inputPath,
        ]);
        const [srcW, srcH] = String(probeResult.stdout).trim().split(",").map(Number);
        // Eğer kaynak dikey (portrait) ise width'i baz al
        const isPortrait = (srcH || 0) > (srcW || 0);
        const sourceShortSide = isPortrait ? (srcW || 720) : (srcH || 720);
        const targetShortSide = clampEvenDimension(Math.min(sourceShortSide || 720, 1080), 720);
        const singleBitrate = targetShortSide >= 1080 ? 5000 :
            targetShortSide >= 720 ? 2800 :
                targetShortSide >= 480 ? 1400 :
                    targetShortSide >= 360 ? 800 : 500;
        const renditions = [{
                height: targetShortSide,
                bitrate: singleBitrate,
                maxrate: Math.round(singleBitrate * 1.07),
                bufsize: singleBitrate * 2,
                label: "0",
            }];
        // B2: Gerçek FPS kullan — GOP = segment_duration × actual_fps
        const gopSize = Math.round(segment2 * videoFPS);
        console.log(`[HLS] Single rendition mode enabled (${targetShortSide} short-side, ${singleBitrate}k, hasAudio=${videoHasAudio})`);
        // Her rendition için ayrı dizin oluştur
        for (const r of renditions) {
            fs.mkdirSync(path.join(outputDir, r.label), { recursive: true });
        }
        // Tek rendition HLS encoding
        const ffmpegArgs = ["-i", inputPath];
        const filterComplexParts = [];
        const outputArgs = [];
        for (let i = 0; i < renditions.length; i++) {
            const r = renditions[i];
            const scale = isPortrait
                ? `scale=${r.height}:-2:flags=lanczos`
                : `scale=-2:${r.height}:flags=lanczos`;
            const renditionLabel = `r${i}`;
            filterComplexParts.push(buildTurqCleanVisionFilterComplex(renditionLabel, scale));
            outputArgs.push("-map", `[${renditionLabel}out]`, `-c:v:${i}`, "libx264", `-b:v:${i}`, `${r.bitrate}k`, `-maxrate:v:${i}`, `${r.maxrate}k`, `-bufsize:v:${i}`, `${r.bufsize}k`, `-pix_fmt`, "yuv420p", `-profile:v:${i}`, "main", `-preset`, "fast", `-g:v:${i}`, String(gopSize), `-keyint_min:v:${i}`, String(gopSize), `-sc_threshold:v:${i}`, "0");
            if (videoHasAudio) {
                outputArgs.push("-map", "0:a:0?", `-c:a:${i}`, "aac", `-b:a:${i}`, "128k", `-ar:${i}`, "48000");
            }
        }
        ffmpegArgs.push("-filter_complex", filterComplexParts.join(";"));
        ffmpegArgs.push(...outputArgs);
        // forceKeyFrames tüm stream'lere
        if (forceKeyFrames) {
            ffmpegArgs.push("-force_key_frames", forceKeyFrames);
        }
        // HLS muxer ayarları
        const varStreamMap = renditions
            .map((_, i) => (videoHasAudio ? `v:${i},a:${i}` : `v:${i}`))
            .join(" ");
        ffmpegArgs.push("-f", "hls", "-hls_time", String(segment2), "-hls_init_time", String(segment1), "-hls_list_size", "0", "-hls_playlist_type", "vod", "-hls_flags", "independent_segments+temp_file", "-hls_segment_type", "mpegts", "-master_pl_name", "master.m3u8", "-var_stream_map", varStreamMap, "-hls_segment_filename", path.join(outputDir, "%v/seg_%03d.ts"), path.join(outputDir, "%v/playlist.m3u8"));
        await execFileAsync("ffmpeg", ffmpegArgs, { maxBuffer: 50 * 1024 * 1024 });
        console.log(`[HLS] Transcode complete. Uploading HLS files...`);
        // HLS dosyalarını Storage'a yükle (nested rendition dizinleri dahil)
        const uploadPromises = [];
        let hlsSegmentCount = 0;
        const walkDir = (dir, prefix) => {
            for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
                if (entry.isDirectory()) {
                    walkDir(path.join(dir, entry.name), `${prefix}${entry.name}/`);
                }
                else {
                    const localPath = path.join(dir, entry.name);
                    const remotePath = `${target.hlsOutputPrefix}/${prefix}${entry.name}`;
                    const isPlaylist = entry.name.endsWith(".m3u8");
                    const isMaster = entry.name === "master.m3u8";
                    if (entry.name.endsWith(".ts"))
                        hlsSegmentCount++;
                    // Segmentler immutable → uzun cache. Master playlist kısa cache (ABR switch).
                    const cacheControl = isPlaylist
                        ? isMaster
                            ? "public, max-age=300, s-maxage=300"
                            : "public, max-age=86400, s-maxage=86400"
                        : "public, max-age=31536000, s-maxage=31536000, immutable";
                    uploadPromises.push(bucket.upload(localPath, {
                        destination: remotePath,
                        metadata: {
                            contentType: isPlaylist
                                ? "application/vnd.apple.mpegurl"
                                : "video/mp2t",
                            cacheControl,
                        },
                    }));
                }
            }
        };
        walkDir(outputDir, "");
        await Promise.all(uploadPromises);
        // Firestore güncelle
        const hlsUrl = `https://${CDN_DOMAIN}/${target.hlsOutputPrefix}/master.m3u8`;
        if (!migrationMode) {
            await db.doc(target.firestoreDoc).set(target.buildSuccessData(hlsUrl, hlsSegmentCount), { merge: true });
        }
        // Story'de ilgili video element URL'sini HLS master URL'e çevir.
        // Böylece dokümanda MP4 URL kalmaz.
        if (!migrationMode &&
            target.type === "story" &&
            target.storyUid &&
            target.storyId) {
            try {
                const sourceFileName = path.posix.basename(filePath).toLowerCase();
                const storyPathNeedle = `/stories/${target.storyUid}/${target.storyId}/`.toLowerCase();
                const storySnap = await db.doc(target.firestoreDoc).get();
                const data = storySnap.data();
                const elements = Array.isArray(data?.elements) ? data?.elements : [];
                let changed = false;
                const updated = elements.map((raw) => {
                    if (!raw || typeof raw !== "object")
                        return raw;
                    const e = raw;
                    const type = String(e.type || "").toLowerCase();
                    const content = String(e.content || "");
                    if (type !== "video" || !content)
                        return raw;
                    const lcContent = content.toLowerCase();
                    if (lcContent.includes(storyPathNeedle) &&
                        lcContent.includes(sourceFileName)) {
                        changed = true;
                        return { ...e, content: hlsUrl };
                    }
                    return raw;
                });
                if (changed) {
                    await db.doc(target.firestoreDoc).set({
                        elements: updated,
                    }, { merge: true });
                }
            }
            catch (storyPatchErr) {
                console.warn("[HLS] Story element URL patch failed (ignored)", storyPatchErr);
            }
        }
        console.log(`[HLS] Complete for ${target.type}`);
        // Story için orijinal video dosyasını tutma: HLS hazır olduktan sonra sil.
        if (target.type === "story") {
            try {
                await bucket.file(filePath).delete({ ignoreNotFound: true });
                console.log("[HLS] Story source deleted");
            }
            catch (deleteErr) {
                console.warn("[HLS] Story source delete failed (ignored)", deleteErr);
            }
        }
        // Temp dosyaları temizle
        fs.rmSync(tempDir, { recursive: true, force: true });
    }
    catch (error) {
        console.error("[HLS] Error processing video", {
            type: target.type,
            error,
        });
        if (!migrationMode) {
            await db.doc(target.firestoreDoc).set(target.buildFailData(), { merge: true });
        }
        // Temp temizle
        if (fs.existsSync(tempDir)) {
            fs.rmSync(tempDir, { recursive: true, force: true });
        }
    }
});
//# sourceMappingURL=hlsTranscode.js.map