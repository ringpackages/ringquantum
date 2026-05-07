/*
    Project: Jabr
    File: src/core/Tokenizer.ring
    Description: High-Speed WORD-LEVEL Tokenizer using AlQalam HashMap
*/

class Tokenizer

    # --- Configuration ---
    aSpecialTokens
    nVocabSize
    nDimension = 4096
    nActiveBits = 192
    # --- QUANTIZATION ENGINE (INT8) ---
    oQuantizedBuffer 

    # --- The Engine (C++ HashMap + Unified Spectral Memory) ---
    oIndexMap      = new QalamIndex() # String -> ID
    aSpectralCache = []                # ID -> Spectral Vector (For Ring side)
    oSpectralBuffer = new QalamVector(nDimension * 10000) # Pre-allocate flat memory
    
    func init
        aSpecialTokens = []
        nVocabSize     = 0
        
        # Reserve core tokens to prevent collision with regular words
        addToken("<PAD>") # Will get ID 1
        addToken("<UNK>") # Will get ID 2
        
        return self
    
    func addToken cToken
        nVocabSize++
        oIndexMap.define(cToken, nVocabSize)
        
        # --- Generate High-Entropy Sparse Fingerprint ---
        oFingerprint = new QalamVector(nDimension)
        
        # واستخدامه لتحديث البفر الموحد مباشرة (Zero-Copy)
        # نمرر عنوان البداية للكلمة الحالية داخل البفر الضخم
        # ملاحظة: في رينج نضرب الإزاحة في 8 لأن العنوان هو بايتات (Address in bytes)
        nBufferOffset = (nVocabSize-1) * nDimension * 8
        nTargetAddr   = oSpectralBuffer.getRawPointer() + nBufferOffset

        # استخدام الكرنل الفائق لملء البصمة (C-Speed)
        quantum_fast_fingerprint(oFingerprint.getRawPointer(), cToken, nDimension, nActiveBits)
        quantum_fast_fingerprint(nTargetAddr, cToken, nDimension, nActiveBits)
        
        aSpectralCache + oFingerprint
        return oFingerprint

    # The Most Robust Splitter (Standard Word-level Segmentation)
    func splitText cText
        aTokens = []
        cWord = ""
        nLen = len(cText)
        # We explicitly handle characters by their ASCII to avoid UTF-8 issues in split
        for i = 1 to nLen
            nCode = ascii(cText[i])
            # Space or Control Chars
            if nCode <= 32 
                if len(cWord) > 0 aTokens + cWord cWord = "" ok
            # ASCII Punctuation
            elseif (nCode >= 33 and nCode <= 47) or 
                    (nCode >= 58 and nCode <= 64) or 
                    (nCode >= 91 and nCode <= 96) or 
                    (nCode >= 123 and nCode <= 126)
                if len(cWord) > 0 aTokens + cWord cWord = "" ok
                aTokens + cText[i]
            # UTF-8 or Extended ASCII (Treat as Word Starters)
            elseif nCode > 127
                # إذا وجدنا بايت عالي (UTF-8)، نعتبره بداية كلمة أو جزءاً منها
                cWord += cText[i]
            # Normal Word Character
            else
                cWord += cText[i]
            ok
        next
        if len(cWord) > 0 aTokens + cWord ok
        return aTokens

    func buildVocab aTextList
        see "[Tokenizer] Absorbing Linguistic Spectrum..." + nl
        nNew = 0
        for cText in aTextList
            aTokens = splitText(lower(cText))
            for tk in aTokens 
                if oIndexMap.recall(tk) = 0
                    addToken(tk)
                    nNew++
                    # see "    (+) Registered: " + tk + nl
                ok
            next
        next
        see "[Tokenizer] Sequence Captured: " + nNew + " New Atoms." + nl
        see "    Status: Cognitive Map Expanded to " + nVocabSize + " Nodes." + nl

    func encode cText
        aIds = []
        aTokens = splitText(lower(cText))
        for tk in aTokens
            nId = oIndexMap.recall(tk)
            if nId > 0
                aIds + nId
            else
                aIds + 2 # <UNK>
            ok
        next
        return aIds

    func decode aIds
        cStr = ""
        for id in aIds
            cStr += getTokenFromId(id) + " "
        next
        return cStr

    func getTokenId cToken
        nId = oIndexMap.recall(cToken)
        if nId = 0 return 2 ok # UNK
        return nId

    func getTokenFromId nId
        if nId > 0 and nId <= nVocabSize
            return oIndexMap.recallKey(nId)
        ok
        return "<UNK>"

    # --- STREAMING ENGINE (For Giant Data) ---
    func streamAbsorb cFilePath
        if !fexists(cFilePath) return false ok
        fp = fopen(cFilePath, "r")
        nNew = 0
        cWord = ""
        while !feof(fp)
            cChar = fgetc(fp)
            nCode = ascii(cChar)
            # تقسيم ذكي للكلمات (Space/Punctuation)
            if nCode <= 32 or (nCode >= 33 and nCode <= 47)
                if len(cWord) > 0
                    if oIndexMap.recall(lower(cWord)) = 0
                        addToken(lower(cWord))
                        nNew++
                    ok
                    cWord = ""
                ok
            else
                cWord += cChar
            ok
        end
        fclose(fp)
        see "[Tokenizer] Stream Finished. Captured: " + nNew + " New Atoms from File." + nl
        return true
        
    func updateQuantizedCache nDim
        nTotalElements = nVocabSize * nDim
        # حجز مساحة كافية (كل double يتسع لـ 8 قيم INT8)
        if isNull(oQuantizedBuffer) or (oQuantizedBuffer.size() < (nTotalElements / 8))
            oQuantizedBuffer = new QalamVector(nTotalElements / 8 + 1)
        ok
        # استدعاء الدالة الجديدة (طلقة واحدة)
        quantum_batch_quantize(oSpectralBuffer.getRawPointer(), 
                               oQuantizedBuffer.getRawPointer(), 
                               nVocabSize, 
                               nDim)
        return oQuantizedBuffer

    func saveVocab cFilePath
        oIndexMap.saveBinary(cFilePath)

    func loadVocab cFilePath
        oIndexMap.loadBinary(cFilePath)
        nVocabSize = oIndexMap.size()
        for i = 1 to nVocabSize
            cToken = oIndexMap.recallKey(i)
            oIndexMap.define(cToken, i)
        next