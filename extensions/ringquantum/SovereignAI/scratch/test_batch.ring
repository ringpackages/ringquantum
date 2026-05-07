load "../sovereign_mind.ring"

# 1. إعداد المحرك (Initialization)
oMind = new SovereignMind()

# 2. تجربة التعلم من التفاعل اللحظي (LearnFromInteraction)
# يتم استخدام المسار الفردي هنا
see "--- Test 1: Real-time Interaction (Individual Mode) ---" + nl
oMind.LearnFromInteraction("مرحباً بك في نظام العقل السيادي.")
oMind.LearnFromInteraction("أنا أتعلم من كلماتك الآن بسرعة كبيرة.")

# 3. تجربة التعلم الدفعي (Batch Training)
# سنقوم بإنشاء نص طويل (أكثر من 64 كلمة) لتفعيل وضع الدفعات (Batch Mode) آلياً
see "--- Test 2: Batch Training (Ultra Fast - Zero-Copy) ---" + nl

cBigText = ""
for i = 1 to 10
    cBigText += "في هذا الاختبار الجديد نقوم بتجربة تقنية الزيرو كوبي لنقل البيانات بسرعة البرق بين معالج القلم والمحرك الكمي. "
    cBigText += "هذا النص مصمم خصيصاً ليكون طويلاً بما يكفي لتجاوز عتبة الـ 64 كلمة وتنشيط وضع التدريب الدفعي آلياً داخل المحرك. "
    cBigText += "نحن نستخدم الآن قوة المعالجة المتوازية وقوة النسخ المباشر للذاكرة لضمان أداء استثنائي. "
next

# قياس الوقت باستخدام كرونوس (The Pen Timer)
oTimer = new QalamChronos()
oMind.AbsorbText(cBigText)
see "Batch Training Finished in: " + oTimer.elapsed() + nl

# 4. تجربة الاستنتاج (Inference)
see "--- Test 3: Thinking & Resonance ---" + nl
see "Sovereign Mind Thinking about (نظام العقل): "
cResponse = oMind.Think("نظام العقل")
see cResponse + nl

see "--- All Tests Completed Successfully ---" + nl
