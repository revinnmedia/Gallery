# إرجاع كنز المسلم إلى App Store — النسخة 2.0 (بدون سيرفر)

Apple أزالت التطبيق لأنه **لم يُحدَّث منذ أكثر من ٣ سنوات** (رسالة 24 مارس 2025).
الحل: رفع تحديث مبني بأحدث Xcode. عند الموافقة يرجع التطبيق لنفس صفحته.

هذه النسخة تعمل **بدون Firebase**: التسبيح، السجل، الإشعارات، عدم الإزعاج، الأصوات،
والترتيب عبر **Game Center**. تسجيل الدخول والأصدقاء والمحادثة تأتي في التحديث التالي.

## ١) حساب Apple Developer (مرة واحدة)
1. https://developer.apple.com/account → Certificates, Identifiers & Profiles → **Identifiers**.
2. افتح `com.sci3ntist.com.kanzalmuslim` وتأكد أن **Game Center** مفعّل.
3. App Store Connect → Users and Access → Integrations → **App Store Connect API** →
   أنشئ مفتاحاً بصلاحية **App Manager** ونزّل ملف `.p8` (يُنزَّل مرة واحدة فقط).

## ٢) Game Center (لوحة أكثر الذاكرين)
App Store Connect → التطبيق → **Services → Game Center**:
- **Leaderboard** → Classic → Best Score
  - Reference Name: `Total Tasbeeh`
  - Leaderboard ID: `kanz_total_tasbeeh`
  - Score Format: Integer، Sort: High to Low
  - Localization عربي: الاسم «أكثر الذاكرين»
- (اختياري) **Achievements** بالمعرّفات: `kanz_first_100`، `kanz_first_1000`، `kanz_first_10000`، `kanz_first_100000`.

## ٣) البناء والرفع عبر Codemagic (بدون Mac)
1. https://codemagic.io → سجّل بحساب GitHub → أضف المستودع.
2. Teams → Integrations → **Developer Portal** → أضف مفتاح API من الخطوة ١ باسم `Kanz ASC Key`.
3. شغّل workflow **ios-release** → بعد ~٢٠ دقيقة تظهر النسخة في TestFlight.
4. جرّبها على جهازك من تطبيق TestFlight.

## ٤) تقديم النسخة 2.0 للمراجعة
App Store Connect → التطبيق → **+ Version** → `2.0`:

**What's New (العربية):**
```
كنز المسلم بحلّة جديدة كلياً:
• إعادة بناء كاملة للتطبيق ليعمل بسلاسة على أحدث أجهزة iPhone
• إصلاح التنبيهات المكررة: تنبيه واحد في كل مرة وبدون إزعاج
• إصلاح تداخل أصوات الأذكار
• خيار عدم الإزعاج بساعات تختارها
• ترتيب أكثر الذاكرين عبر Game Center
• نفس التصميم الذي تحبونه مع تحسينات بسيطة
```

**What's New (English):**
```
Kanz Al Muslim, completely rebuilt:
• Rebuilt from scratch for the latest iPhones
• Fixed duplicate reminders: one reminder at a time
• Fixed overlapping dhikr sounds
• New Do Not Disturb hours
• Top dhikr leaderboard via Game Center
• The same design you love, refreshed
```

**صور الشاشة (iPhone 6.9"):** الملفات في `docs/store/` بمقاس 1290×2796 — ارفعها كما هي.

**App Review Information → Notes:**
```
Version 2.0 is a complete rebuild in response to the App Store Improvement Notice (March 2025).
The app is rebuilt with the latest SDK. The old server and Facebook login were removed.
No account is required: all features (tasbeeh counter, records, reminders) work offline.
The leaderboard uses Game Center. Swipe the columns up (or tap the bead ring) to count.
```

**App Privacy:** Data Not Collected (لا يوجد حساب ولا سيرفر في هذه النسخة).

بعد إرسالها، المراجعة عادة ١–٣ أيام.

## التحديث التالي (2.1): تسجيل الدخول والأصدقاء
انظر `docs/SETUP.md` (Firebase). عندها:
- فعّل **Sign In with Apple** على App ID، وأضف `com.apple.developer.applesignin` إلى `ios/Runner/Runner.entitlements`.
- حدّث App Privacy (الاسم والبريد للحساب).
