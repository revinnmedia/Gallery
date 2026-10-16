# دليل تجهيز ونشر كنز المسلم 2.0

هذا الدليل يشرح كل الخطوات التي تحتاج حساباتك أنت (Apple و Google و Firebase).
الكود جاهز، وهذه الخطوات هي «المفاتيح» التي تربطه بحساباتك.

> **مهم:** التطبيق يعمل بدون أي من هذه الخطوات (التسبيح والسجل والتذكير كلها محلية).
> الخطوات مطلوبة فقط لتسجيل الدخول والترتيب والأصدقاء، وللنشر على المتاجر.

---

## ١) معرّفات التطبيق

| المنصة | المعرّف | ملاحظة |
|---|---|---|
| iOS | `com.sci3ntist.com.kanzalmuslim` | **نفس معرّف النسخة القديمة**، حتى يرجع التطبيق على نفس صفحته في App Store بنفس الاسم والتقييمات |
| Android | `com.revinn.kanzalmuslim` | تطبيق جديد على Google Play. لا يمكن تغييره بعد النشر الأول |

رقم النسخة: `2.0.0` (build `20`) – موجود في `pubspec.yaml`.

---

## ٢) Firebase (السيرفر الجديد)

1. ادخل https://console.firebase.google.com واضغط **Add project**، سمّه `kanz-almuslim`.
2. **Build → Authentication → Get started**، ثم فعّل:
   - **Google**
   - **Apple**
3. **Build → Firestore Database → Create database** (اختر أقرب منطقة، مثلاً `europe-west` أو `me-central`)، وابدأ بـ **production mode**.
4. أضف تطبيق iOS بالمعرّف `com.sci3ntist.com.kanzalmuslim`، ونزّل ملف `GoogleService-Info.plist`.
5. أضف تطبيق Android بالمعرّف `com.revinn.kanzalmuslim`، ونزّل ملف `google-services.json`.
   - لتسجيل الدخول بـ Google على أندرويد أضف بصمة **SHA-1** لمفتاح التوقيع (تظهر في Play Console → App integrity بعد أول رفع، وفي Codemagic).
6. ارفع قواعد الحماية والفهارس (مرة واحدة، من أي جهاز عليه Node.js):
   ```bash
   npx firebase-tools login
   npx firebase-tools use --add      # اختر مشروع kanz-almuslim
   npx firebase-tools deploy --only firestore
   ```

### أين أضع الملفات؟

| الملف | المكان |
|---|---|
| `google-services.json` | `android/app/google-services.json` |
| `GoogleService-Info.plist` | `ios/Runner/GoogleService-Info.plist` (ويجب إضافته لمشروع Xcode ضمن Runner) |

> هذان الملفان ليسا سرّيين (Google تسمح بوضعهما في المستودع)، وأمان البيانات تحميه قواعد Firestore.
> أسهل طريقة: أرسلهما لـ Claude ليضعهما ويربطهما بالمشروع.

### تسجيل الدخول بـ Google على iOS
افتح `GoogleService-Info.plist` وانسخ قيمة `REVERSED_CLIENT_ID` و `CLIENT_ID`، ثم أضفهما إلى `ios/Runner/Info.plist`:
```xml
<key>GIDClientID</key>
<string>هنا CLIENT_ID</string>
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>هنا REVERSED_CLIENT_ID</string>
    </array>
  </dict>
</array>
```

---

## ٣) Apple (App Store Connect + Developer)

1. في https://developer.apple.com/account → **Identifiers** → افتح `com.sci3ntist.com.kanzalmuslim` وفعّل:
   - **Sign In with Apple**
   - **Game Center**
2. **Game Center** في App Store Connect → صفحة التطبيق → Services → Game Center:
   - لوحة صدارة (Classic, High score) بالمعرّف: `kanz_total_tasbeeh` واسم «أكثر الذاكرين».
   - إنجازات (اختياري) بالمعرّفات: `kanz_first_100`، `kanz_first_1000`، `kanz_first_10000`، `kanz_first_100000`.
3. أنشئ نسخة جديدة **2.0** في App Store Connect، وفي **App Review Information** اكتب للمراجع:
   > Version 2.0 is a complete rebuild in response to the App Store Improvement Notice (March 2025). The app is rebuilt with the latest SDK, the old server and Facebook login were removed, and the notification and audio bugs were fixed. Sign in is optional (Apple / Google) and is only used for the leaderboard and friends. Accounts can be deleted from Settings → Account → Delete account. All core features (tasbeeh counter, records, reminders) work without an account.
### سبب إزالة التطبيق (رسالة Apple)
رسالتان من Apple:
- **24 مارس 2025 – App Store Improvement Notice:** التطبيق لم يُحدَّث منذ أكثر من ٣ سنوات
  ولم يصل للحد الأدنى من التحميلات، فطلبت Apple تحديثاً خلال ٩٠ يوماً (Guideline 4).
- **23 يونيو 2025:** لم يصل تحديث، فأُزيل التطبيق من المتجر.

**ليست مخالفة في المحتوى.** الحل كما تقول Apple: بناء نسخة بأحدث Xcode ورفعها كتحديث،
وعند الموافقة يرجع التطبيق للمتجر بنفس الصفحة. النسخة 2.0 تفعل ذلك (تُبنى على Codemagic بأحدث Xcode).

---|---|
| السيرفر `kanz.sci3ntist.com` يعمل بـ http غير مشفّر (ممنوع) وغالباً متوقف | Firebase مشفّر بالكامل |
| تسجيل الدخول بفيسبوك فقط بدون «Sign in with Apple» | Apple + Google |
| لا يوجد حذف حساب داخل التطبيق (إلزامي منذ 2022) | الإعدادات → حذف الحساب |
| مكتبات قديمة ومتوقفة (UIWebView, NSURLConnection, UILocalNotification) | كود حديث بالكامل |
| تنبيهات مكررة ومزعجة | جدول تنبيهات جديد بدون تكرار |

---

## ٤) Google Play

1. أنشئ حساب مطوّر: https://play.google.com/console (رسوم ٢٥$ مرة واحدة).
2. **Create app** → الاسم «كنز المسلم»، اللغة العربية، App، Free.
3. **Play Games Services** (اختياري، مقابل Game Center):
   - أنشئ مشروع Play Games واربطه بالتطبيق.
   - أنشئ لوحة صدارة «أكثر الذاكرين» وانسخ معرّفها إلى `androidLeaderboardId` في `lib/services/games_service.dart`.
   - انسخ **Project ID** (رقم من ١٢ خانة) إلى `android/app/src/main/res/values/games.xml`.
4. **App content**: سياسة الخصوصية (رابط)، Data safety (الاسم والبريد للحساب فقط)، تصنيف المحتوى.

---

## ٥) البناء والرفع بدون جهاز Mac – Codemagic

ملف `codemagic.yaml` في المستودع جاهز. الخطوات:
1. ادخل https://codemagic.io وسجّل بحساب GitHub، وأضف مستودع `kanz-almuslim`.
2. **Teams → Integrations → Developer Portal**: أضف مفتاح App Store Connect API (من App Store Connect → Users and Access → Integrations → Keys، صلاحية App Manager).
3. لأندرويد: **Code signing identities → Android keystores** → أنشئ keystore باسم `kanz_keystore`. **احتفظ بنسخة منه، فبدونه لا يمكن تحديث التطبيق أبداً.**
4. شغّل workflow **ios-release** أو **android-release**، وستظهر النسخة في TestFlight أو في Play Console (Internal testing).

---

## ٦) الأيقونة وصور المتجر

- الأيقونة الحالية في المشروع هي أيقونة Flutter المؤقتة. أرسل أيقونة التطبيق الأصلية
  (1024×1024 PNG بدون شفافية) ليتم توليد كل المقاسات لـ iOS و Android.
- صور المتجر: iPhone 6.9" (1320×2868) و 6.5" (1284×2778)، وأندرويد هاتف (1080×1920 على الأقل).
