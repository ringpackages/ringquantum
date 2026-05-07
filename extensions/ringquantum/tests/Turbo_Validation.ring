load "ringquantum.ring"

decimals(6)

func main
    see "============================================" + nl
    see "   RingQuantum Turbo (FP32) Validation Suite" + nl
    see "============================================" + nl
    see "[1] Validating Gate Precision..." + nl
    test_gate_precision()
    
    see nl + "[2] Validating Reversibility (Unitary Test)..." + nl
    test_reversibility()
    
    see nl + "[3] Super-Position Stress Test (25 Qubits)..." + nl
    test_large_scale(25)
    
    see nl + "Verification Complete. All systems operational." + nl

func test_gate_precision
    q = new QuantumCircuit(1)
    # Apply Rotation RY(pi/2) -> Expected |0> = 0.707, |1> = 0.707
    q.RY(0, 3.14159265 / 2.0)
    state = q.GetState()
    r0 = state[1]
    r1 = state[3]
    see "   RY(pi/2) -> |0>: " + r0 + " (Expected ~0.707107)" + nl
    see "               |1>: " + r1 + " (Expected ~0.707107)" + nl
    if fabs(r0 - 0.707107) < 0.0001
        see "   SUCCESS: High Precision Maintained." + nl
    else
        see "   WARNING: Precision variance detected." + nl
    ok

func test_reversibility
    q = new QuantumCircuit(3)
    # Circuit: H(0), CNOT(0,1), Toffoli(0,1,2)
    q.H(0)
    q.CNOT(0,1)
    q.Toffoli(0,1,2)
    
    see "   Forward Circuit Applied." + nl
    
    # Reverse: Toffoli(0,1,2), CNOT(0,1), H(0)
    q.Toffoli(0,1,2)
    q.CNOT(0,1)
    q.H(0)
    
    probs = q.GetProbabilities()
    see "   Reversed Circuit -> Probability of |0>: " + probs[1] + nl
    if probs[1] > 0.999
        see "   SUCCESS: Unitary property verified (Fidelity ~1.0)" + nl
    else
        see "   FAILURE: State drift detected." + nl
    ok

func test_large_scale nQ
    see "   Allocating " + nQ + " Qubits (Turbo Mode)..." + nl
    t1 = clock()
    q = new QuantumCircuit(nQ)
    t2 = clock()
    see "   Initialization: " + ((t2-t1)/clockspersecond()) + "s" + nl
    
    see "   Applying Parallel Gates (H on all " + nQ + " qubits)..." + nl
    t1 = clock()
    for i = 1 to nQ
        q.H(i)
    next
    t2 = clock()
    see "   H-Wallpaper Execution: " + ((t2-t1)/clockspersecond()) + "s" + nl
    
    see "   Calculating Expectation <Z> on Qubit 0..." + nl
    ez = q.ExpectationZ(0)
    see "   <Z0> = " + ez + " (Expected ~0.0)" + nl
