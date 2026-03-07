// 📸 Image Thumbnail Generator
// Automatically generates thumbnails when images are uploaded to Firebase Storage
// Generates 3 sizes: 150px (avatars), 300px (feed), 600px (detail)

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import * as path from "path";
import * as os from "os";
import * as fs from "fs";

// Use dynamic import for sharp to avoid build issues
const sharp = require("sharp");

const THUMBNAIL_SIZES = [
  { width: 150, suffix: "_thumb_150" }, // Avatar size
  { width: 300, suffix: "_thumb_300" }, // Feed preview
  { width: 600, suffix: "_thumb_600" }, // Story preview / detail
];

const SUPPORTED_FORMATS = [".jpg", ".jpeg", ".png", ".webp"];

/**
 * Cloud Function: Generate thumbnails on image upload
 * Triggers when a file is finalized (uploaded) to Firebase Storage
 */
export const generateThumbnails = functions
  .region("europe-west1")
  .storage.object()
  .onFinalize(async (object) => {
    const filePath = object.name;
    if (!filePath) {
      console.log("No file path");
      return null;
    }

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // 🔍 VALIDATION: Check if file should be processed
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    // Skip if already a thumbnail
    if (filePath.includes("_thumb_")) {
      console.log("Already a thumbnail, skipping:", filePath);
      return null;
    }

    // Skip profile avatar uploads: app now uploads finalized single avatar asset
    if (filePath.startsWith("users/") && filePath.includes("_avatarUrl")) {
      console.log("Profile avatar source file, skipping thumbnail generation:", filePath);
      return null;
    }

    // Check file extension
    const ext = path.extname(filePath).toLowerCase();
    if (!SUPPORTED_FORMATS.includes(ext)) {
      console.log("Not an image file, skipping:", filePath);
      return null;
    }

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // 📥 DOWNLOAD: Download source image from Storage
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    const bucket = admin.storage().bucket(object.bucket);
    const file = bucket.file(filePath);

    const tempDir = os.tmpdir();
    const fileName = path.basename(filePath);
    const tempFilePath = path.join(tempDir, fileName);

    try {
      await file.download({ destination: tempFilePath });
      console.log("Downloaded to temp:", tempFilePath);
    } catch (error) {
      console.error("Download error:", error);
      return null;
    }

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // 🎨 GENERATE: Create thumbnails
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    const dir = path.dirname(filePath);
    const baseName = path.basename(filePath, ext);

    const uploadPromises = THUMBNAIL_SIZES.map(async ({ width, suffix }) => {
      const thumbFileName = `${baseName}${suffix}.webp`;
      const thumbPath = path.join(tempDir, thumbFileName);
      const thumbStoragePath = path.join(dir, thumbFileName);

      try {
        // Generate thumbnail with sharp
        await sharp(tempFilePath)
          .resize(width, null, {
            withoutEnlargement: true,
            fit: "inside",
          })
          .webp({
            quality: 85,
            effort: 4, // Balance between speed and compression
          })
          .toFile(thumbPath);

        console.log(`Generated ${width}px thumbnail:`, thumbPath);

        // Upload to Storage
        await bucket.upload(thumbPath, {
          destination: thumbStoragePath,
          metadata: {
            contentType: "image/webp",
            metadata: {
              originalFile: filePath,
              thumbnailSize: width.toString(),
            },
          },
        });

        console.log(`Uploaded thumbnail to:`, thumbStoragePath);

        // Clean up temp file
        fs.unlinkSync(thumbPath);
      } catch (error) {
        console.error(`Error creating ${width}px thumbnail:`, error);
      }
    });

    await Promise.all(uploadPromises);

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // 🧹 CLEANUP: Remove original temp file
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    try {
      fs.unlinkSync(tempFilePath);
      console.log("Cleaned up temp file:", tempFilePath);
    } catch (error) {
      console.error("Cleanup error:", error);
    }

    console.log(`✅ Thumbnail generation complete for: ${filePath}`);
    return null;
  });
