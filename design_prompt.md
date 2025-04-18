# Prompt لتصميم واجهة المستخدم لتطبيق MediSwitch

**الهدف:** تصميم واجهة مستخدم (UI) وتجربة مستخدم (UX) لتطبيق جوال (Android & iOS) باسم **MediSwitch**. يجب أن يكون التصميم **عصرياً، أنيقاً، سهل الاستخدام، وبديهياً**، مع لمسة مستوحاة من بساطة وجاذبية تطبيقات التواصل الاجتماعي الحديثة (مثل Instagram/Telegram)، مع الحفاظ على طابع طبي احترافي وموثوق.

**مهم جداً:** المطلوب هو **التصميم فقط** (Visual Design, Style Guide, Assets). **لا تقم بإنشاء أي كود برمجي للتطبيق (Flutter/Dart أو غيره).**

---

## 1. الهوية البصرية والأسلوب العام:

*   **الأسلوب:** حديث (Modern)، نظيف (Clean)، احترافي (Professional)، سهل الوصول (Accessible)، وجذاب بصرياً.
*   **لوحة الألوان:**
    *   **أساسي:** درجات هادئة من اللون الأزرق الطبي (Medical Blue) كلون أساسي يوحي بالثقة والاحترافية.
    *   **ثانوي:** درجات من الرمادي المحايد (Neutral Grays) للخلفيات والنصوص والعناصر الثانوية.
    *   **ألوان التمييز (Accent Colors):** استخدام ألوان زاهية بشكل محدود جداً لتسليط الضوء على الإجراءات الهامة أو التنبيهات (مثل الأخضر للنجاح، البرتقالي/الأصفر للتحذير، الأحمر للخطر).
    *   **الوضع الداكن (Dark Mode):** يجب تصميم وضع داكن متكامل وجذاب بصرياً ومريح للعين، باستخدام درجات داكنة من الرمادي/الأزرق بدلاً من الأسود الصريح.
*   **الخطوط (Typography):**
    *   **اللغة العربية (الأساسية):** استخدام خط **Noto Sans Arabic** بوضوح وسهولة قراءة عالية. تحديد أحجام وأوزان مختلفة للعناوين والنصوص الأساسية والتسميات.
    *   **اللغة الإنجليزية (الثانوية):** استخدام خط Sans Serif حديث ونظيف يتناسق مع الخط العربي (مثل Roboto, Inter, Noto Sans).
    *   **دعم RTL:** يجب أن يدعم التصميم تخطيط من اليمين لليسار (RTL) بشكل كامل وافتراضي.
*   **الأيقونات (Iconography):** استخدام مجموعة أيقونات حديثة ومتناسقة (يفضل نمط Outlined أو Filled بشكل متناسق)، واضحة وسهلة الفهم.
*   **الرسوم المتحركة (Animations):** تصميم انتقالات سلسة (subtle transitions) بين الشاشات وتأثيرات تفاعلية بسيطة (micro-interactions) على الأزرار والعناصر القابلة للنقر لتعزيز تجربة المستخدم دون إفراط.

---

## 2. الشاشات المطلوبة ومحتوياتها:

**أ. شاشات التدفق الرئيسي (Main Flow - Bottom Navigation):**

*   **الشاشة الرئيسية (HomeScreen):**
    *   **Header:** منطقة علوية بارزة تحتوي على:
        *   تحية للمستخدم + اسم المستخدم (مثال: "مرحباً، أحمد").
        *   صورة رمزية (Avatar) للمستخدم أو أيقونة افتراضية.
        *   شريط بحث غير تفاعلي (ينقل المستخدم إلى شاشة البحث عند النقر عليه).
    *   **أقسام أفقية (Horizontal Lists):**
        *   **الفئات الطبية (Categories):** عرض أيقونات وأسماء الفئات الرئيسية (مسكنات، مضادات حيوية، أمراض مزمنة، فيتامينات، إلخ) بتصميم جذاب يشبه البطاقات الصغيرة (Cards).
        *   **أدوية محدثة مؤخراً (Recently Updated):** عرض قائمة أفقية قابلة للتمرير لأحدث الأدوية التي تم تحديث سعرها أو إضافتها، باستخدام تصميم بطاقة دواء مصغرة (Drug Card - Thumbnail). يجب أن تحتوي على زر "عرض الكل".
        *   **الأدوية الأكثر بحثاً (Popular Drugs):** عرض قائمة أفقية مشابهة للأدوية الأكثر شيوعاً بناءً على بيانات (سيتم توفيرها لاحقاً، يمكن استخدام بيانات مؤقتة للتصميم). يجب أن تحتوي على زر "عرض الكل".
    *   **قائمة الأدوية الرئيسية (Main Drug List):**
        *   عرض قائمة/شبكة (تتغير حسب حجم الشاشة - Responsive) لجميع الأدوية أو الأدوية المفلترة.
        *   استخدام تصميم بطاقة دواء (Drug Card - Detailed) لكل عنصر، يعرض: اسم الدواء التجاري، الاسم العربي، السعر، صورة الدواء (إن وجدت)، الفئة الرئيسية.
        *   إمكانية التمرير اللانهائي (Lazy Loading) لعرض المزيد من الأدوية.
*   **شاشة البدائل (AlternativesScreen):** (قد تكون تبويب ضمن تفاصيل الدواء أو شاشة منفصلة حسب التصميم المقترح)
    *   عرض معلومات الدواء الأصلي في الأعلى.
    *   عرض قائمة بالبدائل المقترحة (نفس المادة الفعالة).
    *   استخدام بطاقة بديل (Alternative Drug Card) لكل عنصر، تعرض المعلومات الأساسية للبديل وسعره.
*   **شاشة حاسبة الجرعة بالوزن (WeightCalculatorScreen):**
    *   حقل لاختيار الدواء (مع دعم البحث).
    *   حقول لإدخال وزن المريض (كجم) وعمره (سنوات) مع أيقونات مناسبة.
    *   زر "حساب الجرعة".
    *   منطقة لعرض النتيجة بوضوح (الجرعة المحسوبة).
    *   عرض الملاحظات والتحذيرات (إن وجدت) بشكل مميز وواضح (مثل استخدام ألوان مختلفة أو أيقونات تحذير).
    *   زر "حفظ الحساب" (ميزة Premium - يجب توضيح ذلك في التصميم، قد يكون الزر غير مفعل أو يظهر أيقونة Premium).
*   **شاشة الإعدادات (SettingsScreen):**
    *   **قسم الملف الشخصي (اختياري):** عرض اسم المستخدم، البريد الإلكتروني (إن وجد)، صورة رمزية، زر "تعديل الملف الشخصي".
    *   **قسم الإعدادات العامة:**
        *   تبديل الوضع الداكن (Dark Mode Toggle).
        *   خيار تغيير لغة التطبيق (العربية/الإنجليزية).
        *   تبديل الإشعارات (Notifications Toggle - تصميم فقط، المنطق لاحقاً).
    *   **قسم الأمان والخصوصية:**
        *   خيار "تغيير كلمة المرور" (إذا تم تطبيق نظام حسابات كامل).
        *   خيار "إعدادات الخصوصية".
    *   **قسم الاشتراك (Subscription):**
        *   عرض حالة الاشتراك الحالية (مجاني/مميز).
        *   زر للانتقال إلى شاشة تفاصيل الاشتراك/الشراء.
    *   **قسم حول التطبيق:**
        *   عرض إصدار التطبيق.
        *   روابط لـ "شروط الخدمة"، "سياسة الخصوصية"، "عن التطبيق".
        *   زر "التحقق من وجود تحديثات".
        *   عرض تاريخ آخر تحديث لبيانات الأدوية.
    *   **زر تسجيل الخروج (Logout):** (إذا تم تطبيق نظام حسابات كامل).

**ب. شاشات ثانوية (Secondary Screens):**

*   **شاشة البحث (SearchScreen):**
    *   **AppBar:** شريط بحث نشط مع أيقونة بحث وزر للفلترة.
    *   **عرض النتائج:** عرض قائمة/شبكة بنتائج البحث باستخدام نفس تصميم `DrugListItem` المستخدم في الشاشة الرئيسية.
    *   **حالة عدم وجود نتائج:** رسالة واضحة للمستخدم.
    *   **الفلاتر (Filter Bottom Sheet):** تصميم Bottom Sheet يظهر عند الضغط على زر الفلترة، يحتوي على:
        *   خيارات فلترة حسب الفئة (باستخدام Chips أو قائمة).
        *   خيار فلترة حسب السعر (ربما باستخدام Slider أو خيارات محددة).
        *   زر "تطبيق الفلاتر" وزر "إعادة تعيين".
*   **شاشة تفاصيل الدواء (DrugDetailsScreen):**
    *   **Header:** عرض صورة الدواء، الاسم التجاري، الاسم العربي، المادة الفعالة، السعر الحالي (مع إمكانية عرض السعر القديم ونسبة التغير إن وجدت). زر "إضافة للمفضلة" (Premium).
    *   **TabBar:** تبويبات للتنقل بين الأقسام:
        *   **معلومات:** عرض تفاصيل الدواء (الشركة، الفئة، الشكل الصيدلي، الوحدة، الاستخدام، الوصف، تاريخ آخر تحديث للسعر).
        *   **البدائل:** عرض محتوى `AlternativesScreen` (أو تصميم مشابه).
        *   **الجرعات:** عرض معلومات الجرعة القياسية (إن وجدت)، وزر للانتقال إلى `WeightCalculatorScreen` مع ملء الدواء الحالي تلقائياً.
        *   **التفاعلات:** عرض قائمة بالتفاعلات الدوائية المعروفة لهذا الدواء (إن وجدت)، وزر للانتقال إلى `InteractionCheckerScreen` مع ملء الدواء الحالي تلقائياً.
*   **شاشة مدقق التفاعلات (InteractionCheckerScreen):**
    *   منطقة لعرض الأدوية المختارة (باستخدام Chips مع زر حذف لكل دواء).
    *   زر "إضافة دواء" (يفتح بحث لاختيار دواء آخر).
    *   زر "فحص التفاعلات".
    *   منطقة لعرض النتائج:
        *   ملخص لمستوى الخطورة العام (Major, Moderate, Minor) باستخدام لون أو أيقونة مميزة.
        *   عرض قائمة بالتفاعلات المكتشفة، كل تفاعل في بطاقة (Interaction Card) توضح: الدوائين المتفاعلين، شدة التفاعل، التأثير، والتوصية. استخدام ألوان مختلفة للبطاقات أو مؤشرات بصرية لتمييز شدة التفاعل.
*   **شاشة الاشتراك (SubscriptionScreen):**
    *   عرض حالة الاشتراك الحالية للمستخدم (مجاني/مميز).
    *   عرض بطاقات لخطط الاشتراك المتاحة (حالياً خطة شهرية واحدة Premium)، توضح: اسم الخطة، السعر، الميزات.
    *   زر "اشترك الآن" لكل خطة.
    *   زر "استعادة المشتريات السابقة".
*   **شاشات Onboarding (اختياري - Task 6.3.5):** تصميم 3-4 شاشات تعريفية بسيطة وجذابة تشرح الميزات الرئيسية (البحث، البدائل، حاسبة الجرعات، التفاعلات) مع صور أو رسوم توضيحية وزر "تخطي" و "التالي/تم".

---

## 3. الأصول المطلوبة (Assets):

*   **أيقونة التطبيق (App Icon):**
    *   تصميم أيقونة فريدة للتطبيق بدقة عالية (1024x1024).
    *   توفير نسخ مختلفة الأحجام المطلوبة لمنصات Android و iOS.
    *   توفير تصميم للأيقونات التكيفية (Adaptive Icons) لـ Android (Foreground و Background).
*   **شعار شاشة البداية (Splash Screen Logo):**
    *   تصميم شعار (أو استخدام أيقونة التطبيق) لعرضه في منتصف شاشة البداية.
    *   توفير نسخة مناسبة للوضع الفاتح والداكن (إذا لزم الأمر).
*   **أيقونات الفئات (Category Icons):** تصميم أو اختيار أيقونات مميزة لكل فئة طبية رئيسية (مسكنات، مضادات حيوية، إلخ).
*   **صور/أيقونات توضيحية:** صور أو أيقونات لاستخدامها في شاشات Onboarding أو كعناصر نائبة (placeholders) لصور الأدوية.
*   **أيقونات الواجهة:** مجموعة أيقونات متناسقة للاستخدام داخل التطبيق (Bottom Navigation, AppBar Actions, List Tiles, Buttons, etc.).

---

## 4. المخرجات المطلوبة (Deliverables):

1.  **High-Fidelity Mockups:** تصميمات نهائية عالية الدقة لجميع الشاشات المذكورة أعلاه، مع مراعاة الوضع الفاتح (Light Mode) والوضع الداكن (Dark Mode).
2.  **Style Guide:** وثيقة دليل الأسلوب تحتوي على:
    *   لوحة الألوان الكاملة (Primary, Secondary, Accent, Backgrounds, Text Colors - Light & Dark).
    *   مواصفات الخطوط (Font Family, Sizes, Weights) للعربية والإنجليزية.
    *   مبادئ التباعد والهوامش (Spacing & Padding Guidelines).
    *   تصميم المكونات الرئيسية (Buttons, Cards, Input Fields, Chips, Tabs, Bottom Navigation) مع تحديد حالاتها المختلفة (Default, Hover, Pressed, Disabled).
3.  **Exported Assets:** جميع الأصول الرسومية (أيقونة التطبيق بجميع الأحجام المطلوبة، شعار Splash، أيقونات الفئات، أيقونات الواجهة، أي صور توضيحية) بصيغ مناسبة (SVG للمتجهات، PNG للصور النقطية).
4.  **(اختياري) Prototype HTML/CSS:** نماذج أولية بسيطة باستخدام HTML/CSS لبعض المكونات المعقدة أو تخطيطات الشاشات الرئيسية لتوضيح التفاعلات أو التصميم المتجاوب بشكل أفضل (إذا كان ذلك سيساعد في توضيح التصميم).

**تذكير:** التركيز الأساسي على **التصميم المرئي ودليل الأسلوب والأصول**، وليس على كود التطبيق النهائي.