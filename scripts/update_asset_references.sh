#!/bin/bash

# Update Asset References - PNG to WebP
# Updates all local asset references from .png to .webp in Dart files

set -e

echo "🔄 Updating asset references: .png → .webp"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Navigate to project root
cd "$(dirname "$0")/.."

# Backup lib folder
BACKUP_DIR="lib_backup_$(date +%Y%m%d_%H%M%S)"
echo "📦 Creating backup: $BACKUP_DIR"
cp -R lib "$BACKUP_DIR"

# Count files to update
TOTAL_FILES=$(grep -rl 'assets.*\.png' lib/ --include="*.dart" | grep -v "firebasestorage" | wc -l | tr -d ' ')

echo "📝 Files to update: $TOTAL_FILES"
echo ""

# Update all local asset .png references to .webp
# Excludes Firebase Storage URLs
find lib -name "*.dart" -type f -exec sed -i '' \
    -e 's/\(assets[^"'\'']*\)\.png/\1.webp/g' \
    {} +

echo "✅ Updated all local asset references"
echo ""

# Verify changes
REMAINING=$(grep -r 'assets.*\.png' lib/ --include="*.dart" 2>/dev/null | grep -v "firebasestorage" | wc -l | tr -d ' ')

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Update Complete!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📊 Remaining .png references: $REMAINING (should be 0)"
echo "🔙 Backup saved at: $BACKUP_DIR"
echo ""

if [ "$REMAINING" -eq 0 ]; then
    echo "✅ All local asset references updated successfully!"
else
    echo "⚠️  Some references might need manual update"
    grep -r 'assets.*\.png' lib/ --include="*.dart" 2>/dev/null | grep -v "firebasestorage" || true
fi
