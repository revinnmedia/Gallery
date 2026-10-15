#!/usr/bin/env bash
# يجهّز أصوات التطبيق الأصلية ويضعها في أماكنها.
#
# الاستخدام (أي مجلد من الاثنين، أو الاثنين معاً):
#   tool/prepare_sounds.sh "/path/to/كنز المسلم/أصوات التطبيق" /path/to/KanzAlMuslim
#
# - مجلد التصميم: ملفات بأسماء عربية (سبحان الله.mp3 ...)
# - مشروع Xcode القديم: ملفات بأسماء مرقّمة (dc8e65c1....mp3)
# جدول الربط بين الأسماء في tool/sounds.json (مطابق بالمحتوى).
# يحتاج python3، و ffmpeg لتحويل أصوات تنبيهات iOS إلى caf.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
[ $# -ge 1 ] || { echo "الاستخدام: $0 <مجلد الأصوات> [مجلد آخر]"; exit 1; }
mkdir -p "$ROOT/assets/sounds" "$ROOT/android/app/src/main/res/raw" "$ROOT/ios/Runner/Sounds"

python3 - "$ROOT" "$@" <<'PY'
import json, os, shutil, subprocess, sys
root, dirs = sys.argv[1], sys.argv[2:]
table = json.load(open(os.path.join(root, 'tool/sounds.json'), encoding='utf-8'))
missing = []
for name, src in table.items():
    found = None
    for d in dirs:
        for key in ('design', 'old'):
            f = src.get(key)
            if f and os.path.exists(os.path.join(d, f)):
                found = os.path.join(d, f)
                break
        if found:
            break
    if not found:
        missing.append(name)
        continue
    shutil.copy(found, os.path.join(root, 'assets/sounds', name + '.mp3'))
    shutil.copy(found, os.path.join(root, 'android/app/src/main/res/raw', name + '.mp3'))
    if shutil.which('ffmpeg'):
        subprocess.run(['ffmpeg', '-loglevel', 'error', '-y', '-i', found, '-t', '29',
                        '-acodec', 'pcm_s16le', os.path.join(root, 'ios/Runner/Sounds', name + '.caf')], check=True)
    print('✓', name, '←', os.path.basename(found))
if missing:
    print('غير موجود:', ', '.join(missing))
PY
echo "تمت. أضف مجلد ios/Runner/Sounds لمشروع Xcode، ثم اجعل soundsBundled = true في notification_service.dart."
