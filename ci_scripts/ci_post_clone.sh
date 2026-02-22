cat > ci_scripts/ci_post_clone.sh << 'EOF'
#!/bin/sh
set -euo pipefail

echo "🔧 [post-clone] Start"

# (Opsiyonel) Flutter SDK yoksa indir
if ! command -v flutter >/dev/null 2>&1; then
  echo "⬇️  Installing Flutter SDK (stable)"
  git clone https://github.com/flutter/flutter.git -b stable ~/flutter
  export PATH="$HOME/flutter/bin:$PATH"
  flutter --version
else
  echo "✅ Flutter already available"
  flutter --version
fi

echo "📦 flutter pub get & precache"
flutter pub get
flutter precache --ios

echo "🪄 Updating CocoaPods specs (safe to skip if slow)"
pod repo update || true

echo "📚 pod install"
cd ios
pod install

echo "✅ [post-clone] Done"
EOF
