/*
** RingQuantum - Bernstein-Vazirani Algorithm
** Bernstein-Vazerani Algorithm
** This algorithm demonstrates the ability of a quantum computer to find a "secret number" in just one step!
*/

load "ringquantum.ring"

func main
    secret_string = "110101" # The secret number (6 bits)
    n = len(secret_string)
    
    see "============================================" + nl
    see "     Bernstein-Vazirani Quantum Demo" + nl
    see "============================================" + nl
    see "Predicting the secret string: " + secret_string + nl
    
    # We need n qubits for inputs + 1 auxiliary qubit (Ancilla)
    q = new QuantumCircuit(n + 1)

    # 1. Preparing the auxiliary qubit in the |- > state (Phase Kickback)
    q.X(n)
    q.H(n)

    # 2. Putting the input qubits in a superposition state
    for i = 1 to n q.H(i) next

    # 3. The Quantum Oracle (contains the secret number)
    # Mathematically: f(x) = s . x
    for i = 1 to n
        if secret_string[i] = "1" 
             q.CNOT(i, n) 
        ok
    next

    # 4. Applying the Hadamard gate again to cancel the superposition and show the result
    for i = 1 to n q.H(i) next

    # 5. Final measurement
    see "Quantum Oracle queried once. Measuring..." + nl
    result = ""
    # Note: The order in the measurement depends on the endianness system
    for i = 1 to n
        result += q.Measure(i)
    next

    see "--------------------------------------------" + nl
    see "Secret String Discovered: " + result + nl
    if result = secret_string 
        see "Verification: SUCCESS (Found in 1 Step!)" + nl 
    else 
        see "Verification: FAILED (Possible Index Mismatch)" + nl 
    ok
    see "--------------------------------------------" + nl