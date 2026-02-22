#!/bin/bash

# Asset Optimization Script - PNG/JPG to WebP
# Converts all images to WebP format with 85% quality
# Expected reduction: 78 MB → 8 MB (90% savings)

set -e

echo "🚀 Starting Asset Optimization..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Check if cwebp is installed
if ! command -v cwebp &> /dev/null; then
    echo "❌ cwebp not found!"
    echo "Install with: brew install webp"
    exit 1
fi

# Navigate to project root
cd "$(dirname "$0")/.."

# Create backup
BACKUP_DIR="assets_backup_$(date +%Y%m%d_%H%M%S)"
echo "📦 Creating backup: $BACKUP_DIR"
cp -R assets "$BACKUP_DIR"

# Statistics
TOTAL_ORIGINAL=0
TOTAL_CONVERTED=0
FILE_COUNT=0

echo ""
echo "🔄 Converting images to WebP (quality: 85%)..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Find and convert all PNG/JPG files
find assets -type f \( -iname "*.png" -o -iname "*.jpg" -o -iname "*.jpeg" \) | while read -r file; do
    # Get file size
    ORIGINAL_SIZE=$(stat -f%z "$file" 2>/dev/null || stat -c%s "$file" 2>/dev/null)
    ORIGINAL_SIZE_MB=$(echo "scale=2; $ORIGINAL_SIZE / 1024 / 1024" | bc)

    # Output filename (replace extension with .webp)
    OUTPUT="${file%.*}.webp"

    # Convert to WebP
    cwebp -q 85 "$file" -o "$OUTPUT" &>/dev/null

    if [ $? -eq 0 ]; then
        CONVERTED_SIZE=$(stat -f%z "$OUTPUT" 2>/dev/null || stat -c%s "$OUTPUT" 2>/dev/null)
        CONVERTED_SIZE_MB=$(echo "scale=2; $CONVERTED_SIZE / 1024 / 1024" | bc)
        REDUCTION=$(echo "scale=1; 100 - ($CONVERTED_SIZE * 100 / $ORIGINAL_SIZE)" | bc)

        echo "✅ $(basename "$file"): ${ORIGINAL_SIZE_MB}MB → ${CONVERTED_SIZE_MB}MB (-${REDUCTION}%)"

        TOTAL_ORIGINAL=$((TOTAL_ORIGINAL + ORIGINAL_SIZE))
        TOTAL_CONVERTED=$((TOTAL_CONVERTED + CONVERTED_SIZE))
        FILE_COUNT=$((FILE_COUNT + 1))

        # Remove original PNG/JPG
        rm "$file"
    else
        echo "❌ Failed: $file"
    fi
done

# Calculate total reduction
TOTAL_ORIGINAL_MB=$(echo "scale=2; $TOTAL_ORIGINAL / 1024 / 1024" | bc)
TOTAL_CONVERTED_MB=$(echo "scale=2; $TOTAL_CONVERTED / 1024 / 1024" | bc)
TOTAL_REDUCTION=$(echo "scale=1; 100 - ($TOTAL_CONVERTED * 100 / $TOTAL_ORIGINAL)" | bc)

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Conversion Complete!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📊 Files converted: $FILE_COUNT"
echo "📦 Original size: ${TOTAL_ORIGINAL_MB} MB"
echo "📦 New size: ${TOTAL_CONVERTED_MB} MB"
echo "💰 Savings: ${TOTAL_REDUCTION}%"
echo ""
echo "🔙 Backup saved at: $BACKUP_DIR"
echo "⚠️  Don't forget to update pubspec.yaml and code references!"
echo ""
