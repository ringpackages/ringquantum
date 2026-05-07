/*
** RingQuantum Showcase - Quantum Phase Estimation (QPE)
** Quantum Phase Estimation
** Used to estimate the eigenvalues of a unitary matrix
*/

load "ringquantum.ring"

func main
    see "--- Quantum Phase Estimation (QPE) Test ---" + nl
    nCount = 3 # Number of precision qubits
    target = 3 # Target qubit holding the eigenstate
    
    q = new QuantumCircuit(nCount + 1)

    # 1. Preparing the target qubit (e.g., state |1>)
    q.X(target)

    # 2. Applying Hadamard to the counting qubits to start superposition
    for i = 0 to nCount-1 q.H(i) next

    # 3. Sending sequential powers of the Phase gate (Controlled Unitary)
    # Selected rotation angle is pi/2 (equivalent to phase 0.25)
    angle = 3.1415926535 / 2 
    for i = 0 to nCount-1
        repetitions = 2^i
        for j = 1 to repetitions
            # Controlled Rotation Z gate
            mCP = [1,0, 0,0, 0,0, cos(angle), sin(angle)]
            q.Controlled_Unitary(i, target, mCP)
        next
    next

    # 4. Applying Inverse QFT to the counting qubits (built-in)
    see "Applying Inverse QFT..." + nl
    q.IQFT(nCount)

    # 5. Measurement (should see "010" for 0.25)
    res_bin = ""
    res_decimal = 0
    for i = 1 to nCount
        m = q.Measure(i)
        res_bin = "" + m + res_bin
        if m res_decimal += (2^i) ok
    next
    
    see "Measured Binary: " + res_bin + nl
    see "Estimated Phase: " + (res_decimal / (2^nCount)) + nl
    
    if (res_decimal / (2^nCount)) = 0.25
        see "SUCCESS: Phase correctly estimated via QPE." + nl
    ok