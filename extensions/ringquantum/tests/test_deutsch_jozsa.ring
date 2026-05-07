/*
** RingQuantum Showcase - Deutsch-Jozsa Algorithm
** Deutsch-Jozsa Algorithm
** An algorithm that proves quantum supremacy in determining the nature of functions (constant or balanced) in a single step
*/

load "ringquantum.ring"

func main
    see "============================================" + nl
    see "    Deutsch-Jozsa Quantum Algorithm" + nl
    see "============================================" + nl
    
    see "Test 1: Balanced Oracle (f(x) = bit sum mode 2)" + nl
    run_dj("balanced")

    see nl + "Test 2: Constant Oracle (f(x) = 1)" + nl
    run_dj("constant")

func run_dj type
    n = 3 # Number of input qubits (8 possibilities)
    q = new QuantumCircuit(n + 1) # +1 auxiliary qubit

    # 1. Preparing the auxiliary qubit (Ancilla) in the |- > state
    q.X(n)
    q.H(n)

    # 2. Putting the input qubits in a superposition state
    for i = 1 to n q.H(i) next

    # 3. The Oracle
    if type = "balanced"
        # Balanced function: f(x) = x0 ^ x1 ^ x2
        for i = 1 to n q.CNOT(i, n) next
    else
        # Constant function: f(x) = 1
        q.X(n) # Leads to flipping the phase for all states (does not affect the difference)
    ok

    # 4. Final Interference (Hadamard on inputs)
    for i = 1 to n q.H(i) next

    # 5. Measurement
    see "Querying Oracle... Measuring input registers..." + nl
    all_zero = true
    res = ""
    for i = 1 to n
        m = q.Measure(i)
        res += m
        if m = 1 all_zero = false ok
    next
    
    see "Measurement Result: |" + res + ">" + nl
    if all_zero
        see "Conclusion: Function is CONSTANT" + nl
    else
        see "Conclusion: Function is BALANCED" + nl
    ok
    see "--------------------------------------------" + nl