load "ringquantum.ring"
load "alqalam.ring"

decimals(10)

func main
    nQ = 25  # 33 Million states
    see "Initializing 25 Qubits (33,554,432 states)..." + nl
    oTime = new QalamChronos()
    q = new QuantumCircuit(nQ)
    
    see "Applying Hadamard to all qubits (H-Wallpaper)..." + nl
    for i = 1 to nQ
        q.H(i)
    next
    
    see "Time taken: " + oTime.elapsed()  + nl
    
    # (Unitary test)
    probs = q.GetProbabilities()
    # We won't compile them all programmatically to avoid wasting time; we'll take a sample.
    see "Probability of State |0>: " + probs[1] + nl