load "ringquantum.ring"
load "alqalam.ring"

# Display settings
decimals(10)

func main
    see "--- Quantum Portfolio Optimizer (25 Qubits) ---" + nl
    nAssets = 25
    
    # 1. Preparing classic financial statements using a alqalam
    # Creating experimental data (Returns & Covariance)
    oReturns = new QalamVector(nAssets)
    oReturns.flood(0.05) # Expected return of 5% per stock
    
    oCovariance = new QalamVector(nAssets * nAssets)
    oCovariance.flood(0.01) # Simple mutual risk
    
    # 2. Quantum algorithm parameters (QAOA)
    gamma = 0.1  # Cost coefficient
    beta  = 0.1  # Mixing coefficient
    
    oTimer = new QalamChronos()
    
    # 3. Running the quantum engine for 25 qubits
    see "Initializing 25-Qubit Quantum System (33.5 Million States)..." + nl
    q = new QuantumCircuit(nAssets)
    
    # Phase a: Full superposition (Hadamard Wall)
    see "Step 1: Applying Superposition..." + nl
    for i = 0 to nAssets - 1 
        q.H(i) 
    next

    # Phase b: Cost Layer
    # Encoding returns and risks in the quantum phase
    see "Step 2: Encoding Financial Data (Hamiltonian Evolution)..." + nl
    for i = 0 to nAssets - 1
        # Single-qubit rotation
        fReturn = oReturns.read(i+1)
        q.RZ(i, fReturn * gamma)
        
        # Mutual risk encoding (Interactions)
        # To reduce the load, we will link each stock to the adjacent stock (Linear Topology)
        if i < nAssets - 1
            fRisk = 0.02 # Covariance value between the two stocks
            q.CNOT(i, i+1)
            q.RZ(i+1, fRisk * gamma)
            q.CNOT(i, i+1)
        ok
    next

    # Phase c: Mixer Layer
    # Allowing interference between investment portfolios
    see "Step 3: Applying Quantum Mixer..." + nl
    for i = 0 to nAssets - 1
        q.RX(i, 2.0 * beta)
    next

    # 4. Calculating the final result (Expectation Value)
    see "Step 4: Analyzing Results (Expectation Values)..." + nl
    fTotalEnergy = 0
    for i = 0 to nAssets - 1
        # The expected value of Z gives us an indicator of the probability of selecting the stock
        fExp = q.ExpectationZ(i)
        fTotalEnergy += fExp
        
        # Smart display layer: show the state of the first five stocks only
        if i < 5
            see "Asset " + i + " Selection Score: " + fExp + nl
        ok
    next

    see "Optimization Cycle Finished!" + nl
    see "Total Computational Time: " + oTimer.elapsed() + nl
    
    # 5. Final decision (Measurement)
    # Extracting the best investment portfolio as a binary code
    see "Final Portfolio Configuration (Binary Code):" + nl
    cPortfolio = ""
    for i = 0 to nAssets - 1
        cPortfolio += q.Measure(i)
    next
    see cPortfolio + nl

    q.Delete()