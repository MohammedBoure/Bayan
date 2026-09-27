# Windows 7 Shims (مكتبات التوافق مع ويندوز 7)

يحتوي هذا المجلد على الكود المصدري وسكريبتات بناء مكتبات التجسير والتوافق المخصصة لتشغيل بيئة Flutter على نظام Windows 7 x64.

---

## 📁 محتويات المجلد:
* **`nt_w7.c`**: الكود المصدري بلغة C لدوال التوافق المفقودة في نظام Windows 7:
  * `RtlAddGrowableFunctionTable`: تحويل الاستدعاء إلى `RtlAddFunctionTable` المدعومة في نواة ويندوز 7.
  * `RtlDeleteGrowableFunctionTable`: تحويل الاستدعاء إلى `RtlDeleteFunctionTable`.
  * تحويل مباشر (Forwarding) لدوال `RtlCaptureStackBackTrace`, `RtlUnwind`, `RtlUnwindEx`, `VerSetConditionMask` نحو `ntdll.dll`.
* **`nt_w7.def`**: ملف تصدير الدوال والموجهات التلقائية نحو `ntdll.dll`.
* **`build.bat`**: سكريبت تجميع المكتبة باستخدام MSVC x64 مع إلغاء الاعتماد على C Runtime (`/NODEFAULTLIB`) لمنع أي تبعيات خارجية على ويندوز 7.
* **`nt_w7.dll`**: المكتبة الثنائية المجمعة الجاهزة للنقل إلى المجلد التوزيعي.
* **`nt_w7.lib`**: ملف الربط الناتج عن التجميع.
* **`nt_w7.exp`**: ملف التصدير الناتج عن الربط.
* **`nt_w7.obj`**: الملف الكائني الوسيط.
