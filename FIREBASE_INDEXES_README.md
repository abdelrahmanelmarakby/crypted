# حل مشكلة Firebase Indexes للـ Stories

## المشكلة
تظهر أخطاء في Firebase Firestore عند محاولة جلب الـ stories بسبب عدم وجود indexes مطلوبة للاستعلامات المعقدة.

## الحل

### 1. إنشاء Indexes في Firebase Console

اذهب إلى [Firebase Console](https://console.firebase.google.com) واتبع الخطوات التالية:

1. اختر مشروعك
2. اذهب إلى **Firestore Database**
3. اذهب إلى تبويب **Indexes**
4. أضف الـ indexes التالية:

#### Index 1: لجلب جميع الـ stories النشطة
- **Collection ID**: `Stories`
- **Fields**:
  - `status` (Ascending)
  - `expiresAt` (Descending)
  - `__name__` (Descending)

#### Index 2: لجلب stories مستخدم محدد
- **Collection ID**: `Stories`
- **Fields**:
  - `uid` (Ascending)
  - `status` (Ascending)
  - `expiresAt` (Descending)
  - `__name__` (Descending)

### 2. استخدام Firebase CLI (اختياري)

إذا كان لديك Firebase CLI مثبت، يمكنك نشر الـ indexes باستخدام:

```bash
firebase deploy --only firestore:indexes
```

### 3. الحل المؤقت في الكود

تم تعديل الكود لاستخدام استعلامات بسيطة مؤقتاً حتى يتم إنشاء الـ indexes:

- تم إضافة دالة `getAllStoriesSimple()` في `StoryDataSources`
- تم تعديل الـ controller لاستخدام الاستعلام البسيط مع فلترة في الكود
- تم إضافة معالجة أفضل للأخطاء

### 4. التحقق من الـ Indexes

بعد إنشاء الـ indexes، انتظر بضع دقائق حتى يتم بناؤها، ثم يمكنك:

1. العودة إلى الاستعلامات الأصلية في الكود
2. إزالة الاستعلامات البسيطة المؤقتة
3. اختبار التطبيق مرة أخرى

### 5. ملاحظات مهمة

- الـ indexes تحتاج وقت للبناء (عادة 1-5 دقائق)
- تأكد من أن جميع الحقول المستخدمة في الاستعلام موجودة في الـ indexes
- يمكنك مراقبة حالة الـ indexes في Firebase Console

## استعادة الكود الأصلي

بعد إنشاء الـ indexes، يمكنك استعادة الكود الأصلي:

1. في `StoryDataSources`: استخدم `getAllStories()` و `getUserStories()` بدلاً من `getAllStoriesSimple()`
2. في `StoriesController`: استخدم الاستعلامات الأصلية بدلاً من الفلترة في الكود

## روابط مفيدة

- [Firebase Indexes Documentation](https://firebase.google.com/docs/firestore/query-data/indexing)
- [Firebase Console](https://console.firebase.google.com)
- [Firebase CLI Installation](https://firebase.google.com/docs/cli) 