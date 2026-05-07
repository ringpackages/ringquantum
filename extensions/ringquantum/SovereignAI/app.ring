# ====================================================================
# [SOVEREIGN AI - INTERFACE TERMINAL]
# ====================================================================

load "sovereign_mind.ring"

# Force Windows Terminal to accept UTF-8 inputs from keyboard (Arabic Support)
# system("chcp 65001 > nul")

oStyl.cyan(:BOLD, nl + "==========================================================" + nl)
oStyl.cyan(:BOLD, "  👑 SOVEREIGN AI (V1.0 - Matrix-Free 100-Qubit Core)  " + nl)
oStyl.cyan(:BOLD, "==========================================================" + nl)

oStyl.yellow(:DIM, "  Booting Quantum Tensor Arrays..." + nl)
oMind = new SovereignMind()

if oMind.LoadMind("memory/brain")
    oStyl.magenta(:BOLD, "  System Online. Prior Knowledge Restored! (Vocab: " + oMind.oTokenizer.nVocabSize + ")" + nl)
else
    oStyl.green(:BOLD, "  System Online. Blank Slate. Awaiting Knowledge." + nl)
ok

oStyl.white(:DIM, "  [Commands] /learn <text>, /read <file>,/askfile <file> /ask <word>, /exit /debug on /debug off" + nl + nl)

while true
    see "Sovereign> "
    cInput = input()
    cInput = trim(cInput)
    if len(cInput) = 0 loop ok
    
    # تحويلة سريعة لحل مشكلة اللغة العربية في Cmder
    if lower(cInput) = "/q"
        if fexists("q.txt")
            cInput = "/askfile q.txt"
        else
            oStyl.red(:DIM, "  [!] Please create 'q.txt' in the folder, write your Arabic there, and save!" + nl)
            loop
        ok
    ok
    
    if lower(cInput) = "/exit"
        oStyl.yellow(:DIM, "Shutting down Hilbert Space..." + nl)
        bye
    ok
    
    if lower(cInput) = "/info"
        oMind.getInfo()
        loop
    ok

    if lower(cInput) = "/save"
        oMind.SaveMind("memory/brain")
        oStyl.green(:BOLD, "  [+] Manual Save Point Created Successfully." + nl)
        loop
    ok

    if lower(cInput) = "/clear"
        oStyl.red(:BOLD, "  [!] WARNING: Wipe all memories? (Y/N): ")
        ans = input()
        if lower(ans) = "y"
            oMind = new SovereignMind()
            oStyl.magenta(:BOLD, "  [!] Neural Matrix Reset to Factory Zero." + nl)
        ok
        loop
    ok

    if left(lower(cInput), 6) = "/learn"
        cText = trim(substr(cInput, 7))
        if left(cText, 1) = ":" cText = trim(substr(cText, 2)) ok
        if len(cText) > 0
            oStyl.cyan(:DIM, "  [+] Absorbing Phase Frequencies..." + nl)
            oLearnTimer = new QalamChronos()
            oMind.AbsorbText(cText)
            cLearnTime = oLearnTimer.elapsed()
            
            # --- Auto-Save (Double Protocol) ---
            oMind.SaveMind("memory/brain")
            oStyl.green(:BOLD, "  [+] Knowledge Absorbed. (Vocab: " + oMind.oTokenizer.nVocabSize + " / Time: " + cLearnTime + ")" + nl)
        else
            oStyl.red(:DIM, "  [!] Syntax: /learn your sentence here." + nl)
        ok
        loop
    ok

    if left(lower(cInput), 5) = "/read"
        cFile = trim(substr(cInput, 6))
        if len(cFile) > 0
            oStyl.cyan(:DIM, "  [+] Scanning and Loading File: " + cFile + " ..." + nl)
            oLearnTimer1 = new QalamChronos()
            if oMind.AbsorbFile(cFile)
                cLearnTime1 = oLearnTimer1.elapsed()
                # --- Auto-Save ---
                oMind.SaveMind("memory/brain")
                oStyl.green(:BOLD, "  [+] Data Absorbed Successfully! (Vocab: " + oMind.oTokenizer.nVocabSize  + " / Time: " + cLearnTime1 + ")" + nl)
            else
                oStyl.red(:BOLD, "  [!] Error: File not found (" + cFile + ")" + nl)
            ok
        else
            oStyl.red(:DIM, "  [!] Syntax: /read filename.txt" + nl)
        ok
        loop
    ok

    if left(lower(cInput), 8) = "/askfile"
        cFile = trim(substr(cInput, 9))
        if len(cFile) > 0 and fexists(cFile)
            cWord = trim(read(cFile))
            # Clean Input
            if left(lower(cWord), 6) = "/ask :" cWord = trim(substr(cWord, 7)) ok
            if left(lower(cWord), 5) = "/ask " cWord = trim(substr(cWord, 6)) ok
            if left(cWord, 1) = ":" cWord = trim(substr(cWord, 2)) ok
            
            if len(cWord) > 0
                oStyl.yellow(:DIM, "  [?] Resonating state for '" + cWord + "'..." + nl)
                oTimer = new QalamChronos()
                cResponse = oMind.Think(cWord)
                cTime = oTimer.elapsed()
                oStyl.cyan(:BOLD, "  [*] Output: " + cResponse + nl)
                oStyl.magenta(:DIM, "  [~] Speed: " + cTime + nl)
            ok
        else
            oStyl.red(:DIM, "  [!] Syntax: /askfile query.txt (File must exist)" + nl)
        ok
        loop
    ok

    if left(lower(cInput), 4) = "/ask"
        cWord = trim(substr(cInput, 5))
        if left(cWord, 1) = ":" cWord = trim(substr(cWord, 2)) ok
        if len(cWord) > 0
            oStyl.yellow(:DIM, "  [?] Resonating state for '" + cWord + "'..." + nl)
            oTimer = new QalamChronos()
            cResponse = oMind.Think(cWord)
            cTime = oTimer.elapsed()
            oStyl.cyan(:BOLD, "  [*] Output: " + cResponse + nl)
            oStyl.magenta(:DIM, "  [~] Speed: " + cTime + nl)
        ok
        loop
    ok
    
    # الدردشة الطبيعية (استنتاج وتفاعل حي)
    aInputWords = split(cInput, " ")
    if len(aInputWords) > 0
        # 1. الاستنتاج بناءً على آخر كلمة (Resonance)
        cResponse = oMind.Think(aInputWords[len(aInputWords)])
        oStyl.cyan(:BOLD, "  Sovereign: " + cResponse + nl)
        
        # 2. التعلم اللحظي من مدخلات المستخدم (Real-time Growth)
        oMind.LearnFromInteraction(cInput)
ok
end

