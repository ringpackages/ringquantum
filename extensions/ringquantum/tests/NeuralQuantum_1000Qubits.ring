# Neural Quantum State - Stress Test (1000 Qubits)
load "../NeuralQuantum.ring"

SetThreads(2)

func main
    see "=================================================" + nl
    see "   NQS ULTRA-SCALE STRESS TEST (1000 QUBITS)     " + nl
    see "=================================================" + nl

    # 1. Ultra-Scale Parameters
    nQubits = 1000
    nHidden = 1000
    nSamples = 100    # Lower samples to speed up the demo at this scale
    nEpochs = 20
    nLR = 0.001

    # 2. Engine Initialization
    see "-> Initializing Neural Engine (1 Million Connections)... "
    nStartInit = clock()
    oEngine = new NeuralQuantum(nQubits, nHidden)
    see "Done in " + ((clock()-nStartInit)/clockspersecond()) + "s" + nl

    # 3. Hamiltonian Configuration (Global 1D Chain)
    oHVec = new Tensor(nQubits, 1)
    oJMat = new Tensor(nQubits, nQubits)

    see "-> Constructing 1D-Ising Lattice (1000 Nodes)... "
    oHVec.fill(-1.0) # Uniform transverse field
    
    # Nearest neighbor coupling
    for i = 1 to nQubits - 1
        oJMat.setVal(i, i+1, -1.0)
        oJMat.setVal(i+1, i, -1.0)
    next
    see "Ready." + nl

    # 4. Training Execution
    see "-> Launching Ultra-Scale Training on GPU..." + nl
    nStart = clock()
    
    # Run training
    oEngine.Train(oHVec, oJMat, nSamples, nEpochs, nLR)
    
    nEnd = clock()
    nTotalTime = (nEnd - nStart) / clockspersecond()

    # 5. Performance Report
    see nl + "=================================================" + nl
    see "   PERFORMANCE ANALYTICS (1000 QUBITS)" + nl
    see "=================================================" + nl
    see "Total GPU Training Time : " + nTotalTime + " seconds" + nl
    see "Throughput              : " + (nEpochs / nTotalTime) + " Epochs/sec" + nl
    
    nFinalEnergy = oEngine.GetLocalEnergy(oHVec, oJMat)
    see "Approx. Ground Energy   : " + nFinalEnergy + nl
    see "-------------------------------------------------" + nl
    see "Simulation Scale: 1000 Qubits - SUCCESS" + nl
    see "=================================================" + nl
