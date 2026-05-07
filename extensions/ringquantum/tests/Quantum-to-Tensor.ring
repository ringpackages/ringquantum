/*
** RingQuantum Bridge - Quantum to Tensor Integration
** Quantum-Classical Tensor Bridge
** This example demonstrates how to process data quantumly and then convert it into Tensors 
** to start machine learning operations using RingTensor
*/

load "ringquantum.ring"
load "ringml.ring" # Includes AlQalam and RingTensor

func main
    see "============================================" + nl
    see "    Quantum-Classical Tensor Bridge" + nl
    see "============================================" + nl

    nQ = 10 # 1024 states (32x32 Grid)
    q = new QuantumCircuit(nQ)
    
    # 1. Quantum Pre-processing
    see "1. Generating Quantum States (10 Qubits)..." + nl
    q.H(0)
    q.CNOT(0, 5)
    q.RY(2, 0.4)
    
    # 2. Extracting probabilities to AlQalam Vector
    see "2. Extracting probabilities to AlQalam..." + nl
    probs = q.GetProbabilities()
    oVec = new QalamVector(len(probs))
    for p in probs oVec.flow(p) next
    
    # 3. Linking with RingTensor (Zero-Copy Bridge)
    # Converting the probability vector into a Tensor with dimensions 32x32
    see "3. Creating Tensor (32x32) from Quantum Data..." + nl
    oTensor = oVec.toTensor(32, 32)
    
    # 4. Performing classical matrix operations on the quantum output
    # We will multiply the resulting matrix by a random weight matrix
    see "4. Running Matrix Multiplication (Classical ML Stage)..." + nl
    oWeights = new Tensor(32, 32)
    tensor_random(oWeights.pData)
    
    oResult = new Tensor(32, 32)
    tensor_matmul(oTensor.pData, oWeights.pData, oResult.pData)
    
    see "--------------------------------------------" + nl
    see "Pipeline Finished: Quantum State -> AlQalam -> RingTensor" + nl
    oResult.printStats() 
    see "--------------------------------------------" + nl