load "stdlib.ring"
load "ringquantum.ring"
load "alqalam.ring"
load "ringtensor.ring"
load "internetlib.ring"

nAssets = 25
nDays   = 60
decimals(4)
SetThreads(4)

aStocks = ["AAPL", "MSFT", "GOOGL", "AMZN", "NVDA", "META", "TSLA", "V", "WMT", "JPM",
           "UNH", "MA", "JNJ", "XOM", "PG", "HD", "CVX", "KO", "ABBV", "PEP",
           "COST", "ADBE", "CRM", "DIS", "NFLX"]

aNames = ["Apple", "Microsoft", "Alphabet", "Amazon", "Nvidia", "Meta", "Tesla", "Visa", "Walmart", "JPMorgan",
          "UnitedHealth", "Mastercard", "J&J", "ExxonMobil", "P&G", "HomeDepot", "Chevron",
          "Coca-Cola", "AbbVie", "PepsiCo", "Costco", "Adobe", "Salesforce", "Disney", "Netflix"]

aSectors = ["Tech", "Tech", "Tech", "Tech", "Tech", "Tech", "Auto", "Finance", "Retail", "Finance",
            "Health", "Finance", "Health", "Energy", "Consumer", "Retail", "Energy", "Consumer", "Health", "Consumer",
            "Retail", "Tech", "Tech", "Media", "Media"]

API_KEY = "demo"

func main
    see "==========================================================" + nl
    see "    RING QUANTUM STOCK INTELLIGENCE v2.0" + nl
    see "==========================================================" + nl
    see "Engine : GPU FP32 Turbo | Method : QAOA" + nl
    see "Assets : " + nAssets + " stocks | Data : Twelve Data API" + nl
    see "==========================================================" + nl + nl

    cFile = "realstock_25.csv"
    if !fExists(cFile)
        FetchRealData(cFile)
    ok

    oPrices = LoadPrices(cFile, nAssets, nDays)
    oCov = BuildCovarianceMatrix(oPrices, nAssets, nDays)
    see "Risk matrix ready." + nl + nl

    W    = tensor_init(1, 2)
    Grad = tensor_init(1, 2)
    M    = tensor_init(1, 2)
    V    = tensor_init(1, 2)
    tensor_set(W, 1, 1, 0.5)
    tensor_set(W, 1, 2, 0.5)

    nEpochs = 12
    LR = 0.05
    oTimer = new QalamChronos()

    see "Running QAOA (" + nAssets + " Qubits)..." + nl
    for epoch = 1 to nEpochs
        g = tensor_get(W, 1, 1)
        b = tensor_get(W, 1, 2)
		eps = 0.02
        e0 = CostFunction(g, b, oCov)
		grad_g = (CostFunction(g+eps, b, oCov) - CostFunction(g-eps, b, oCov)) / (2*eps)
		grad_b = (CostFunction(g, b+eps, oCov) - CostFunction(g, b-eps, oCov)) / (2*eps)
		tensor_set(Grad, 1, 1, grad_g)
		tensor_set(Grad, 1, 2, grad_b)
        tensor_update_adam(W, Grad, M, V, LR, 0.9, 0.999, 0.00000001, epoch, 0.0)
        see "  Epoch " + epoch + "/" + nEpochs + "  Risk = " + e0 + nl
    next

    see nl + "========== COMPLETE (" + oTimer.elapsed() + ") ==========" + nl + nl

    qFinal = new QuantumCircuit(nAssets)
    ApplyQAOA(qFinal, tensor_get(W, 1, 1), tensor_get(W, 1, 2), oCov)

    see "PORTFOLIO RECOMMENDATION" + nl
    see "----------------------------------------------------------" + nl
    see "  #  | Ticker | Company         | Sector   | Decision" + nl
    see "----------------------------------------------------------" + nl

    nBuy = 0
    aBuyList = []
    for i = 0 to nAssets-1
        bit = qFinal.Measure(i)
        idx = i + 1
        sNum = "" + idx
        if idx < 10 sNum = " " + idx ok
        sTicker = aStocks[idx]
        while len(sTicker) < 6 sTicker += " " end
        sName = aNames[idx]
        while len(sName) < 15 sName += " " end
        sSec = aSectors[idx]
        while len(sSec) < 8 sSec += " " end
        if bit = 1
            see "  " + sNum + " | " + sTicker + " | " + sName + " | " + sSec + " | BUY" + nl
            nBuy++ add(aBuyList, aStocks[idx])
        else
            see "  " + sNum + " | " + sTicker + " | " + sName + " | " + sSec + " | HOLD" + nl
        ok
    next

    see "----------------------------------------------------------" + nl
    see "Selected " + nBuy + " / " + nAssets + " stocks." + nl + nl

    if nBuy > 0
        w = 100.0 / nBuy
        see "ALLOCATION:" + nl
        for t in aBuyList see "  " + t + " -> " + w + "%" + nl next
    ok
    see "==========================================================" + nl

func CostFunction g, b, oCov
    q = new QuantumCircuit(nAssets)
    ApplyQAOA(q, g, b, oCov)
    energy = 0.0
    for i = 0 to nAssets-1
        for j = i+1 to nAssets-1
            risk = oCov.read(i*nAssets + j + 1)
            if fabs(risk) > 0.0001
                energy += risk * quantum_exp_zz(q.pState, i, j)
            ok
        next
    next
    return energy

func ApplyQAOA q, gamma, beta, oCov
    for i = 0 to nAssets-1 q.H(i) next
    for i = 0 to nAssets-1
        for j = i+1 to nAssets-1
            risk = oCov.read(i*nAssets + j + 1)
            if fabs(risk) > 0.0001
                q.CNOT(i, j)
                q.RZ(j, risk * gamma)
                q.CNOT(i, j)
            ok
        next
    next
    for i = 0 to nAssets-1 q.RX(i, 2.0 * beta) next

func FetchRealData cPath
    see "Downloading REAL stock prices (Twelve Data API)..." + nl + nl

    aAllClose = list(nAssets)

    for s = 1 to nAssets
        sym = aStocks[s]
        see "  [" + s + "/" + nAssets + "] " + sym + " ... "

        cURL = "https://api.twelvedata.com/time_series?symbol=" + sym +
               "&interval=1day&outputsize=" + nDays +
               "&format=CSV&apikey=" + API_KEY

        cCSV = ""
        try
            cCSV = download(cURL)
        catch
            see "NETWORK ERROR" + nl
            aAllClose[s] = []
            loop
        done

        if len(cCSV) < 30 or substr(cCSV, "error") > 0 or substr(cCSV, "code") > 0
            see "API LIMIT (will use fallback)" + nl
            aAllClose[s] = []
            loop
        ok

        aLines = split(cCSV, nl)
        aPrices = []
        for k = len(aLines) to 2 step -1
            line = trim(aLines[k])
            if line = "" loop ok
            aCols = split(line, ";")
            if len(aCols) >= 5
                closePrice = 0 + trim(aCols[5])
                if closePrice > 0
                    add(aPrices, closePrice)
                ok
            ok
        next

        aAllClose[s] = aPrices
        if len(aPrices) > 0
            see "OK (" + len(aPrices) + " days) Last=$" + aPrices[len(aPrices)] + nl
        else
            see "PARSE ERROR" + nl
        ok
    next

    nActual = 9999
    for s = 1 to nAssets
        if len(aAllClose[s]) > 0 and len(aAllClose[s]) < nActual
            nActual = len(aAllClose[s])
        ok
    next
    if nActual > nDays nActual = nDays ok
    if nActual = 9999 nActual = nDays ok

    for s = 1 to nAssets
        if len(aAllClose[s]) < nActual
            FillFallback(aAllClose, s, nActual)
        ok
    next

    f = fopen(cPath, "w")
    for d = 1 to nActual
        line = ""
        for s = 1 to nAssets
            line += "" + aAllClose[s][d]
            if s < nAssets line += "," ok
        next
        fputs(f, line + nl)
    next
    fclose(f)
    see nl + "Saved " + nActual + " days x " + nAssets + " stocks -> " + cPath + nl + nl

func FillFallback aAll, s, n
    aBase = [270, 440, 178, 205, 135, 610, 260, 345, 95, 260,
             580, 530, 155, 108, 170, 405, 155, 73, 200, 150,
             950, 440, 310, 118, 1050]
    aAll[s] = list(n)
    aAll[s][1] = aBase[s]
    for d = 2 to n
        change = 1.0 + (0.0003 + 0.018 * ((random(2000)/1000.0) - 1.0))
        aAll[s][d] = aAll[s][d-1] * change
    next

func LoadPrices cFile, nA, nD
    vec = new QalamVector(nA * nD)
    data = read(cFile)
    rows = split(data, nl)
    for r in rows
        if r = "" loop ok
        cols = split(r, ",")
        for c in cols vec.flow(0+c) next
    next
    return vec

func BuildCovarianceMatrix oPrices, nA, nD
    see "Computing covariance matrix..." + nl
    nValid = nD - 1
    rets = list(nValid)
    for d = 1 to nValid rets[d] = list(nA) next
    means = list(nA)
    for i = 1 to nA means[i] = 0.0 next

    for d = 1 to nValid
        for i = 1 to nA
            pNow = oPrices.read(d * nA + i)
            pPre = oPrices.read((d-1) * nA + i)
            r = 0.0
            if pPre > 0.01 r = ((pNow - pPre) / pPre) * 100.0 ok
            rets[d][i] = r
            means[i] += r
        next
    next
    for i = 1 to nA if nValid > 0 means[i] = means[i] / nValid ok next

    cov = new QalamVector(nA * nA)
    for i = 1 to nA
        for j = 1 to nA
            val = 0.0
            for d = 1 to nValid
                val += (rets[d][i] - means[i]) * (rets[d][j] - means[j])
            next
            if (nValid - 1) > 0 val = val / (nValid - 1) ok
            cov.flow(val)
        next
    next
    return cov
