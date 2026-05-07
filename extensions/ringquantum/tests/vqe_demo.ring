/*
** RingQuantum - Hybrid VQE Optimizer
** Hybrid VQE Optimizer
** This example demonstrates how to integrate quantum circuits with classical optimization algorithms
** Application: Finding the Ground State Energy
*/

load "ringquantum.ring"

func main
    see "--- Starting Hybrid VQE Simulation ---" + nl
    
    # 1. Optimizer settings
    nSteps = 40           # Number of optimization cycles
    fTheta = 0.5          # Initial angle
    fLearningRate = 0.2   # Learning rate (Gradient Descent)
    
    see "Initial Theta: " + fTheta + nl
    see "Optimizing using Gradient Descent (Classical Processor)..." + nl

    # 2. The Hybrid Loop
    for i = 1 to nSteps
        # Calculate energy at the current angle using the quantum processor
        fEnergy = calculate_energy(fTheta)
        
        # Calculate numerical gradient (Numerical Gradient)
        # Gradient = [E(theta + eps) - E(theta - eps)] / 2*eps
        fEps = 0.05
        fGrad = (calculate_energy(fTheta + fEps) - calculate_energy(fTheta - fEps)) / (2 * fEps)
        
        # Classical optimization step
        fTheta -= fLearningRate * fGrad
        
        if i % 10 = 0
            see "  Step " + i + ": Energy = " + fEnergy + nl
        ok
    next

    see nl + "Optimization Finished." + nl
    see "Final Optimized Theta: " + fTheta + nl
    see "Minimum Energy found: " + calculate_energy(fTheta) + nl
    see "Note: For H=Z, the minimum energy should be -1.0 (|1> state)" + nl

# The Classical-Quantum Link (Calculate Energy)
func calculate_energy fAngle
    # 1. Quantum stage: Running the Ansatz circuit
    q = new QuantumCircuit(1)
    
    # Ansatz: Rotating the qubit by angle fAngle around the Y axis
    # Using the built-in RY function directly (GPU acceleration)
    q.RY(0, fAngle)
    
    # 2. Measurement stage: Getting the expected value <Z>
    # Using the GPU-accelerated ExpZ function instead of manual calculation
    return q.ExpectationZ(0)