# ====================================================================
# [SOVEREIGN AI - BILINGUAL COHERENCE TEST]
# File: scratch/debug.ring
# ====================================================================

load "../sovereign_mind.ring"

func main()
    see "==========================================================" + nl
    see "  👑 SOVEREIGN AI - BILINGUAL STABILITY TEST" + nl
    see "==========================================================" + nl

    oMind = new SovereignMind()

    # --- [TEST 1: ENGLISH CONTEXT] ---
    see "[1] Learning English Core..." + nl
    cEnglish = "the sovereign ai is a matrix-free engine for real-time inference"
    oMind.AbsorbText(cEnglish)
    
    see "    Query: 'the sovereign ai'" + nl
    cRes1 = oMind.Think("the sovereign ai")
    see "    AI: '" + cRes1 + "'" + nl
    
    # --- [TEST 2: ARABIC CONTEXT] ---
    see nl + "[2] Learning Arabic Core..." + nl
    cArabic = "جبرائيل هو محرك ذكاء اصطناعي سيادي يستخدم الذاكرة الهولوجرافية"
    oMind.AbsorbText(cArabic)
    
    see "    Query: 'جبرائيل هو'" + nl
    cRes2 = oMind.Think("جبرائيل هو")
    see "    AI: '" + cRes2 + "'" + nl

    # --- [JUDGMENT] ---
    see nl + "[3] FINAL JUDGMENT:" + nl
    
    bEngOk = (substr(lower(cRes1), "matrix-free") > 0 or substr(lower(cRes1), "engine") > 0)
    bArOk  = (substr(cRes2, "محرك") > 0 or substr(cRes2, "سيادي") > 0)
    
    if bEngOk and bArOk
        see "✅ [SUCCESS] Sovereign Intelligence is Multi-Lingual and Stable!" + nl
    elseif bEngOk
        see "⚠️ [PARTIAL] English is stable, but Arabic showed interference." + nl
    elseif bArOk
        see "⚠️ [PARTIAL] Arabic is stable, but English showed interference." + nl
    else
        see "❌ [FAILED] Total Holographic Distortion detected." + nl
    ok
    see "==========================================================" + nl
