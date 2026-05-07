load "ringquantum.ring"

func main
    # Create a system of 3 qubits (8 states)
    q = new QuantumCircuit(3)

    # Put qubits 0 and 2 in superposition (Hadamard)
    q.H(0)
    q.H(2)

    # Flip qubit 1 (X gate)
    q.X(1)

    # Now reveal the state fabric
    q.RevealState()
    
    # Calculate the expected value of Z on qubit 1
    # Since we applied X to it, we expect the value to be -1.0
    see "Expectation Value <Z> on Qubit 1: " + q.ExpectationZ(1) + nl
    q.Delete()