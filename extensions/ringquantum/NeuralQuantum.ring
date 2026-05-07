# Neural Quantum State - Professional Wrapper
# Optimized for 1000+ Qubits

load "ringml.ring"
load "ringquantum.ring"


if isMainSourceFile(){
    see "============================================" + nl
    see "    Neural Quantum State (Professional)" + nl
    see "============================================" + nl

    # 1. Setup
    nQubits = 10
    nHidden = 20
    nTrainingSamples = 100
    nEpochs = 20
    nLearningRate = 0.01

    # 2. Initialize Neural Quantum State
    # Use a unique name to avoid naming conflicts with class properties
    oNeuralEngine = new NeuralQuantum(nQubits, nHidden)

    # 3. Define the Hamiltonian (e.g., Transverse Field Ising Model)
    oHVec = new Tensor(nQubits, 1) 
    oJMat = new Tensor(nQubits, nQubits) 

    # Set transverse field
    oHVec.fill(-1.0)
    
    # Set coupling
    for i = 1 to nQubits - 1
        oJMat.setVal(i, i+1, -1.0)
        oJMat.setVal(i+1, i, -1.0)
    next

    # 4. Train the NQS
    oNeuralEngine.Train(oHVec, oJMat, nTrainingSamples, nEpochs, nLearningRate)

    # 5. Result Visualization
    see "Sampling from trained NQS..." + nl
    oNeuralEngine.Sample(50)
    aFinalSpins = oNeuralEngine.GetSpins()
    
    nFinalEnergy = oNeuralEngine.GetLocalEnergy(oHVec, oJMat)
    
    see "--------------------------------------------" + nl
    see "Training Complete!" + nl
    see "Final Energy: " + nFinalEnergy + nl
    see "Ground State: "
    for x in aFinalSpins see "" + x next
    see nl
    see "--------------------------------------------" + nl
}

# ---------------------------------------------------
# Neural Quantum State Class
# ---------------------------------------------------

class NeuralQuantum
    pNqsHandle  # Using a unique name for the C pointer
    nQubits nHidden
    
    # Core Weight Tensors
    oWReal oWImag 
    oAReal oBReal 

    # Adam Tensors (Memory for optimizer)
    oMwTensor oVwTensor
    oMbTensor oVbTensor
    oMaTensor oVaTensor

    # Training Buffers (Pre-allocated to avoid GC crashes)
    oSumGradW oSumGradA oSumGradB oSumO oSumOA oSumOB
    oTempGradW oGradWBuf oGradABuf oGradBBuf
    oGWI oGBR oGAR

    func init nV, nH
        nQubits = nV 
        nHidden = nH
        pNqsHandle = quantum_nqs_init(nV, nH)
        
        # 1. Initializing Tensors (Using the Tensor class)
        oWReal = new Tensor(nV, nH)   oWReal.random().scalarMul(0.01)
        oWImag = new Tensor(nV, nH)   oWImag.random().scalarMul(0.01)
        oAReal = new Tensor(1, nV)    oAReal.zeros()
        oBReal = new Tensor(1, nH)    oBReal.zeros()
        
        # 2. Adam Cache (Must explicitly zero to prevent garbage NaN values)
        oMwTensor = new Tensor(nV, nH)  oMwTensor.zeros()
        oVwTensor = new Tensor(nV, nH)  oVwTensor.zeros()
        oMbTensor = new Tensor(1, nH)   oMbTensor.zeros()
        oVbTensor = new Tensor(1, nH)   oVbTensor.zeros()
        oMaTensor = new Tensor(1, nV)   oMaTensor.zeros()
        oVaTensor = new Tensor(1, nV)   oVaTensor.zeros()

        # 3. Pre-allocate Training Buffers
        oSumGradW = new Tensor(nV, nH)
        oSumGradA = new Tensor(1, nV)
        oSumGradB = new Tensor(1, nH)
        oSumO     = new Tensor(nV, nH)
        oSumOA    = new Tensor(1, nV)
        oSumOB    = new Tensor(1, nH)
        oTempGradW = new Tensor(nV, nH)
        oGradWBuf = new Tensor(nV, nH)
        oGradABuf = new Tensor(1, nV)
        oGradBBuf = new Tensor(1, nH)
        oGWI = new Tensor(nV, nH)
        oGBR = new Tensor(1, nH)
        oGAR = new Tensor(1, nV)

        Sync()
        return self

    func Sync
        # Link C handle with our Tensor objects
        quantum_nqs_bind(pNqsHandle, 
            tensor_get_data_ptr(oWReal.pData),
            tensor_get_data_ptr(oWImag.pData),
            tensor_get_data_ptr(oAReal.pData),
            tensor_get_data_ptr(oBReal.pData)
        )

    func Sample nSteps
        quantum_nqs_sample(pNqsHandle, nSteps)

    func GetSpins
        return quantum_nqs_get_spins(pNqsHandle)

    func ComputeGradients oGWR, oGWI, oGBR, oGAR
        quantum_nqs_grads(pNqsHandle, 
            tensor_get_data_ptr(oGWR.pData),
            tensor_get_data_ptr(oGWI.pData),
            tensor_get_data_ptr(oGBR.pData),
            tensor_get_data_ptr(oGAR.pData)
        )

    func UpdateWeights oGradW, oGradA, oGradB, nLR, nEpoch
        # 1. Update Weights
        tensor_update_adam(oWReal.pData, oGradW.pData, oMwTensor.pData, oVwTensor.pData, nLR, 0.9, 0.999, 0.00000001, nEpoch, 0.001)
        
        # 2. Update Visible Biases (a)
        tensor_update_adam(oAReal.pData, oGradA.pData, oMaTensor.pData, oVaTensor.pData, nLR, 0.9, 0.999, 0.00000001, nEpoch, 0.0)

        # 3. Update Hidden Biases (b)
        tensor_update_adam(oBReal.pData, oGradB.pData, oMbTensor.pData, oVbTensor.pData, nLR, 0.9, 0.999, 0.00000001, nEpoch, 0.0)
    
    func GetLocalEnergy oH, oJ
        return quantum_nqs_energy(pNqsHandle, 
            tensor_get_data_ptr(oH.pData),
            tensor_get_data_ptr(oJ.pData)
        )

    func Train oH, oJ, nSamples, nEpochs, nLR
        see "Starting Neural Training for " + nQubits + " Qubits..." + nl
        
        nLastEnergy = 0.0
        nStagnantCount = 0

        for nEpoch = 1 to nEpochs
            nSumEnergy = 0.0
            oSumGradW.zeros()
            oSumGradA.zeros()
            oSumGradB.zeros()
            oSumO.zeros()
            oSumOA.zeros()
            oSumOB.zeros()

            for nS = 1 to nSamples
                Sample(10)
                nEnergy = GetLocalEnergy(oH, oJ)
                
                ComputeGradients(oTempGradW, oGWI, oGBR, oGAR)
                
                # Accumulate Weight Gradients: SumGradW += Energy * GradientW
                oGradWBuf.copyData(oTempGradW)
                oGradWBuf.scalarMul(nEnergy)
                oSumGradW.add(oGradWBuf)
                
                # Accumulate Bias Gradients
                oGradABuf.copyData(oGAR)
                oGradABuf.scalarMul(nEnergy)
                oSumGradA.add(oGradABuf)

                oGradBBuf.copyData(oGBR)
                oGradBBuf.scalarMul(nEnergy)
                oSumGradB.add(oGradBBuf)
                
                # Accumulate Baseline Sums
                oSumO.add(oTempGradW)
                oSumOA.add(oGAR)
                oSumOB.add(oGBR)
                
                nSumEnergy += nEnergy
            next

            # Stochastic Gradient Calculation: <EO> - <E><O>
            nAvgEnergy = nSumEnergy / nSamples
            
            # W-Gradient
            oSumO.scalarMul(nAvgEnergy)
            oSumGradW.sub(oSumO).scalarMul(1.0/nSamples)
            
            # A-Gradient
            oSumOA.scalarMul(nAvgEnergy)
            oSumGradA.sub(oSumOA).scalarMul(1.0/nSamples)

            # B-Gradient
            oSumOB.scalarMul(nAvgEnergy)
            oSumGradB.sub(oSumOB).scalarMul(1.0/nSamples)

            # --- Adaptive Learning Rate Logic ---
            if fabs(nAvgEnergy - nLastEnergy) < 0.0001
                nStagnantCount++
            else
                nStagnantCount = 0
            ok
            
            if nStagnantCount >= 5
                nLR = nLR * 0.5  # Decay LR on stagnation
                nStagnantCount = 0
                see "    (Adaptive LR: Decaying to " + nLR + ")" + nl
            ok
            nLastEnergy = nAvgEnergy

            # Weight Update
            UpdateWeights(oSumGradW, oSumGradA, oSumGradB, nLR, nEpoch)
            
            if nEpoch % 5 = 0
                see "    Epoch " + nEpoch + " | Energy: " + nAvgEnergy + nl
            ok
        next
        see "Training Complete inside NeuralQuantum." + nl
        return self