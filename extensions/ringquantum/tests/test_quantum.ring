load "ringquantum.ring"

func main
    # 1. Initialize a system of 2 Qubits
    # Initial state is |00> with probability 1.0 at index 0
    q = new QuantumCircuit(2)
    
    see "Initial State (Expect |00> = 1.0):" + nl
    print_state(q)
    
    # 2. Apply Hadamard on Qubit 0
    # Expected State: (|00> + |10>) / sqrt(2)
    q.H(0)
    
    # 3. Apply CNOT with Control=0, Target=1
    # Expected State: (|00> + |11>) / sqrt(2)
    q.CNOT(0, 1)
    
    see nl + "State after Bell Circuit (|00> + |11>) / sqrt(2):" + nl
    print_state(q)
    
    # 4. Measure Qubit 0
    res = q.Measure(0)
    see nl + "Measurement of Qubit 0: " + res + nl
    
    # 5. Check Probabilities
    probs = q.GetProbabilities()
    see "Probabilities distribution: " + nl
    for i = 1 to len(probs)
        see "State |" + (i-1) + "> : " + probs[i] + nl
    next

func print_state q
    state = q.GetState()
    # State is interleaved [Re0, Im0, Re1, Im1, ...]
    for i = 1 to len(state) step 2
        r = state[i]
        im = state[i+1]
        see "Amplitude |" + ((i-1)/2) + "> : " + r + " + " + im + "i" + nl
    next