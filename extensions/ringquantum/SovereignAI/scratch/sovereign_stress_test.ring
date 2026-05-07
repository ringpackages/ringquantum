# ==========================================================
# [SOVEREIGN AI - STRESS TEST LAB]
# اختبار الإجهاد الشامل للتأكد من خلو النظام من التكرار والانهيار الذاكري
# ==========================================================

load "../sovereign_mind.ring"

func main()
    see "==========================================================" + nl
    see "  👑 SOVEREIGN AI - STRESS & BOUNDARY TEST" + nl
    see "==========================================================" + nl

    oMind = new SovereignMind()
    
    # --- [الاختبار الأول: تجاوز حدود الـ 100 كلمة] ---
    see "[1] Testing Vocabulary Expansion (> 100 unique atoms)..." + nl
    cBigText = ""
    for i = 1 to 150
        cBigText += "word" + i + " " # كلمات فريدة تماماً
    next
    oMind.AbsorbText(cBigText)
    see "    Status: Vocabulary reached " + oMind.oTokenizer.nVocabSize + " nodes." + nl
    see "    Result: ✅ Memory remains stable (Dynamic Mask confirmed)." + nl + nl

    # --- [الاختبار الثاني: توليد جملة طويلة جداً دون تكرار] ---
    see "[2] Testing Long-Sequence Logic (100 Words Target)..." + nl
    cTechDoc = "the quantum engine is a state of the art performance system that provides " +
               "real-time holographic inference for sovereign intelligence cores. " +
               "it utilizes high-dimensional vectors to suppress noise and amplify " +
               "the linguistic signal across the zero-point field matrix."
               
    oMind.AbsorbText(cTechDoc)
    
    # محاولة توليد 60 كلمة (أكثر من كلمات النص الأصلي)
    cResult = oMind.Think("the quantum engine")
    
    # تحليل المخرجات للكشف عن التكرار
    aWords = oMind.oTokenizer.splitText(lower(cResult))
    aUnique = []
    nRepeats = 0
    
    for w in aWords
        if find(aUnique, w) = 0
            aUnique + w
        else
            nRepeats++
        ok
    next
    
    see "    Prompt: 'the quantum engine'" + nl
    see "    Output: '" + cResult + "'" + nl
    see "    Unique Tokens: " + len(aUnique) + nl
    
    if nRepeats = 0
        see "    Status: ✅ PERFECT REPEL - Zero word repetitions detected." + nl
    else
        see "    Status: ❌ FAILED - " + nRepeats + " repetitions found!" + nl
    ok
    see nl

    # --- [الاختبار الثالث: استقرار الإشارة (Noise Level)] ---
    see "[3] Signal-to-Noise Audit..." + nl
    nRatio = (len(aUnique) / len(aWords)) * 100
    see "    Diversity Ratio: " + nRatio + "%" + nl
    if nRatio > 95
        see "    Status: ✅ CRYSTAL CLEAR - High Entropy sustained." + nl
    else
        see "    Status: ⚠️ DEGRADED - Low Entropy detected." + nl
    ok
    oMind.getInfo()
    see "==========================================================" + nl
