# RingQuantum Extension Loader
# Defines constants and loads the DLL


if iswindows()
    LoadLib("ring_quantum.dll")
but ismacosx()
    LoadLib("libring_quantum.dylib")
else
    LoadLib("libring_quantum.so")
ok

# Constants for ease of use
Quantum_Target_0 = 0
Quantum_Target_1 = 1
Quantum_Target_2 = 2
Quantum_Target_3 = 3

func GetQuantumCores
    return quantum_get_cores()

func SetQuantumThreads nCores
    quantum_set_threads(nCores)

func EnableQuantumGPU bState
    quantum_enable_gpu(bState)

func SetQuantumGPUThreshold nQubits
    quantum_set_gpu_threshold(nQubits)

# Helper class for a cleaner syntax
class QuantumCircuit
    pState
    nQubits

    func init nQubits
        pState = quantum_init(nQubits)
        self.nQubits = nQubits
        return self

    # Hadamard Gate
    func H target
        quantum_h(pState, target)
    
    # Pauli Gates
    func X target
        quantum_x(pState, target)

    func Y target           
        mY = [0,0,0,-1,0,1,0,0] 
        quantum_unitary(pState, target, mY) # Pauli-Y

    func Z target           
        quantum_phase(pState, target, 3.1415926535)
        
    # CNOT Gate
    func CNOT ctrl, target
        quantum_cnot(pState, ctrl, target)

    # Swap Gate
    func Swap q1, q2      
        quantum_swap(pState, q1, q2)

    # Toffoli Gate
    func Toffoli q1, q2, t  
        quantum_toffoli(pState, q1, q2, t) 

    # Phase Gate
    func Phase target, phi
        quantum_phase(pState, target, phi)
    
    # Rotation Gates
    func RX target, theta
        quantum_rx(pState, target, theta)
    
    func RY target, theta
        quantum_ry(pState, target, theta)
    
    func RZ target, theta
        quantum_rz(pState, target, theta)
    
    # Universal Gate
    func U target, theta, phi, lambda
        quantum_u_gate(pState, target, theta, phi, lambda)
    
    # Expectation Values
    func ExpectationX target
        return quantum_exp_x(pState, target)
    
    func ExpectationY target
        return quantum_exp_y(pState, target)
    
    func ExpectationZ target
        return quantum_exp_z(pState, target)    
    
    # Measurement
    func Measure target
        return quantum_measure(pState, target)

    # Get Probabilities
    func GetProbabilities
        return quantum_get_probabilities(pState)
    
    # Get State
    func GetState
        return quantum_get_state(pState)

    # Controlled Unitary
    func Controlled_Unitary ctrl, target, matrix
        quantum_controlled_unitary(pState, ctrl, target, matrix)

    # --- Multi-Controlled Master Gate ---
    func MCU aControls, nTarget, aMatrix
        quantum_mcu(pState, aControls, nTarget, aMatrix)

    # Special case: MCX (Multi-Controlled NOT)
    func MCX aControls, nTarget
        mX = [0,0,1,0,1,0,0,0] # Identity Swap for X
        MCU(aControls, nTarget, mX)
    
    # Fidelity Check
    func Fidelity oOther
        return quantum_fidelity(pState, oOther.pState)

    # --- Standard Algorithms ---

    # Quantum Fourier Transform
    func QFT n
        for i = n-1 to 0 step -1
            H(i)
            for j = i-1 to 0 step -1
                k = i - j
                theta = 3.1415926535 / pow(2, k)
                mCP = [1,0, 0,0, 0,0, cos(theta), sin(theta)]
                Controlled_Unitary(j, i, mCP)
            next
        next
        for i = 0 to (n/2)-1 Swap(i, n-i-1) next

    # Inverse Quantum Fourier Transform
    func IQFT n
        for i = 0 to (n/2)-1 Swap(i, n-i-1) next
        for i = 0 to n-1
            for j = 0 to i-1
                k = i - j
                theta = -3.1415926535 / pow(2, k)
                mCP = [1,0, 0,0, 0,0, cos(theta), sin(theta)]
                Controlled_Unitary(j, i, mCP)
            next
            H(i)
        next

    # Controlled-Z Gate
    func CZ ctrl, target
        mCP = [1,0, 0,0, 0,0, -1,0]
        Controlled_Unitary(ctrl, target, mCP)

    # Delete
    func Delete
        quantum_free_mem(pState)
    
    # Display the status in a readable format
    func RevealState
        aState = GetState()
        nQ = nQubits
        see "--- Quantum State Fabric (n=" + nQubits + ") ---" + nl
        for i = 1 to len(aState) step 2
            re = aState[i]
            im = aState[i+1]
            # Show only states with probability greater than zero to avoid clutter
            if fabs(re) > 0.000001 or fabs(im) > 0.000001
                nIdx = (i-1)/2
                cBin = DecToBinFixed(nIdx, nQ)
                Decimals(6)
                see "|" + cBin + "> : (" + re + " + " + im + "i)" + nl
                Decimals(2)
            ok
        next

    # Helper function to convert a number to binary with fixed length
    func DecToBinFixed nNum, nLen
        cBin = ""
        nTmp = nNum
        for x = 1 to nLen
            if nTmp % 2 = 1 cBin = "1" + cBin else cBin = "0" + cBin ok
            nTmp = floor(nTmp / 2)
        next
        return cBin

