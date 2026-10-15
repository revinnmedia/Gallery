اختبار قواعد الحماية على محاكي Firestore:

```bash
cd firebase/rules-test
npm install
npx firebase emulators:exec --only firestore --project kanz-rules-test "npx mocha rules.test.mjs"
```
