# ====================================================================
# [SOVEREIGN LEARNING LAB - EXPERIMENT V3]
# Theme: Contextual Grammar & Disambiguation
# ====================================================================

load "qubit_sovereign_core.ring"
oLab = new QubitSovereignCore()

aTrainingText = [
    "i am a quantum ai",    
    "you are a human user", 
    "what am i",            
    "who are you"           
]

oStyl.cyan(:BOLD, nl + "═══════════════════════════════════════════════" + nl)
oStyl.cyan(:BOLD, "  🧠 PHASE 1: GRAMMAR & CONTEXT ABSORPTION" + nl)
oStyl.cyan(:BOLD, "═══════════════════════════════════════════════" + nl)
oStyl.yellow(:BOLD, "  Learning 10 Epochs implicitly with lr=0.05..." + nl)

# 10 Epochs للتدريب المستقر
for nEpoch = 1 to 10
    for cSentence in aTrainingText
        aWords = split(cSentence, " ")
        oLab.absorb(aWords)
    next
next

oStyl.green(:BOLD, "  ✅ ABSORPTION COMPLETE." + nl)
oStyl.white(:DIM, "  Vocabulary Size: " + len(oLab.aWordMap) + " words" + nl)



# ====================================================================
oStyl.cyan(:BOLD, nl + "═══════════════════════════════════════════════" + nl)
oStyl.cyan(:BOLD, "  🔬 TEST 1: The 'i' Connection" + nl)
oStyl.cyan(:BOLD, "═══════════════════════════════════════════════" + nl)
oStyl.yellow(:BOLD, "  Query: After 'i' -> Expected: 'am'?" + nl)
nID = oLab.getWordID("i")
oInput = oLab.getEmbedding(nID)
aDecoded = decodeResult(oLab.predict(oInput), oLab)
oStyl.green(:BOLD, "  ➤ Prediction: [" + aDecoded[1] + "] (Score: " + aDecoded[2] + ")" + nl)

# ====================================================================
oStyl.cyan(:BOLD, nl + "═══════════════════════════════════════════════" + nl)
oStyl.cyan(:BOLD, "  🔬 TEST 2: The 'you' Connection" + nl)
oStyl.cyan(:BOLD, "═══════════════════════════════════════════════" + nl)
oStyl.yellow(:BOLD, "  Query: After 'you' -> Expected: 'are'?" + nl)
nID = oLab.getWordID("you")
oInput = oLab.getEmbedding(nID)
aDecoded = decodeResult(oLab.predict(oInput), oLab)
oStyl.green(:BOLD, "  ➤ Prediction: [" + aDecoded[1] + "] (Score: " + aDecoded[2] + ")" + nl)

# ====================================================================
oStyl.cyan(:BOLD, nl + "═══════════════════════════════════════════════" + nl)
oStyl.cyan(:BOLD, "  🔬 TEST 3: Interrogative Context ('what')" + nl)
oStyl.cyan(:BOLD, "═══════════════════════════════════════════════" + nl)
oStyl.yellow(:BOLD, "  Query: After 'what' -> Expected: 'am'?" + nl)
nID = oLab.getWordID("what")
oInput = oLab.getEmbedding(nID)
aDecoded = decodeResult(oLab.predict(oInput), oLab)
oStyl.green(:BOLD, "  ➤ Prediction: [" + aDecoded[1] + "] (Score: " + aDecoded[2] + ")" + nl)

# ====================================================================
oStyl.cyan(:BOLD, nl + "═══════════════════════════════════════════════" + nl)
oStyl.cyan(:BOLD, "  🔬 TEST 4: The Identity Equation ('human' + 'user')" + nl)
oStyl.cyan(:BOLD, "═══════════════════════════════════════════════" + nl)
oStyl.yellow(:BOLD, "  Query: 'human' + 'user' -> Can it guess anything related?" + nl)

nID_1 = oLab.getWordID("human")
nID_2 = oLab.getWordID("user")
oVec1 = oLab.getEmbedding(nID_1)
oVec2 = oLab.getEmbedding(nID_2)
oContext = new QalamVector(576)
oContext.flood(0)
for k = 1 to 576  # الآن نغطي كل الأبعاد
    oContext.write(k, oVec1.read(k) + oVec2.read(k))
next
aDecoded = decodeResult(oLab.predict(oContext), oLab)
oStyl.green(:BOLD, "  ➤ Prediction: [" + aDecoded[1] + "] (Score: " + aDecoded[2] + ")" + nl)

# دالة الاستخراج الصامتة
func decodeResult oResult, oLab
    nMaxVal = -999999
    nMaxIdx = 0
    for i = 1 to len(oLab.aWordMap)
        nScore = oResult.read(i)
        if nScore > nMaxVal
            nMaxVal = nScore
            nMaxIdx = i
        ok
    next
    if nMaxIdx > 0
        return [oLab.aWordMap[nMaxIdx], nMaxVal]
    ok
    return ["<silence>", 0]