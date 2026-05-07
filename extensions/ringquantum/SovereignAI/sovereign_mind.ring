# ====================================================================
# [SOVEREIGN MIND - THE CORE ENTITY]
# Unified Architecture connecting RingML, RingQuantum, and AlQalam.
# ====================================================================

# 1. Load the Universal Components
load "../quantum_transformer.ring"
load "Tokenizer.ring"


decimals(6)
# SetQuantumThreads(GetQuantumCores()) 
# EnableQuantumGPU(0)
# SetQuantumGPUThreshold(999999)

class SovereignMind

    # Cognitive Parameters (Balanced for Stability)
    nQubits    = 512  
    nHeads     = 1    
    nDimension = 4096 
    nBatch     = 1
    nLearningRate = 0.3
    nEpochs = 10
    aShifts = [157, 311, 467, 619, 773]
    
    # Core Components
    oQuantumEngine      
    oTokenizer          
    aFingerprintCache = []
    
    # Telemetry
    bDebug = true

    # Persistent Buffers for Zero-Copy Batch Training
    oInputBatch  = NULL
    oTargetBatch = NULL
    nBatchSize   = 32

    func init()
        oTokenizer = new Tokenizer()
        
        # 1.5. إعداد البنية التحتية الكوانتومية (Dynamic Sizing)
        # نرسل البعد المطلوب (nDimension) إلى الـ C لضمان تخصيص الذاكرة الصحيح
        quantum_set_dimension(nDimension)
        
        # 2. تهيئة المحرك الكوانتومي لبناء مصفوفة التداخل (Associative Memory)
        # هذا الاستدعاء ضروري لتخصيص الذاكرة في الـ C
        oQuantumEngine = new QuantumTransformer(nQubits, nBatch)
        oQuantumEngine.AddLayer(nHeads, nDimension)
        
        aFingerprintCache = []

        # 3. Initialize Persistent Buffers for Batch Training
        oInputBatch  = new QalamVector(nDimension * nBatchSize)
        oTargetBatch = new QalamVector(nDimension * nBatchSize)

        return self 

    func getInfo
        see "[Sovereign Mind] Cognitive Status:" + nl
        see "    Qubits: " + nQubits + nl
        see "    Heads: " + nHeads + nl
        see "    Dimension: " + nDimension + nl
        see "    Batch: " + nBatch + nl
        see "    Learning Rate: " + nLearningRate + nl
        see "    Epochs: " + nEpochs + nl
        see "    Vocabulary Size: " + oTokenizer.nVocabSize + nl
        return true
    
    # --- SENSING & ABSORPTION (Hebbian Atomic Etching) ---
    func AbsorbText(cText)
        cText = lower(cText) 
        oTokenizer.buildVocab([cText])
        aIds = oTokenizer.encode(cText)
        nlenaIds = len(aIds)
        

        # إذا كان النص قصيراً (أقل من 64 كلمة)، استخدم التعلم الفردي القديم
        if nlenaIds < 64
            for ep = 1 to nEpochs
                aWindow = []
                for i = 1 to nlenaIds
                    nId = aIds[i]
                    oTarget  = getQubitFingerprint(nId)
                    oContext = getContextWave(aWindow)
                    
                    # المسار القديم (Individual)
                    oQuantumEngine.UpdateTDVP(oContext, oTarget, nLearningRate)
                    
                    # زحزحة النافذة
                    aWindow + nId
                     
                    if len(aWindow) > 5 del(aWindow, 1) ok
                next
            next
            return
        ok

        # إذا كان النص طويلاً، انتقل آلياً للمسار الدفعي (Batch Mode)
        nBatchCount = 0

        for ep = 1 to nEpochs
            aWindow = []
            for i = 1 to nlenaIds
                nId = aIds[i]
                oTarget  = getQubitFingerprint(nId)
                oContext = getContextWave(aWindow)

                # نقل سريع جداً داخل الذاكرة (Memcpy - Zero-Copy)
                oInputBatch.copySegment(oContext, nBatchCount * nDimension)
                oTargetBatch.copySegment(oTarget, nBatchCount * nDimension)
                
                nBatchCount = nBatchCount + 1

                if nBatchCount = nBatchSize
                    # تمرير العناوين الفيزيائية مباشرة للمحرك (Zero-Copy)
                    oQuantumEngine.UpdateBatch(oInputBatch, oTargetBatch, nBatchSize, nLearningRate)
                    nBatchCount = 0
                ok

                # زحزحة النافذة
                aWindow + nId
                if len(aWindow) > 5 del(aWindow, 1) ok
            next
        next

        # معالجة ما تبقى في البفر (إذا لم يمتلئ بالكامل في الطلقة الأخيرة)
        if nBatchCount > 0
             oQuantumEngine.UpdateBatch(oInputBatch, oTargetBatch, nBatchCount, nLearningRate)
        ok

    func getContextWave(aWindow)
        oBuffer = new QalamVector(nDimension)
        quantum_holographic_bind(oBuffer.getRawPointer(), 
                                 oTokenizer.oSpectralBuffer.getRawPointer(), 
                                 aWindow, 
                                 nDimension)
        oBuffer.normalise()
        return oBuffer

    func LearnFromInteraction(cUserSentence)
        # هذا هو التعلم الفردي الذي لا يحتاج لبفر
        # يستخدم المسار القديم لتعديل العقل لحظياً
        AbsorbText(cUserSentence) 
        see "[Mind] New concept absorbed instantly." + nl
        
    func PermuteWave oWave, nPos
        # معامل إزاحة كبير لضمان تفرد الترددات (Prime 79)
        nShift = (nPos * 79) % nDimension
        return oWave.rotate(nShift) 
    
        
    func AbsorbFile(cFilePath)
        if !fexists(cFilePath)
            return false
        ok
        cFileContent = read(cFilePath)
        AbsorbText(cFileContent)
        return true

    # --- BRAIN PRESERVATION (SAVE & LOAD) ---
    # ميزة الحفظ المزدوج (Double Saving System) لضمان سلامة البيانات
    func SaveMind(cFileName)
        oStyl.yellow(:DIM, "  [Storage] Initiating Double-Save Protocol..." + nl)
        
        # 1. إنشاء نسخة احتياطية (Shadow Backup) قبل الكتابة الجديدة
        if fexists(cFileName + "_vocab.bin")
            system("copy " + cFileName + "_vocab.bin " + cFileName + "_vocab.bak > nul")
            system("copy " + cFileName + "_wq.tensor " + cFileName + "_wq.bak > nul")
        ok

        # 2. حفظ الذاكرة اللغوية (The Dictionary)
        oTokenizer.saveVocab(cFileName + "_vocab.bin")
        
        # 3. حفظ مصفوفات الوعي الكاملة (All Tensors)
        # نقوم بحفظ كل من القسم الحقيقي والخيالي لضمان استعادة الحالة بنسبة 100%
        oQuantumEngine.W_q_re.saveFile(cFileName + "_wq.tensor")
        oQuantumEngine.W_q_im.saveFile(cFileName + "_wi.tensor")
        oQuantumEngine.W_k_re.saveFile(cFileName + "_wk.tensor")
        oQuantumEngine.W_k_im.saveFile(cFileName + "_ki.tensor")
        oQuantumEngine.W_v_re.saveFile(cFileName + "_wv.tensor")
        oQuantumEngine.W_v_im.saveFile(cFileName + "_vi.tensor")
        
        # 4. حفظ أطوار الهاملتوني (The Hamiltonian Amplitudes)
        oQuantumEngine.Head_amp.saveFile(cFileName + "_hamp.tensor")
        oQuantumEngine.Head_phase.saveFile(cFileName + "_hphase.tensor")
        
        return true
    
    func LoadMind(cFileName)
        # التحقق من وجود الملفات الأساسية
        if !fexists(cFileName + "_vocab.bin") return false ok
        if !fexists(cFileName + "_wq.tensor") return false ok
        
        try
            # 1. استعادة القاموس اللغوي
            oTokenizer.loadVocab(cFileName + "_vocab.bin")
            
            # 2. شحن مصفوفات الكوانتوم (Zero-Copy Bulk Load)
            oQuantumEngine.W_q_re.loadFile(cFileName + "_wq.tensor")
            if fexists(cFileName + "_wi.tensor") oQuantumEngine.W_q_im.loadFile(cFileName + "_wi.tensor") ok
            
            oQuantumEngine.W_k_re.loadFile(cFileName + "_wk.tensor")
            if fexists(cFileName + "_ki.tensor") oQuantumEngine.W_k_im.loadFile(cFileName + "_ki.tensor") ok
            
            oQuantumEngine.W_v_re.loadFile(cFileName + "_wv.tensor")
            if fexists(cFileName + "_vi.tensor") oQuantumEngine.W_v_im.loadFile(cFileName + "_vi.tensor") ok
            
            oQuantumEngine.Head_amp.loadFile(cFileName + "_hamp.tensor")
            if fexists(cFileName + "_hphase.tensor") oQuantumEngine.Head_phase.loadFile(cFileName + "_hphase.tensor") ok
            
            # 3. تصفير الذاكرة المؤقتة (Clear Interference Patterns)
            aFingerprintCache = []
            return true
        catch
            oStyl.red(:BOLD, "  [!] Load Error: Main memory corrupted. Trying backup..." + nl)
            if fexists(cFileName + "_vocab.bak")
                return LoadMindFromBackup(cFileName)
            ok
        done
        return false

    func LoadMindFromBackup(cFileName)
        # محاولة أخيرة للاستعادة من ملف الباك اب
        oTokenizer.loadVocab(cFileName + "_vocab.bak")
        oQuantumEngine.W_q_re.loadFile(cFileName + "_wq.bak")
        return true

    # --- THINKING & INFERENCE (Holographic Context Generator) ---
    func Think(cWord)
        cWord = lower(cWord)
        aIds = oTokenizer.encode(cWord)
        if len(aIds) = 0 return "? (Silence)" ok
        
        # 1. المرحلة الأولى: بناء هولوجرام مكاني محاذى لليمين
        aWindow = []
        for nID in aIds 
            aWindow + nID 
            if len(aWindow) > 5 del(aWindow, 1) ok 
        next
        
        oContextHolo = new QalamVector(nDimension)
        nLen = len(aWindow)
        for k = 1 to nLen
            nDistance = nLen - k + 1
            oPosWave = getQubitFingerprint(aWindow[k]).rotate(aShifts[6 - nDistance])
            nWeight = (k * 1.0) / nLen
            oContextHolo.process(42, oPosWave.pPtr, nWeight, 0) 
        next
        oContextHolo.normalise()
        
        cOutputSentence = ""
        nVoSize = oTokenizer.nVocabSize 
        aUsedIds = []
        
        # 2. المرحلة الثانية: الاستنتاج بالرنين الكوانتومي (INT8 Engine)
        oQuantWave = new QalamVector(128) # 1024 Bytes for INT8
        
        for s = 1 to 50 
            # استنتاج "الكلمة التالية" من زخم الهولوجرام
            oResultWave = oQuantumEngine.Inference(oContextHolo, 0.1, 0.1)
            # oResultWave.amplify(5.0)
            # شحذ الرنين (Resonance Sharpening)
            oResultWave.process(45, 0, 3.0, 0)
            
            # ضغط متجه النتيجة للتحويل لـ INT8 المكمم
            quantum_quantize(oResultWave.getRawPointer(), 
                             oQuantWave.getRawPointer(), 
                             nDimension)
            
            # البحث السريع في C (INT8 Optimization)
            oTopIds = new QalamVector(5)
            if s = 1
                oUsedVec = new QalamVector(oTokenizer.nVocabSize +10)
                for nID in aIds oUsedVec.write(nID, 1.0) next
                oQuantizedCache = oTokenizer.updateQuantizedCache(nDimension)
            ok
            
            # البحث باستخدام نواة الـ INT8 الفائقة
            quantum_find_best_int8(oQuantWave.getRawPointer(), 
                                   oQuantizedCache.getRawPointer(), 
                                   nVoSize, 
                                   oTopIds.getRawPointer(), 
                                   oUsedVec.getRawPointer())
            
            aTopCandidates = []
            for k = 1 to 5
                nID = oTopIds.read(k)
                if nID > 0 aTopCandidates + nID ok
            next
            
            if len(aTopCandidates) > 0
                nMaxIdx = aTopCandidates[1] 
                cToken = oTokenizer.getTokenFromId(nMaxIdx)
                # see "[Sovereign Mind] Generated: " + cToken + nl

                if cToken != "<PAD>" and cToken != "<UNK>"
                    
                    cOutputSentence += cToken + " "
                    aUsedIds + nMaxIdx
                    
                    # منع تكرار الكلمة في الدورات القادمة (Update Blackout Mask)
                    oUsedVec.write(nMaxIdx, 1.0)
                    
                    # تحديث النافذة والهولوجرام المكاني
                    aWindow + nMaxIdx
                    if len(aWindow) > 5 del(aWindow, 1) ok
                    
                    oContextHolo = new QalamVector(nDimension)
                    nLen = len(aWindow)
                    for k = 1 to nLen
                        nDistance = nLen - k + 1
                        oPosWave = getQubitFingerprint(aWindow[k]).rotate(aShifts[6 - nDistance])
                        nWeight = (k * 1.0) / nLen
                        oContextHolo.process(42, oPosWave.pPtr, nWeight, 0) 
                    next
                    oContextHolo.normalise()
                else
                    exit
                ok
            else
                exit
            ok
        next
        
        if len(cOutputSentence) = 0
            return "? (Low Resonance - Signal Lost)"
        ok
        
        return cOutputSentence

    # --- HILBERT SPACE EMBEDDING ---
    func getQubitFingerprint(nID)
        # استدعاء البصمة الفورييرية مباشرة من الـ Tokenizer
        if nID > 0 and nID <= len(oTokenizer.aSpectralCache)
            return oTokenizer.aSpectralCache[nID]
        ok
        
        # Fallback (Should not happen with proper tokenization)
        oVec = new QalamVector(nDimension)
        for d = 1 to nDimension
            nPhase = (nID * 13.73 * d) + (d * 8.19)
            oVec.write(d, sin(nPhase))
        next
        return oVec
        
    # دالة الربط الهولوجرافي (Circular Convolution via FFT)
    func BindContext(oWaveA, oWaveB)
        # تحويل كلاهما للمجال الترددي (1024 نقطة)
        oSpecA = new QalamVector(nDimension*2)
        oSpecB = new QalamVector(nDimension*2)
        quantum_fft(oWaveA.getRawPointer(), oSpecA.getRawPointer())
        quantum_fft(oWaveB.getRawPointer(), oSpecB.getRawPointer())
        
        # الضرب المعقد في فضاء التردد (Pointwise Complex Multiplication)
        oSpecResult = new QalamVector(nDimension*2)
        for i = 1 to nDimension
            reA = oSpecA.read(i*2-1)
            imA = oSpecA.read(i*2)
            reB = oSpecB.read(i*2-1)
            imB = oSpecB.read(i*2)
            
            # (a+bi)*(c+di) = (ac-bd) + (ad+bc)i
            oSpecResult.write(i*2-1, (reA*reB - imA*imB))
            oSpecResult.write(i*2, (reA*imB + imA*reB))
        next
        
        # العودة لمجال الزمن (IFFT) لاستخراج الكيان الجديد
        oResult = new QalamVector(nDimension)
        quantum_ifft(oSpecResult.getRawPointer(), oResult.getRawPointer())
        
        # موازنة الطاقة لضمان ثبات الإشارة
        nNorm = oResult.norm()
        if nNorm > 0.0001 oResult.amplify(1.0/nNorm) ok
        
        return oResult
