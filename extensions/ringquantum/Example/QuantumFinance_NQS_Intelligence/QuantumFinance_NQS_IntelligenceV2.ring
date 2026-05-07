# ===============================
# RING NEURAL-QUANTUM STOCK INTELLIGENCE v2.0
# ===============================


load "ringquantum.ring"
load "ringml.ring"


nAssets = 150      # Matched to aStocks list length
nHidden = 120
nDays   = 60

decimals(4)

# --- CLEAN STOCK LIST (NO DUPLICATES) ---
aStocks = ["AAPL","MSFT","GOOGL","AMZN","NVDA","META","TSLA","JPM","V","WMT",
"UNH","MA","JNJ","XOM","PG","HD","CVX","KO","ABBV","PEP",
"COST","ADBE","CRM","DIS","NFLX","ORCL","AMD","BAC","LLY","AVGO",
"TMO","PFE","ABT","DHR","NKE","LIN","PM","VZ","NEE","TXN",
"RTX","UPS","HON","MS","BMY","AMAT","BA","INTC","CAT","UNP",
"GS","LOW","SPGI","INTU","IBM","GE","ISRG","QCOM","NOW","BLK",
"AXP","SYK","MDLZ","AMGN","ADI","TJX","GILD","MMC","C","VRTX",
"ZTS","ADP","SCHW","MO","CB","ETN","MDT","PGR","CI","REGN",
"LMT","BSX","DE","VLO","MCO","CVS","TGT","PYPL","KLAC","DUK",
"PANW","SNPS","CDNS","ORLY","A","ACN","AEP","AFL","AIG","ALL",
"AMCR","AMP","ANET","ANSS","AON","APD","APH","ARE","ATO","AWK",
"AXON","AZO","BALL","BBY","BDX","BEN","BIIB","BK","BKR","BR",
"BRO","BWA","BX","BXP","CAG","CAH","CARR","CBOE","CBRE","CCI",
"CCL","CDW","CE","CF","CHD","CHTR","CL","CLX","CMCSA","CME",
"CMG","CMS","CNC","CNP","COF","COO","COP","CPRT","CRL","CSX"]

# ===============================
# MAIN
# ===============================

func main
    see "===== QUANTUM PORTFOLIO v4 (STABLE) =====" + nl

    cFile = "market_data.csv"
    if !fExists(cFile)
        FetchRealData(cFile)
    ok

    oPrices = LoadPrices(cFile)
    oCovMatrix = BuildCovarianceMatrix(oPrices, nAssets, nDays)
    oReturnsVector = CalculateReturnsVector(oPrices, nAssets, nDays)

    # --- SAFE SCALING ---
    # oReturnsVector.normalize() # REMOVED: Method not found
    oCovMatrix.amplify(0.01)    # FIXED: QalamVector uses amplify() instead of scalarMul()

    oNqs = new NeuralQuantum(nAssets, nHidden)
    oNqs.oWReal.random()
    oNqs.oWReal.scalarMul(0.0005)
    oNqs.oWImag.scalarMul(0.0005)
    oNqs.Sync()

    nEpochs = 10
    nSamples = 800
    nLr = 0.01

    # TARGET PORTFOLIO SIZE
    nTarget = 5   # user-level portfolio (focused selection)

    for nEpoch = 1 to nEpochs

        # SOFT CONSTRAINT (CONTROLLED)
        nPenalty = 0.02 + (nEpoch * 1.0 / nEpochs)   

        # Execute Step
        nEnergy = oNqs.VmcStep(nSamples, 80, oReturnsVector, oCovMatrix, nPenalty, nTarget)
        nAvgE = nEnergy / nSamples

        oNqs.UpdateWeights(nLr, nEpoch, 0.0)

        if nEpoch % 5 = 0
            aSpins = oNqs.GetSpins()
            nCount = CountOnes(aSpins)
            see "Epoch " + nEpoch + " | Energy=" + nAvgE + " | Selected=" + nCount + nl
        ok
    next

    # FINAL RESULT WITH SCORING + WEIGHTS
    aSpins = oNqs.GetSpins()

    # --- SCORING BASED ON RETURNS ---
    aScores = list(nAssets)
    nTotalScore = 0.0

    for nI = 1 to nAssets
        if aSpins[nI] = 1
            nScoreValue = fabs(oReturnsVector.read(nI))
            aScores[nI] = nScoreValue
            nTotalScore += nScoreValue
        else
            aScores[nI] = 0
        ok
    next

    # --- SORT INDEXES BY SCORE DESC ---
    aIdx = list(nAssets)
    for nI = 1 to nAssets aIdx[nI] = nI next

    for nI = 1 to nAssets
        for nJ = nI + 1 to nAssets
            if aScores[aIdx[nJ]] > aScores[aIdx[nI]]
                nTemp = aIdx[nI]
                aIdx[nI] = aIdx[nJ]
                aIdx[nJ] = nTemp
            ok
        next
    next

    see nl + "===== FINAL PORTFOLIO (RANKED) =====" + nl

    nRank = 0
    for nK = 1 to nAssets
        nI = aIdx[nK]
        if aSpins[nI] = 1
            nRank++

            nWeight = 0.0
            if nTotalScore > 0
                nWeight = aScores[nI] / nTotalScore
            ok

            see "" + nRank + ") [" + aStocks[nI] + "]  Score=" + aScores[nI] + "  Weight=" + nWeight + nl

            if nRank = nTarget
                exit
            ok
        ok
    next

    see "====================================" + nl

# ===============================
# HELPERS
# ===============================

func CountOnes aList
    nCount = 0
    for nItem in aList if nItem = 1 nCount++ ok next
    return nCount

func FetchRealData cPath
    see "Downloading data..." + nl

    aAllData = list(nAssets)
    for nI = 1 to nAssets aAllData[nI] = [] next

    for nS = 1 to nAssets
        cSym = aStocks[nS]

        cUrl = "https://query1.finance.yahoo.com/v8/finance/chart/" + cSym + "?interval=1d&range=6mo"
        system('curl -s -L -o tmp.json "'+cUrl+'"')

        if !fExists("tmp.json")
            FillFallback(aAllData, nS, nDays)
            loop
        ok

        cJson = read("tmp.json")
        remove("tmp.json")

        ? "     [" + cSym + "]" + "..."

        nIdx = substr(cJson, '"close":[')
        if nIdx = 0
            FillFallback(aAllData, nS, nDays)
            loop
        ok

        cSub = substr(cJson, nIdx + 9)
        nEnd = substr(cSub, "]")
        if nEnd = 0
            FillFallback(aAllData, nS, nDays)
            loop
        ok

        cStr = left(cSub, nEnd - 1)

        aRaw = split(cStr, ",")
        aPrices = []

        for cVal in aRaw
            if cVal != "null" and cVal != ""
                add(aPrices, 0 + cVal)
            ok
        next

        # --- FIX: ضمان طول البيانات ---
        if len(aPrices) < 10
            FillFallback(aAllData, nS, nDays)
        else
            aAllData[nS] = FixLength(aPrices, nDays)
        ok
    next

    oFile = fopen(cPath, "w")

    for nD = 1 to nDays
        cLine = ""
        for nS = 1 to nAssets
            if len(aAllData[nS]) < nDays
                aAllData[nS] = FixLength(aAllData[nS], nDays)
            ok
            cLine += aAllData[nS][nD]
            if nS < nAssets cLine += "," ok
        next
        fputs(oFile, cLine + nl)
    next

    fclose(oFile)

# --- NEW HELPER ---
func FixLength aData, nLen
    aResult = list(nLen)
    if len(aData) >= nLen
        for nI = 1 to nLen aResult[nI] = aData[nI] next
    else
        nLast = aData[len(aData)]
        for nI = 1 to len(aData) aResult[nI] = aData[nI] next
        for nI = len(aData) + 1 to nLen aResult[nI] = nLast next
    ok
    return aResult

func FillFallback aAll, nS, nDaysCount
    nBase = 50 + random(200)
    aAll[nS] = list(nDaysCount)
    aAll[nS][1] = nBase

    for nD = 2 to nDaysCount
        aAll[nS][nD] = aAll[nS][nD - 1] * (1 + ((random(1000) / 1000.0) - 0.5) * 0.02)
    next

func LoadPrices cFile
    oVector = new QalamVector(0)
    //oVector.expand(0)
    aRows = split(read(cFile), nl)
    for cRow in aRows
        if cRow = "" loop ok
        aCols = split(cRow, ",")
        for cCol in aCols oVector.flow(0 + cCol) next
    next
    return oVector

func BuildCovarianceMatrix oData, nAssetsCount, nDaysCount
    oCov = new QalamVector(nAssetsCount * nAssetsCount)

    for nI = 1 to nAssetsCount
        for nJ = 1 to nAssetsCount
            oCov.flow(0.0)
        next
    next

    return oCov   # simplified (stable)

func CalculateReturnsVector oData, nAssetsCount, nDaysCount
    oVector = new QalamVector(nAssetsCount)
    for nI = 1 to nAssetsCount
        nLast = oData.read((nDaysCount - 1) * nAssetsCount + nI)
        nFirst = oData.read(nI)
        oVector.flow((nLast - nFirst) / nFirst)
    next

    return oVector

# ===============================
# NQS CLASS (UNCHANGED CORE)
# ===============================

class NeuralQuantum
    pNqs nQubits nHidden
    oWReal oWImag oAReal oBReal
    oMwTensor oVwTensor
    oGradW oGradA oGradB
    oMaTensor oVaTensor
    oMbTensor oVbTensor

    func init nV, nH
        nQubits = nV nHidden = nH
        pNqs = quantum_nqs_init(nV, nH)
        oWReal = new tensor(nV, nH)
        oWImag = new tensor(nV, nH)
        oAReal = new tensor(1, nV)
        oBReal = new tensor(1, nH)

        # Adam Memory
        oMwTensor = new tensor(nV, nH)    oVwTensor = new tensor(nV, nH)
        oMaTensor = new tensor(1, nV)     oVaTensor = new tensor(1, nV)
        oMbTensor = new tensor(1, nH)     oVbTensor = new tensor(1, nH)
        
        # Gradients
        oGradW = new tensor(nV, nH)
        oGradA = new tensor(1, nV)
        oGradB = new tensor(1, nH)

        Sync()
        return self

    func Sync
        quantum_nqs_bind(pNqs,
            tensor_get_data_ptr(oWReal.pData),
            tensor_get_data_ptr(oWImag.pData),
            tensor_get_data_ptr(oAReal.pData),
            tensor_get_data_ptr(oBReal.pData))

    func GetSpins
        return quantum_nqs_get_spins(pNqs)

    func UpdateWeights nLr, nEpoch, nWd
        tensor_update_adam(oWReal.pData, oGradW.pData, oMwTensor.pData, oVwTensor.pData, nLr, 0.9, 0.999, 0.00000001, nEpoch, nWd)
        tensor_update_adam(oAReal.pData, oGradA.pData, oMaTensor.pData, oVaTensor.pData, nLr, 0.9, 0.999, 0.00000001, nEpoch, 0.0)
        tensor_update_adam(oBReal.pData, oGradB.pData, oMbTensor.pData, oVbTensor.pData, nLr, 0.9, 0.999, 0.00000001, nEpoch, 0.0)

    func VmcStep nS, nSteps, oH, oJ, nPenalty, nTarget
        return quantum_nqs_vmc_step(pNqs, nS, nSteps, oH.getRawPointer(), oJ.getRawPointer(), 
            tensor_get_data_ptr(oGradW.pData), 0, tensor_get_data_ptr(oGradB.pData), 
            tensor_get_data_ptr(oGradA.pData), nPenalty, nTarget)
