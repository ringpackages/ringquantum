# ====================================================================
# QUANTUM STRATEGIST ENGINE (Phase 11 - The Trader's Spirit)
# Market Neutral | Alpha-Beta Decoupling | Risk-Parity Quantum Weighting
# ====================================================================

load "../quantum_transformer.ring"

# --- GLOBAL SETTINGS ---
decimals(6)

nAssets = 40 
nTrainDays = 126 # Semi-annual memory for structure
nTestDays = 21 
nStep = 21

cDataFile = "market_data_sniper_40.csv"
cOutputFile = "quantum_strategist_report.txt"

# --- ASSET LIST (Same 40 for continuity, but treated differently) ---
aStocks = [
    "AAPL", "MSFT", "GOOGL", "AMZN", "NVDA", "META", "TSLA", "NFLX", "AMD", "ADBE",
    "CRM", "AVGO", "ORCL", "QCOM", "NOW", "INTU", "AMAT", "ISRG", "LRCX", "PANW",
    "V", "MA", "JPM", "BAC", "MS", "GS",
    "SH", "PSQ", "SQQQ", "SPXS", "UVXY",
    "GOLD", "GLD", "TLT", "DOG", "RWM", "BITO", "ARKK", "SMH", "SOXX"
]

func main
    see "    " + copy("=", 68) + nl
    see "    |               QUANTUM STRATEGIST (PHASE 11)                    |" + nl
    see "    |       Market Neutral | Alpha-Beta Decoupling | Risk Parity     |" + nl
    see "    " + copy("=", 68) + nl + nl
    
    if !fExists(cDataFile) FetchSniperData(cDataFile, 2520) ok
    aDataRaw = LoadPricesM(cDataFile)
    nTotalDaysActual = len(aDataRaw)
    
    nCumPortReturn = 1.0
    nCumMarkReturn = 1.0
    nCumAlphaValue = 1.0
    aPrevPortfolio = []
    nTotalCycles = 0

    oTransformer = new QuantumTransformer(nAssets, 512)
    oTransformer.AddLayer(4, 128)

    for t = 1 to (nTotalDaysActual - nTrainDays - nTestDays + 1) step nStep
        nTrainStart = t
        nTrainEnd   = t + nTrainDays - 1
        nTestStart  = nTrainEnd
        nTestEnd    = nTestStart + nTestDays
        if nTestEnd > nTotalDaysActual exit ok
        nTotalCycles++

        # --- TRADER'S INTUITION: ALPHA EXTRACTION ---
        oAlphaVector = new QalamVector(nAssets)
        oCovMatrix = new QalamVector(nAssets * nAssets)
        
        # 1. Calculate Market Beta (Benchmark = Top 5)
        aMktRets = list(nTrainDays-1)
        for d = 1 to (nTrainDays-1)
            nM = 0.0
            for i = 1 to 5
                p1 = aDataRaw[nTrainStart+d][i]
                p0 = aDataRaw[nTrainStart+d-1][i]
                if p0 > 0 nM += (p1-p0)/p0 ok
            next
            aMktRets[d] = nM / 5
        next

        # 2. Extract Pure Alpha (Residuals)
        for i = 1 to nAssets
            # Linear Regression Intuition: Return_i = Alpha + Beta*Return_Mkt
            # We simplify to: Forward Alpha = Excess Return over Market
            pEnd = aDataRaw[nTrainEnd][i]
            pStart = aDataRaw[nTrainEnd-21][i] # Last month momentum
            nRet = 0.0 if pStart > 0 nRet = (pEnd - pStart)/pStart ok
            
            pStartL = aDataRaw[nTrainStart][i] # Long term trend
            nLongRet = (pEnd - pStartL)/pStartL
            
            # THE TRADER'S FILTER: Only pick if short-term > long-term (Acceleration)
            if nRet > (nLongRet/6) and nRet > 0.01
                oAlphaVector.write(i, nRet) 
            else
                oAlphaVector.write(i, -2.0) # Penalty
            ok
        next

        # --- DYNAMIC COVARIANCE (THE RISK PARITY) ---
        for i = 1 to nAssets
            for j = 1 to nAssets
                nSum = 0.0
                for d = 1 to (nTrainDays-1)
                    p1i = aDataRaw[nTrainStart+d][i]
                    p0i = aDataRaw[nTrainStart+d-1][i]
                    ri = 0.0 if p0i > 0 ri = (p1i-p0i)/p0i ok
                    
                    p1j = aDataRaw[nTrainStart+d][j]
                    p0j = aDataRaw[nTrainStart+d-1][j]
                    rj = 0.0 if p0j > 0 rj = (p1j-p0j)/p0j ok
                    
                    nSum += ri * rj
                next
                oCovMatrix.flow(nSum / (nTrainDays-1))
            next
        next

        # Squeeze weights with Risk-Parity Logic
        oAlphaVector.amplify(-100.0)
        oCovMatrix.amplify(50.0) # High Risk resistance

        # TRANSACTION COST BUFFER (Trader's Exit/Entry Rule)
        nBuffer = 15.0
        if len(aPrevPortfolio) > 0
            for i = 1 to nAssets
                if find(aPrevPortfolio, i) > 0
                    oAlphaVector.write(i, oAlphaVector.read(i) - nBuffer)
                else
                    oAlphaVector.write(i, oAlphaVector.read(i) + nBuffer)
                ok
            next
        ok

        nEnergy = oTransformer.UpdateTDVP(oAlphaVector, oCovMatrix, 80.0, 10, 60, 0.0001, 0.01)

        # SELECTION: THE ALPHA PEAK
        oTransformer.SetTemperature(1.3)
        aSamples = oTransformer.GenerateSamples(1024)
        aBestPort = []
        nMaxSuccess = -999.0
        
        for aS in aSamples
            # Estimate Expected Alpha
            nExpAlpha = 0
            nActive = 0
            for i = 1 to nAssets if aS[i]=1 nExpAlpha += oAlphaVector.read(i) nActive++ ok next
            if nActive >= 3 and nActive <= 8 # Optimal Trading Size
                if nExpAlpha < nMaxSuccess
                    nMaxSuccess = nExpAlpha
                    aBestPort = []
                    for i = 1 to nAssets if aS[i]=1 aBestPort + i ok next
                ok
            ok
        next

        # EXECUTION OOS
        nTurnover = 0
        if len(aPrevPortfolio) > 0
            for i = 1 to nAssets if (find(aPrevPortfolio,i)>0) != (find(aBestPort,i)>0) nTurnover++ ok next
        ok
        aPrevPortfolio = aBestPort

        nPortRet = 0.0
        nMktRet = 0.0
        for i = 1 to nAssets
            p1 = aDataRaw[nTestEnd][i]
            p0 = aDataRaw[nTestStart][i]
            r = (p1-p0)/p0
            if find(aBestPort, i) > 0 nPortRet += r ok
            if i <= 5 nMktRet += r ok 
        next
        if len(aBestPort) > 0 nPortRet /= len(aBestPort) ok
        nMktRet /= 5
        
        nNetRet = nPortRet - (nTurnover * 0.001)
        nAlpha = nNetRet - nMktRet
        
        nCumPortReturn *= (1.0 + nNetRet)
        nCumMarkReturn *= (1.0 + nMktRet)
        nCumAlphaValue *= (1.0 + nAlpha)
        
        see "    | CYCLE " + ("" + nTotalCycles) + " | Alpha: " + round2(nAlpha*100) + "% | Net: " + round2(nNetRet*100) + "% | Size: " + ("" + len(aBestPort)) + " | E: " + round2(nEnergy) + nl
    next

    see nl + copy("=", 68) + nl
    see "    [!] STRATEGIST MISSION COMPLETE. " + nl
    see "    Total Cumulative Alpha: " + round2((nCumAlphaValue-1)*100) + "%" + nl
    see copy("=", 68) + nl

func round2 n return floor(n * 1000) / 1000

func FetchSniperData cPath, nD
    see "    -> Fetching Strategist Datasets... " + nl
    aAll = list(nAssets)
    for i = 1 to nAssets
        cUrl = "https://query1.finance.yahoo.com/v8/finance/chart/" + aStocks[i] + "?interval=1d&range=10y"
        system('curl.exe -s -A "Mozilla/5.0" -L -o temp_s.json "' + cUrl + '"')
        if fExists("temp_s.json")
            cJson = read("temp_s.json")
            remove("temp_s.json")
            nIdx = substr(cJson, '"adjclose":[')
            if nIdx = 0 nIdx = substr(cJson, '"close":[') ok
            if nIdx > 0
                cSub = substr(cJson, nIdx)
                cSub = substr(cSub, substr(cSub, "[") + 1)
                nEnd = substr(cSub, "]")
                if nEnd > 0
                    aRaw = split(left(cSub, nEnd-1), ",")
                    aPrices = []
                    nLV = 100.0
                    for cV in aRaw
                        cV = trim(cV)
                        if cV != "null" and cV != "" try nLV = 0 + cV catch done ok
                        add(aPrices, nLV)
                    next
                    if len(aPrices) >= nD * 0.4 aAll[i] = aPrices ok
                ok
            ok
        ok
        if len(aAll[i]) < nD aAll[i] = list(nD) nB = 100 for j = 1 to nD aAll[i][j] = nB nB *= (1.0 + (random(100)/50000.0)-0.001) next ok
    next
    oF = fopen(cPath, "w")
    for d = 1 to nD
        cL = ""
        for s = 1 to nAssets
            cL += aAll[s][d]
            if s < nAssets cL += "," ok
        next
        fputs(oF, cL + nl)
    next
    fclose(oF)

func LoadPricesM cFile
    aAll = []
    aRows = split(read(cFile), nl)
    for cRow in aRows
        if cRow = "" loop ok
        aCols = split(cRow, ",")
        aDay = []
        for i = 1 to len(aCols) aDay + (0 + aCols[i]) next
        aAll + aDay
    next
    return aAll
