/*
** RingQuantum Showcase - VQE Ising Model
** Ising Model for Quantum Physics
** Used to find the ground state energy of a 2-qubit magnetic system
*/

load "ringquantum.ring"

func main
    see "--- 2-Qubit Ising Model VQE Optimizer ---" + nl
    
    # We will scan the angle space (Grid Search) to find the lowest energy
    # Target Hamiltonian: H = -ZZ - X0 - X1
    
    minEnergy = 100
    bestTheta = 0
    
    see "Searching for Ground State Energy..." + nl

    for i = 1 to 100
        fTheta = i * 0.0628 # Scan from 0 to 2PI
        currentE = get_ising_energy(fTheta)
        
        if currentE < minEnergy
            minEnergy = currentE
            bestTheta = fTheta
        ok
    next

    see nl + "Simulation Results:" + nl
    see "--------------------------------------------" + nl
    see "Optimized Configuration (Theta): " + bestTheta + nl
    see "Calculated Ground State Energy: " + minEnergy + nl
    see "Theoretical Expectation: ~ -2.0 to -2.5" + nl
    see "--------------------------------------------" + nl

func get_ising_energy fAngle
    # 1. Building the Ansatz circuit
    q = new QuantumCircuit(2)
    q.H(0)
    q.CNOT(0, 1) # Entangling qubits to simulate magnetic interaction
    q.RY(0, fAngle)
    q.RY(1, fAngle)

    # 2. Calculate the spin correlation interaction <Z0 Z1>
    # Using the GPU-accelerated function directly
    expZZ = quantum_exp_zz(q.pState, 0, 1)

    # 3. Calculate the external magnetic field <X0> and <X1>
    # Calculated from the same state
    expX0 = q.ExpectationX(0)
    expX1 = q.ExpectationX(1)

    # Total Energy: Hamiltonian H = -ZZ - X0 - X1
    # Remember that the lowest energy in physics is the most stable state
    return -expZZ - expX0 - expX1