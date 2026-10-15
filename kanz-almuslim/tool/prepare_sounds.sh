#!/usr/bin/env bash
# يجهّز أصوات الأذكار من مجلد النسخة القديمة.
# الاستخدام: tool/prepare_sounds.sh /path/to/old/KanzAlMuslim
# يحتاج ffmpeg (لتحويل أصوات تنبيهات iOS إلى caf).
set -euo pipefail
SRC="${1:?مسار مجلد النسخة القديمة}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
mkdir -p "$ROOT/assets/sounds" "$ROOT/android/app/src/main/res/raw" "$ROOT/ios/Runner/Sounds"
for f in "$SRC"/*.mp3; do
  base="$(basename "$f" .mp3)"
  # نأخذ فقط الملفات ذات الأسماء الرقمية (الأسماء العربية نسخ مكررة).
  [[ "$base" =~ ^[0-9a-f]{32}$ ]] || continue
  name="s_$base"
  cp "$f" "$ROOT/assets/sounds/$name.mp3"
  cp "$f" "$ROOT/android/app/src/main/res/raw/$name.mp3"
  ffmpeg -loglevel error -y -i "$f" -t 29 -acodec pcm_s16le "$ROOT/ios/Runner/Sounds/$name.caf"
  echo "✓ $name"
done
echo "تمت. أضف مجلد ios/Runner/Sounds لمشروع Xcode، ثم اجعل soundsBundled = true."
