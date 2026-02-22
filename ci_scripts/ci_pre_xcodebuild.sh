cat > ci_scripts/ci_pre_xcodebuild.sh << 'EOF'
#!/bin/sh
set -euo pipefail

echo "🚀 [pre-xcodebuild] Start"

if [ -d "$HOME/flutter/bin" ]; then
  export PATH="$HOME/flutter/bin:$PATH"
fi

flutter pub get

echo "✅ [pre-xcodebuild] Ready"
EOF
