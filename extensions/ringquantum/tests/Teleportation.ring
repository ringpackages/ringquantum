/*
** RingQuantum Showcase - Quantum Teleportation
** Quantum Teleportation
** Transferring a quantum state from one location to another using entanglement and classical communication
*/

load "ringquantum.ring"

func main
    # We need 3 qubits: 0 (Sender), 1 (Alice's Bridge), 2 (Bob's Receiver)
    q = new QuantumCircuit(3)

    # 1. Preparing the state to be teleported (in Qubit 0)
    # We will make it a superposition state with angle RY(pi/3)
    val = 3.14159 / 3.0
    q.RY(0, val)
    see "Original state prepared on Qubit 0 (Alice)." + nl

    # 2. Creating a Bell pair (Quantum Entanglement) between Qubits 1 and 2
    # Qubit 1 goes to Alice and 2 goes to Bob
    q.H(1)
    q.CNOT(1, 2)
    see "Entangled pair shared between Alice and Bob." + nl

    # 3. Alice performs operations on her qubit (0) and the entangled qubit (1)
    q.CNOT(0, 1)
    q.H(0)

    # 4. Alice measures her qubits and sends the result to Bob via "classical communication"
    m0 = q.Measure(0)
    m1 = q.Measure(1)
    see "Alice measured her qubits: " + m0 + ", " + m1 + nl

    # 5. Bob corrects his qubit based on Alice's results
    # This demonstrates the hybrid integration between programming logic and quantum state
    if m1 = 1 q.X(2) ok
    if m0 = 1 q.Z(2) ok

    see nl + "Teleportation Finished." + nl
    see "Bob's Qubit (2) should now match Alice's original state." + nl
    
    # Check probabilities
    q.RevealState()