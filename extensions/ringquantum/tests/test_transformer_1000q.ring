
load "ringml.ring"
load "../quantum_transformer.ring"

//SetQuantumThreads(2)
//EnableQuantumGPU(1)
//SetQuantumGPUThreshold(100)

nQubits = 100 //1000

func main
    see "==========================================================" + nl
    see " Quantum Transformer Strategy (" + nQubits + " Qubits Test) " + nl
    see " Integrating RingTensor, AlQalam, and RingQuantum " + nl
    see "==========================================================" + nl
    
    
    nBatch = 1024
    
    see "> Initializing AlQalam Engine (Loading Financial Data)..." + nl
    
    # Using AlQalam Native Vector (C++ Extension) To Construct Financial Arrays (Returns, Covariance/Interactions)
    oReturns = new QalamVector(nQubits)
    for i = 1 to nQubits
        oReturns.flow(0.05 * (random(100)/100)) # e.g. simulating random 5% daily returns
    next
    
    oCov = new QalamVector(nQubits * nQubits)
    for i = 1 to nQubits * nQubits
        oCov.flow(0.01 * (random(10)/10)) # Simulated covariance density (J matrix)
    next
    
    see "> AlQalam Market Data Loaded Successfully via Raw C++ VRAM/RAM!" + nl
    
    see "> Initializing Quantum Transformer (ANQS)..." + nl
    oTransformer = new QuantumTransformer(nQubits, nBatch)
    
    // Add Attention Layer: 4 Heads, 128 Dimension Size
    see "> Building Generative Transformer Layers..." + nl
    oTransformer.AddLayer(4, 128)
    
    see "> Fusing Optimizer (Adam) & Commencing VMC Training Iterations..." + nl
    nEpochs = 10
    nPenalty = 50.0
    nTarget = 20
    finalEnergy = oTransformer.TrainVMC(nEpochs, oReturns, oCov, nPenalty, nTarget)
    
    see "==========================================================" + nl
    see " Training Complete. Minimum Portfolio Energy: " + finalEnergy + nl
    see " Strategy is optimized and mapped to zero-copy memory." + nl
    see "==========================================================" + nl
