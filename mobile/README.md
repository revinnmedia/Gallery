# تطبيق الجوال — مطبعة (Capacitor)

التطبيق على الجوال عبارة عن **غلاف native** (Android + iOS) يفتح الموقع المنشور
داخل WebView. الواجهة والـ API نفسهم اللي بالموقع، بدون تكرار كود.

## المتطلبات

- **Android:** [Android Studio](https://developer.android.com/studio) (يثبّت Java + Gradle + SDK)
- **iOS:** macOS فقط، مع [Xcode](https://developer.apple.com/xcode/)
- المشروع منشور على رابط عام (Vercel أو أي مستضيف Next.js)

## خطوات الإعداد (أول مرة فقط)

1. **انشر الموقع** على Vercel (أو غيره) واحفظ الرابط النهائي.
2. **عدّل `capacitor.config.ts`** في جذر المشروع: غيّر `server.url` ليصير رابط موقعك المنشور.
   (أو خلّه يقرأ من متغير البيئة `CAPACITOR_SERVER_URL`.)
3. **أنشئ المنصة:**
   ```bash
   npm run mobile:add:android   # ينشئ مجلد android/
   npm run mobile:add:ios       # ينشئ مجلد ios/ (macOS فقط)
   ```
4. **زامن:**
   ```bash
   npm run mobile:sync
   ```

## تشغيل وتطوير

```bash
npm run mobile:open:android   # يفتح Android Studio
npm run mobile:open:ios       # يفتح Xcode
```

من Android Studio: اضغط ▶️ لتشغيل التطبيق على محاكي أو جوال موصول USB.
من Xcode: اختار جهاز واضغط ▶️.

## بناء ملف التثبيت

**Android APK (للاختبار):**
- في Android Studio: `Build → Build Bundle(s) / APK(s) → Build APK(s)`
- الملف ينطلع في `android/app/build/outputs/apk/debug/app-debug.apk`

**Android AAB (Google Play):**
- `Build → Generate Signed Bundle / APK → Android App Bundle`
- يحتاج keystore (أنشئ واحد من نفس الواجهة أول مرة)

**iOS IPA (App Store):**
- في Xcode: `Product → Archive` ثم `Distribute App`

## أيقونة وشاشة البداية

ضع صورة 1024×1024 في `mobile/resources/icon.png` ثم نفّذ:
```bash
npm run mobile:assets
```
يولّد كل المقاسات تلقائياً.

## ملاحظات

- إذا غيّرت إعدادات الـ web build أو الـ `capacitor.config.ts`، شغّل `npm run mobile:sync`.
- مجلدات `android/` و `ios/` المُنشأة بـ `cap add` ما بتُضاف لـ git افتراضياً
  (هي مولّدة)، بس فيك تضيفها لو بدك تشاركها بين المطورين.
- الموقع لازم يكون شغّال على HTTPS وإلا Android رح يرفضه افتراضياً.
