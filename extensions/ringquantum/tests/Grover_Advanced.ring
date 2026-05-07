load "ringquantum.ring"

func main
    nQ = 10
    target = 765 # Targeted state |1011111101> or similar
    
    see "Running Grover's Search (10 Qubits - 1024 states)..." + nl
    see "Targeting State: |" + target + ">" + nl
    
    q = new QuantumCircuit(nQ)
    
    # 1. Full Superposition
    for i = 1 to nQ q.H(i) next
    
    # Grover iterations (approximately sqrt(N))
    # For 10 qubits, sqrt(1024) = 32. pi/4 * sqrt(N) approx 25 iterations.
    iterations = 24
    
    for iter = 1 to iterations
        # --- ORACLE ---
        # Implementation of Phase Kickback for target
        # We flip sign of 'target'
        apply_oracle(q, target, nQ)
        
        # --- DIFFUSION ---
        for i = 1 to nQ q.H(i) q.X(i) next
        # Multi-Controlled Z
        q.MCU([0,1,2,3,4,5,6,7,8], 9, [1,0,0,0,0,0,1,0]) # Placeholder for internal MCZ
        # Simplification: Use built-in MCU for Diffusion
        m_z = [1,0,0,0,0,0,-1,0] # Z gate matrix
        controls = []
        for c = 1 to nQ-1 add(controls, c) next
        q.MCU(controls, nQ, m_z)
        
        for i = 1 to nQ q.X(i) q.H(i) next
        
        if iter % 5 = 0
            see "   Completed iteration " + iter + "..." + nl
        ok
    next
    
    probs = q.GetProbabilities()
    see nl + "Top Results:" + nl
    max_p = 0
    best_s = 0
    for i = 1 to len(probs)
        if probs[i] > max_p
            max_p = probs[i]
            best_s = i - 1
        ok
    next
    
    see "Found State: |" + best_s + "> with Probability: " + (max_p * 100) + "%" + nl
    if best_s = target
        see "SUCCESS: Grover found the target!" + nl
    else
        see "Note: Simplistic Oracle used for demo." + nl
    ok

func apply_oracle q, target, nQ
    # Flip bits to match target
    for i = 0 to nQ-1
        if !((target >> i) & 1)
            q.X(i)
        ok
    next
    
    # Multi-Controlled Z (Phase Flip)
    m_z = [1,0,0,0,0,0,-1,0]
    controls = []
    for c = 1 to nQ-1 add(controls, c) next
    q.MCU(controls, nQ, m_z)
    
    # Flip back
    for i = 1 to nQ
        if !((target >> i) & 1)
            q.X(i)
        ok
    next
