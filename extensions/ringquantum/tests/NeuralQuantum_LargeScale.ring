# Neural Quantum State - Large Scale Simulation (100 Qubits)
load "../NeuralQuantum.ring"

SetThreads(2)

func main
    see "============================================" + nl
    see "   NQS LARGE SCALE BENCHMARK (100 QUBITS)   " + nl
    see "============================================" + nl

    # 1. System Parameters
    nQubits = 100
    nHidden = 100
    nSamples = 200
    nEpochs = 50
    nLR = 0.005

    # 2. Engine Initialization
    oEngine = new NeuralQuantum(nQubits, nHidden)

    # 3. Complex Hamiltonian Construction
    # We use a 1D Chain with random local fields
    oHVec = new Tensor(nQubits, 1)
    oJMat = new Tensor(nQubits, nQubits)

    see "-> Building Hamiltonian for 100 Qubits... "
    
    # Set random transverse fields (H_i between -1 and 1)
    for i = 1 to nQubits
        oHVec.setVal(i, 1, (random(2000)/1000.0) - 1.0)
    next

    # Set nearest neighbor couplings (J_i,i+1 = -1.0)
    for i = 1 to nQubits - 1
        oJMat.setVal(i, i+1, -1.0)
        oJMat.setVal(i+1, i, -1.0)
    next
    see "Done." + nl

    # 4. Performance Measurement
    nStart = clock()
    
    see "-> Starting High-Performance Training..." + nl
    oEngine.Train(oHVec, oJMat, nSamples, nEpochs, nLR)
    
    nEnd = clock()
    nTotalTime = (nEnd - nStart) / clockspersecond()

    # 5. Final Analytics
    see nl + "============================================" + nl
    see "   SIMULATION RESULTS" + nl
    see "============================================" + nl
    see "Total Execution Time : " + nTotalTime + " seconds" + nl
    see "Average Time / Epoch : " + (nTotalTime / nEpochs) + " seconds" + nl
    
    nFinalEnergy = oEngine.GetLocalEnergy(oHVec, oJMat)
    see "Final System Energy  : " + nFinalEnergy + nl
    
    see "Final Spin Configuration (Sampling):" + nl
    oEngine.Sample(100)
    aSpins = oEngine.GetSpins()
    
    see "State: ["
    for i = 1 to len(aSpins)
        if aSpins[i] > 0 see "+" else see "-" ok
        if i % 50 = 0 and i < nQubits see nl + "        " ok
    next
    see "]" + nl
    see "============================================" + nl
