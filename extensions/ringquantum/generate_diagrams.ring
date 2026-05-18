# ⚛️ RingQuantum Premium High-Fidelity Diagram & Logo Generator
# Automatically outputs maximum precision SVGs using SVGLib.
# Author: Antigravity AI Pair Programmer
# Date: May 18, 2026

load "svglib.ring"

see "====================================================" + nl
see "   RINGQUANTUM HIGH-FIDELITY DIAGRAM GENERATOR" + nl
see "====================================================" + nl
see "Generating high-definition vector assets..." + nl

# Generate Logo and diagrams
generateLogo()
generateThreeLayerArchitecture()
generateZeroCopyPipeline()
generateVmcTrainingPipeline()
generateHybridOptimizationPipeline()

see "----------------------------------------------------" + nl
see "All high-precision assets generated successfully!" + nl

# ==============================================================================
# 0. Premium Logo Generator (images/logo.svg)
# ==============================================================================
func generateLogo
    see "Generating logo: images/logo.svg..." + nl
    
    width = 500
    height = 500
    svg = new SVGWriter(width, height)
    svg.setViewBox(0, 0, width, height)
    
    # 1. Futuristic Cyber Background (Circular App Icon Badge)
    bgGrad = svg.createLinearGradient(0, 0, 100, 100, [
        [0,   "#0b1329"], # Deep midnight blue
        [100, "#010409"]  # Pure pitch black
    ])
    
    # Glow filter
    glow = svg.createGlowFilter(12, "#00f2fe")
    shadow = svg.createShadowFilter(6, 6, 10, "#000000")
    
    # Base Badge
    svg.addCircle(250, 250, 220, [
        :fill = bgGrad, 
        :stroke = "#1e293b", 
        :strokeWidth = 3, 
        :filter = shadow
    ])
    
    # Blueprint grid inside the badge
    badgeGrid = svg.createGridPattern(20, 1, "#1e293b", bgGrad)
    svg.addCircle(250, 250, 218, [:fill = badgeGrid, :opacity = 0.25])
    
    # 2. Outer glowing rim
    rimGrad = svg.createLinearGradient(0, 0, 100, 100, [
        [0,   "#00d2ff"],
        [50,  "#7928ca"],
        [100, "#ff007f"]
    ])
    svg.addCircle(250, 250, 210, [
        :fill = "none", 
        :stroke = rimGrad, 
        :strokeWidth = 2, 
        :opacity = 0.7
    ])

    # 3. Quantum Orbital Rings (Precise Rotated Ellipses)
    orbitGrad = svg.createLinearGradient(0, 0, 100, 0, [
        [0,   "#00f2fe"], # Cyan
        [100, "#4facfe"]  # Deep Blue
    ])
    
    # Draw 3 quantum orbits rotated at 45, 90, and 135 degrees
    svg.addEllipse(250, 250, 175, 55, [
        :fill = "none", 
        :stroke = orbitGrad, 
        :strokeWidth = 2.5, 
        :opacity = 0.8, 
        :rotate = [45, 250, 250]
    ])
    svg.addEllipse(250, 250, 175, 55, [
        :fill = "none", 
        :stroke = orbitGrad, 
        :strokeWidth = 2.5, 
        :opacity = 0.8, 
        :rotate = [135, 250, 250]
    ])
    svg.addEllipse(250, 250, 175, 55, [
        :fill = "none", 
        :stroke = orbitGrad, 
        :strokeWidth = 2.5, 
        :opacity = 0.8, 
        :rotate = [90, 250, 250]
    ])

    # 4. Neural Network Synapses Lattices (Intertwined AI nodes)
    # Synapse Lines
    svg.addLine(126, 126, 250, 250, [:stroke = "#7928ca", :strokeWidth = 1, :opacity = 0.4])
    svg.addLine(374, 126, 250, 250, [:stroke = "#7928ca", :strokeWidth = 1, :opacity = 0.4])
    svg.addLine(126, 374, 250, 250, [:stroke = "#7928ca", :strokeWidth = 1, :opacity = 0.4])
    svg.addLine(374, 374, 250, 250, [:stroke = "#7928ca", :strokeWidth = 1, :opacity = 0.4])
    svg.addLine(250, 75,  250, 250, [:stroke = "#7928ca", :strokeWidth = 1, :opacity = 0.4])
    svg.addLine(250, 425, 250, 250, [:stroke = "#7928ca", :strokeWidth = 1, :opacity = 0.4])

    # Synapse Nodes (Glowing small circles)
    svg.addCircle(126, 126, 6, [:fill = "#00f2fe", :filter = glow])
    svg.addCircle(374, 126, 6, [:fill = "#ff007f", :filter = glow])
    svg.addCircle(126, 374, 6, [:fill = "#ff007f", :filter = glow])
    svg.addCircle(374, 374, 6, [:fill = "#00f2fe", :filter = glow])
    svg.addCircle(250, 75,  7, [:fill = "#38bdf8", :filter = glow])
    svg.addCircle(250, 425, 7, [:fill = "#a855f7", :filter = glow])

    # 5. Pulsing Qubit core (Radial glowing sphere)
    qubitGrad = svg.createRadialGradient(250, 250, 45, [
        [0,   "#ffffff"],
        [25,  "#00f2fe"],
        [75,  "#7928ca"],
        [100, "#0b1329"]
    ])
    svg.addCircle(250, 250, 50, [:fill = qubitGrad, :filter = shadow])

    # 6. Central Cybernetic Typography (Q / RQ)
    svg.addTextCentered("Q", 250, 254, [
        :fontFamily = "system-ui, -apple-system, sans-serif", 
        :fontSize = 52, 
        :fontWeight = "bold", 
        :fill = "#ffffff",
        :opacity = 0.95
    ])
    
    # 7. Brand Label Subtitle
    brandGrad = svg.createLinearGradient(0, 0, 100, 0, [
        [0,   "#38bdf8"],
        [100, "#ec4899"]
    ])
    svg.addTextCentered("RINGQUANTUM", 250, 360, [
        :fontFamily = "system-ui, 'Segoe UI', sans-serif", 
        :fontSize = 18, 
        :fontWeight = "bold", 
        :fill = brandGrad
    ])
    
    # Modern cybernetic tick lines under subtitle
    svg.addLine(180, 375, 230, 375, [:stroke = "#00f2fe", :strokeWidth = 2])
    svg.addLine(270, 375, 320, 375, [:stroke = "#ff007f", :strokeWidth = 2])
    svg.addCircle(250, 375, 3, [:fill = "#ffffff"])

    svg.save("images/logo.svg")

# ==============================================================================
# 1. Three-Layer System Architecture Diagram (images/three_layer_architecture.svg)
# ==============================================================================
func generateThreeLayerArchitecture
    see "Generating: images/three_layer_architecture.svg..." + nl
    
    width = 1000
    height = 820
    svg = new SVGWriter(width, height)
    svg.setViewBox(0, 0, width, height)
    
    # Background slate
    bgGrad = svg.createLinearGradient(0, 0, 100, 100, [[0, "#0B111E"], [100, "#1A2234"]])
    svg.addRect(0, 0, width, height, [:fill = bgGrad])
    
    # Mesh grid
    grid = svg.createGridPattern(40, 1, "#2D3748", bgGrad)
    svg.addRect(0, 0, width, height, [:fill = grid, :opacity = 0.2])
    
    shadow = svg.createShadowFilter(5, 5, 8, "#020617")
    
    # Custom Gradients for Layers
    gradApp = svg.createLinearGradient(0, 0, 100, 0, [[0, "#0D9488"], [100, "#115E59"]])
    gradKernel = svg.createLinearGradient(0, 0, 100, 0, [[0, "#4F46E5"], [100, "#3730A3"]])
    gradDeps = svg.createLinearGradient(0, 0, 100, 0, [[0, "#BE185D"], [100, "#9D174D"]])
    
    subCardGrad = svg.createLinearGradient(0, 0, 0, 100, [[0, "#1B2234"], [100, "#0B111E"]])

    # Header Title
    svg.addTextCentered("⚛️ RINGQUANTUM HYBRID NEURAL-QUANTUM ENGINE", width / 2, 45, [
        :fontFamily = "'Segoe UI', sans-serif", :fontSize = 24, :fontWeight = "bold", :fill = "#F8FAFC"
    ])
    svg.addTextCentered("Production-Grade Three-Layer Separation of Concerns & Hardware Dispatcher", width / 2, 75, [
        :fontFamily = "'Segoe UI', sans-serif", :fontSize = 14, :fill = "#94A3B8"
    ])
    
    # ----------------------------------------------------
    # LAYER 1: APPLICATION LAYER
    # ----------------------------------------------------
    svg.addRoundedRect(50, 110, 900, 160, 12, [:fill = gradApp, :stroke = "#0D9488", :strokeWidth = 1.5, :filter = shadow])
    svg.addText("APPLICATION LAYER (Pure Ring Object-Oriented APIs & Structs)", 70, 140, [
        :fontFamily = "'Segoe UI', sans-serif", :fontSize = 13, :fontWeight = "bold", :fill = "#CCFBF1"
    ])
    
    # QuantumCircuit Box
    svg.addRoundedRect(80, 165, 250, 85, 8, [:fill = subCardGrad, :stroke = "#14B8A6", :strokeWidth = 1])
    svg.addTextCentered("QuantumCircuit", 205, 195, [:fontFamily = "'Segoe UI', sans-serif", :fontSize = 14, :fontWeight = "bold", :fill = "#2DD4BF"])
    svg.addTextCentered("Exact Quantum States (ringquantum.ring)", 205, 215, [:fontFamily = "'Segoe UI', sans-serif", :fontSize = 10, :fill = "#94A3B8"])
    svg.addTextCentered("Universal Gate API: H, CNOT, MCX, ExpZ", 205, 232, [:fontFamily = "'Segoe UI', sans-serif", :fontSize = 9, :fill = "#cbd5e1"])

    # NeuralQuantum Box
    svg.addRoundedRect(375, 165, 250, 85, 8, [:fill = subCardGrad, :stroke = "#14B8A6", :strokeWidth = 1])
    svg.addTextCentered("NeuralQuantum", 500, 195, [:fontFamily = "'Segoe UI', sans-serif", :fontSize = 14, :fontWeight = "bold", :fill = "#2DD4BF"])
    svg.addTextCentered("NQS RBM Wavefunction (NeuralQuantum.ring)", 500, 215, [:fontFamily = "'Segoe UI', sans-serif", :fontSize = 10, :fill = "#94A3B8"])
    svg.addTextCentered("Variational Optimization & Ising/Binary Maps", 500, 232, [:fontFamily = "'Segoe UI', sans-serif", :fontSize = 9, :fill = "#cbd5e1"])

    # QuantumTransformer Box
    svg.addRoundedRect(670, 165, 250, 85, 8, [:fill = subCardGrad, :stroke = "#14B8A6", :strokeWidth = 1])
    svg.addTextCentered("QuantumTransformer", 795, 195, [:fontFamily = "'Segoe UI', sans-serif", :fontSize = 14, :fontWeight = "bold", :fill = "#2DD4BF"])
    svg.addTextCentered("ANQS Attn Model (quantum_transformer.ring)", 795, 215, [:fontFamily = "'Segoe UI', sans-serif", :fontSize = 10, :fill = "#94A3B8"])
    svg.addTextCentered("Causal Masked Sampling & TDVP Solver", 795, 232, [:fontFamily = "'Segoe UI', sans-serif", :fontSize = 9, :fill = "#cbd5e1"])

    # ----------------------------------------------------
    # LAYER 2: C KERNEL LAYER (HIGH PERFORMANCE)
    # ----------------------------------------------------
    svg.addRoundedRect(50, 320, 900, 275, 12, [:fill = gradKernel, :stroke = "#4F46E5", :strokeWidth = 1.5, :filter = shadow])
    svg.addText("C KERNEL LAYER (Lock-Free Multi-Threaded Math Engine - ring_quantum.c)", 70, 350, [
        :fontFamily = "'Segoe UI', sans-serif", :fontSize = 13, :fontWeight = "bold", :fill = "#E0E7FF"
    ])
    
    # Statevector Simulator Card
    svg.addRoundedRect(80, 375, 250, 175, 8, [:fill = subCardGrad, :stroke = "#6366F1", :strokeWidth = 1])
    svg.addTextCentered("Statevector Engine", 205, 400, [:fontFamily = "'Segoe UI', sans-serif", :fontSize = 13, :fontWeight = "bold", :fill = "#818CF8"])
    svg.addTextCentered("• Interleaved Complex Memory Layout", 205, 430, [:fontFamily = "'Segoe UI', sans-serif", :fontSize = 10, :fill = "#CBD5E1"])
    svg.addTextCentered("• Bitwise Gate XOR Indexing", 205, 450, [:fontFamily = "'Segoe UI', sans-serif", :fontSize = 10, :fill = "#CBD5E1"])
    svg.addTextCentered("• Multi-Controlled Unitaries (MCU)", 205, 470, [:fontFamily = "'Segoe UI', sans-serif", :fontSize = 10, :fill = "#CBD5E1"])
    svg.addTextCentered("• Exact Amplitudes [Re, Im]", 205, 490, [:fontFamily = "'Segoe UI', sans-serif", :fontSize = 10, :fill = "#CBD5E1"])
    svg.addTextCentered("Exact limit: ≤ 25 Qubits", 205, 525, [:fontFamily = "'Segoe UI', sans-serif", :fontSize = 10, :fontWeight = "bold", :fill = "#F43F5E"])

    # NQS RBM Engine Card
    svg.addRoundedRect(375, 375, 250, 175, 8, [:fill = subCardGrad, :stroke = "#6366F1", :strokeWidth = 1])
    svg.addTextCentered("NQS (RBM) Solver", 500, 400, [:fontFamily = "'Segoe UI', sans-serif", :fontSize = 13, :fontWeight = "bold", :fill = "#818CF8"])
    svg.addTextCentered("• Metropolis-Hastings MCMC Sampler", 500, 430, [:fontFamily = "'Segoe UI', sans-serif", :fontSize = 10, :fill = "#CBD5E1"])
    svg.addTextCentered("• In-Memory Spin Configurations", 500, 450, [:fontFamily = "'Segoe UI', sans-serif", :fontSize = 10, :fill = "#CBD5E1"])
    svg.addTextCentered("• Z-score Advantage REINFORCE", 500, 470, [:fontFamily = "'Segoe UI', sans-serif", :fontSize = 10, :fill = "#CBD5E1"])
    svg.addTextCentered("• Direct Visible Bias Constraints", 500, 490, [:fontFamily = "'Segoe UI', sans-serif", :fontSize = 10, :fill = "#CBD5E1"])
    svg.addTextCentered("Approx limit: ≤ 500 Qubits", 500, 525, [:fontFamily = "'Segoe UI', sans-serif", :fontSize = 10, :fontWeight = "bold", :fill = "#FB923C"])

    # ANQS Transformer Card
    svg.addRoundedRect(670, 375, 250, 175, 8, [:fill = subCardGrad, :stroke = "#6366F1", :strokeWidth = 1])
    svg.addTextCentered("Transformer (ANQS)", 795, 400, [:fontFamily = "'Segoe UI', sans-serif", :fontSize = 13, :fontWeight = "bold", :fill = "#818CF8"])
    svg.addTextCentered("• Masked Complex Attention Heads", 795, 430, [:fontFamily = "'Segoe UI', sans-serif", :fontSize = 10, :fill = "#CBD5E1"])
    svg.addTextCentered("• Exact Autoregressive Bernoulli", 795, 450, [:fontFamily = "'Segoe UI', sans-serif", :fontSize = 10, :fill = "#CBD5E1"])
    svg.addTextCentered("• Thread-Local Lock-Free XorShift", 795, 470, [:fontFamily = "'Segoe UI', sans-serif", :fontSize = 10, :fill = "#CBD5E1"])
    svg.addTextCentered("• Parameter Jacobian Generation", 795, 490, [:fontFamily = "'Segoe UI', sans-serif", :fontSize = 10, :fill = "#CBD5E1"])
    svg.addTextCentered("Approx limit: ≤ 1000+ Qubits", 795, 525, [:fontFamily = "'Segoe UI', sans-serif", :fontSize = 10, :fontWeight = "bold", :fill = "#A855F7"])

    # Hardware Accelerator Bar
    accelGrad = svg.createLinearGradient(0,0,100,0,[[0,"#1e293b"],[100,"#334155"]])
    svg.addRoundedRect(80, 560, 840, 22, 5, [:fill = accelGrad])
    svg.addTextCentered("HARDWARE DISPATCH: OpenMP CPU Multi-Threading  |  OpenCL Mapped Buffers FP32 Turbo (GPU Shared Memory)", 520, 571, [
        :fontFamily = "'Segoe UI', sans-serif", :fontSize = 9.5, :fontWeight = "bold", :fill = "#38BDF8"
    ])

    # ----------------------------------------------------
    # LAYER 3: COOPERATIVE DEPENDENCIES
    # ----------------------------------------------------
    svg.addRoundedRect(50, 640, 900, 140, 12, [:fill = gradDeps, :stroke = "#DB2777", :strokeWidth = 1.5, :filter = shadow])
    svg.addText("EXTERNAL COOPERATIVE ENGINE DEPENDENCIES (Zero-Copy Pointer Interoperability)", 70, 670, [
        :fontFamily = "'Segoe UI', sans-serif", :fontSize = 13, :fontWeight = "bold", :fill = "#FCE7F3"
    ])
    
    # RingTensor Card
    svg.addRoundedRect(80, 695, 250, 70, 8, [:fill = subCardGrad, :stroke = "#EC4899", :strokeWidth = 1])
    svg.addTextCentered("RingTensor (C)", 205, 720, [:fontFamily = "'Segoe UI', sans-serif", :fontSize = 14, :fontWeight = "bold", :fill = "#F472B6"])
    svg.addTextCentered("In-Place Adam Momentum & Graph Ops", 205, 742, [:fontFamily = "'Segoe UI', sans-serif", :fontSize = 10, :fill = "#94A3B8"])

    # AlQalam Card
    svg.addRoundedRect(375, 695, 250, 70, 8, [:fill = subCardGrad, :stroke = "#EC4899", :strokeWidth = 1])
    svg.addTextCentered("AlQalam (C++)", 500, 720, [:fontFamily = "'Segoe UI', sans-serif", :fontSize = 14, :fontWeight = "bold", :fill = "#F472B6"])
    svg.addTextCentered("Matrix-Free Conjugate Gradient Solver", 500, 742, [:fontFamily = "'Segoe UI', sans-serif", :fontSize = 10, :fill = "#94A3B8"])

    # RingML Card
    svg.addRoundedRect(670, 695, 250, 70, 8, [:fill = subCardGrad, :stroke = "#EC4899", :strokeWidth = 1])
    svg.addTextCentered("RingML (Ring)", 795, 720, [:fontFamily = "'Segoe UI', sans-serif", :fontSize = 14, :fontWeight = "bold", :fill = "#F472B6"])
    svg.addTextCentered("Orchestrated SGD Optimizer Controllers", 795, 742, [:fontFamily = "'Segoe UI', sans-serif", :fontSize = 10, :fill = "#94A3B8"])

    # Connecting Arrows
    arrow = svg.createArrowMarker(8, "#64748B")
    
    # Application to Kernel
    svg.addLine(205, 270, 205, 320, [:stroke = "#64748B", :strokeWidth = 2, :strokeDash = "4,4", :markerEnd = arrow])
    svg.addLine(500, 270, 500, 320, [:stroke = "#64748B", :strokeWidth = 2, :strokeDash = "4,4", :markerEnd = arrow])
    svg.addLine(795, 270, 795, 320, [:stroke = "#64748B", :strokeWidth = 2, :strokeDash = "4,4", :markerEnd = arrow])
    
    # Kernel to Dependencies
    svg.addLine(205, 595, 205, 640, [:stroke = "#64748B", :strokeWidth = 2, :strokeDash = "4,4", :markerEnd = arrow])
    svg.addLine(500, 595, 500, 640, [:stroke = "#64748B", :strokeWidth = 2, :strokeDash = "4,4", :markerEnd = arrow])
    svg.addLine(795, 595, 795, 640, [:stroke = "#64748B", :strokeWidth = 2, :strokeDash = "4,4", :markerEnd = arrow])

    svg.save("images/three_layer_architecture.svg")

# ==============================================================================
# 2. Zero-Copy Memory Pipeline Diagram (images/zero_copy_pipeline.svg)
# ==============================================================================
func generateZeroCopyPipeline
    see "Generating: images/zero_copy_pipeline.svg..." + nl
    
    width = 1000
    height = 580
    svg = new SVGWriter(width, height)
    svg.setViewBox(0, 0, width, height)
    
    # Background slate
    bgGrad = svg.createLinearGradient(0, 0, 100, 100, [[0, "#010409"], [100, "#0D1117"]])
    svg.addRect(0, 0, width, height, [:fill = bgGrad])
    
    # Blueprint grid
    grid = svg.createGridPattern(30, 1, "#1F2937", bgGrad)
    svg.addRect(0, 0, width, height, [:fill = grid, :opacity = 0.25])
    
    shadow = svg.createShadowFilter(5, 5, 8, "#020617")
    
    # Header
    svg.addTextCentered("🚀 HIGH-PRECISION ZERO-COPY MEMORY PIPELINE", width / 2, 45, [
        :fontFamily = "'Segoe UI', sans-serif", :fontSize = 24, :fontWeight = "bold", :fill = "#F8FAFC"
    ])
    svg.addTextCentered("Direct hardware memory allocation and pointer-sharing to bypass C/C++/Ring copy overhead", width / 2, 75, [
        :fontFamily = "'Segoe UI', sans-serif", :fontSize = 14, :fill = "#94A3B8"
    ])

    # Left: Ring Orchestration Layer (CPU)
    ringGrad = svg.createLinearGradient(0, 0, 0, 100, [[0, "#0284C7"], [100, "#0369A1"]])
    svg.addRoundedRect(50, 120, 220, 360, 10, [:fill = ringGrad, :stroke = "#0EA5E9", :strokeWidth = 1.5, :filter = shadow])
    svg.addTextCentered("Ring Interpreter (CPU)", 160, 150, [:fontFamily = "'Segoe UI', sans-serif", :fontSize = 15, :fontWeight = "bold", :fill = "#F0F9FF"])
    svg.addTextCentered("Orchestrates allocation and binds", 160, 172, [:fontFamily = "'Segoe UI', sans-serif", :fontSize = 10, :fill = "#BAE6FD"])
    
    subGrad = svg.createLinearGradient(0, 0, 0, 100, [[0, "#0D1117"], [100, "#161B22"]])
    
    # Steps
    svg.addRoundedRect(65, 205, 190, 52, 6, [:fill = subGrad, :stroke = "#0284C7"])
    svg.addTextCentered("1. W = new Tensor(N, M)", 160, 225, [:fontFamily = "'Segoe UI', sans-serif", :fontSize = 11, :fontWeight = "bold", :fill = "#38BDF8"])
    svg.addTextCentered("Allocates double* array in C", 160, 243, [:fontFamily = "'Segoe UI', sans-serif", :fontSize = 9, :fill = "#94A3B8"])

    svg.addRoundedRect(65, 275, 190, 52, 6, [:fill = subGrad, :stroke = "#0284C7"])
    svg.addTextCentered("2. ptr = W.data_ptr()", 160, 295, [:fontFamily = "'Segoe UI', sans-serif", :fontSize = 11, :fontWeight = "bold", :fill = "#38BDF8"])
    svg.addTextCentered("Extracts physical memory address", 160, 313, [:fontFamily = "'Segoe UI', sans-serif", :fontSize = 9, :fill = "#94A3B8"])

    svg.addRoundedRect(65, 345, 190, 52, 6, [:fill = subGrad, :stroke = "#0284C7"])
    svg.addTextCentered("3. quantum_bind(nqs, ptr)", 160, 365, [:fontFamily = "'Segoe UI', sans-serif", :fontSize = 11, :fontWeight = "bold", :fill = "#38BDF8"])
    svg.addTextCentered("Maps exact address to C struct", 160, 383, [:fontFamily = "'Segoe UI', sans-serif", :fontSize = 9, :fill = "#94A3B8"])

    svg.addRoundedRect(65, 415, 190, 48, 6, [:fill = subGrad, :stroke = "#0284C7"])
    svg.addTextCentered("4. Train (In-place)", 160, 432, [:fontFamily = "'Segoe UI', sans-serif", :fontSize = 11, :fontWeight = "bold", :fill = "#38BDF8"])
    svg.addTextCentered("No copy during iterations", 160, 448, [:fontFamily = "'Segoe UI', sans-serif", :fontSize = 9, :fill = "#94A3B8"])

    # Center: High-Precision SILICON CHIP STYLE RAM CARD
    chipBg = svg.createLinearGradient(0,0,0,100,[[0,"#064E3B"],[100,"#022C22"]])
    svg.addRoundedRect(350, 180, 300, 240, 8, [:fill = chipBg, :stroke = "#059669", :strokeWidth = 2, :filter = shadow])
    
    # Draw metallic circuit traces (representing technical precision)
    svg.addLine(350, 210, 400, 210, [:stroke = "#10B981", :strokeWidth = 1.5, :opacity = 0.5])
    svg.addLine(350, 240, 400, 240, [:stroke = "#10B981", :strokeWidth = 1.5, :opacity = 0.5])
    svg.addLine(350, 360, 400, 360, [:stroke = "#10B981", :strokeWidth = 1.5, :opacity = 0.5])
    svg.addLine(350, 390, 400, 390, [:stroke = "#10B981", :strokeWidth = 1.5, :opacity = 0.5])
    svg.addLine(600, 210, 650, 210, [:stroke = "#10B981", :strokeWidth = 1.5, :opacity = 0.5])
    svg.addLine(600, 390, 650, 390, [:stroke = "#10B981", :strokeWidth = 1.5, :opacity = 0.5])

    # Memory gold pins on RAM sides
    for py = 190 to 410 step 15
        svg.addRect(344, py, 6, 8, [:fill = "#F59E0B"])
        svg.addRect(650, py, 6, 8, [:fill = "#F59E0B"])
    next

    # Microchips inside RAM
    svg.addRoundedRect(420, 200, 160, 35, 4, [:fill = "#111827", :stroke = "#475569"])
    svg.addTextCentered("PHYSICAL RAM MODULE", 500, 218, [:fontFamily = "Courier New", :fontSize = 11, :fontWeight = "bold", :fill = "#F3F4F6"])
    
    svg.addRoundedRect(370, 255, 260, 140, 6, [:fill = "#1E293B", :stroke = "#10B981", :strokeWidth = 1.5])
    svg.addTextCentered("SHARED DOUBLE POINTER ARRAYS", 500, 275, [:fontFamily = "'Segoe UI', sans-serif", :fontSize = 11, :fontWeight = "bold", :fill = "#34D399"])
    
    # Show memory addresses (Precision Detail!)
    svg.addRoundedRect(385, 295, 230, 85, 4, [:fill = "#0F172A"])
    svg.addTextCentered("double* W_real ──► [0x7FFE6B30]", 500, 315, [:fontFamily = "Courier New", :fontSize = 11, :fontWeight = "bold", :fill = "#F59E0B"])
    svg.addTextCentered("double* W_imag ──► [0x7FFE6B68]", 500, 335, [:fontFamily = "Courier New", :fontSize = 11, :fontWeight = "bold", :fill = "#F59E0B"])
    svg.addTextCentered("double* a_real ──► [0x7FFE6C00]", 500, 355, [:fontFamily = "Courier New", :fontSize = 11, :fontWeight = "bold", :fill = "#F59E0B"])

    # Right Stack: Shared Engines (Direct Hardware Readers)
    # RingTensor (C)
    tensorGrad = svg.createLinearGradient(0, 0, 100, 0, [[0, "#166534"], [100, "#14532D"]])
    svg.addRoundedRect(720, 120, 230, 85, 8, [:fill = tensorGrad, :stroke = "#22C55E", :strokeWidth = 1.5, :filter = shadow])
    svg.addTextCentered("RingTensor Engine", 835, 148, [:fontFamily = "'Segoe UI', sans-serif", :fontSize = 14, :fontWeight = "bold", :fill = "#F0FDF4"])
    svg.addTextCentered("Directly updates [0x7FFE6B30]", 835, 170, [:fontFamily = "Courier New", :fontSize = 10, :fill = "#A7F3D0"])
    svg.addTextCentered("In-Place Adam Optimizer Loop", 835, 185, [:fontFamily = "'Segoe UI', sans-serif", :fontSize = 9, :fill = "#BBF7D0"])

    # RingQuantum (C)
    quantumGrad = svg.createLinearGradient(0, 0, 100, 0, [[0, "#5B21B6"], [100, "#4C1D95"]])
    svg.addRoundedRect(720, 245, 230, 85, 8, [:fill = quantumGrad, :stroke = "#A78BFA", :strokeWidth = 1.5, :filter = shadow])
    svg.addTextCentered("RingQuantum Engine", 835, 273, [:fontFamily = "'Segoe UI', sans-serif", :fontSize = 14, :fontWeight = "bold", :fill = "#F5F3FF"])
    svg.addTextCentered("Binds: nqs->W_real = pointer", 835, 295, [:fontFamily = "Courier New", :fontSize = 10, :fill = "#DDD6FE"])
    svg.addTextCentered("Runs MCMC / Causal Attn loops", 835, 310, [:fontFamily = "'Segoe UI', sans-serif", :fontSize = 9, :fill = "#E9D5FF"])

    # AlQalam (C++)
    qalamGrad = svg.createLinearGradient(0, 0, 100, 0, [[0, "#9D174D"], [100, "#831843"]])
    svg.addRoundedRect(720, 370, 230, 85, 8, [:fill = qalamGrad, :stroke = "#F472B6", :strokeWidth = 1.5, :filter = shadow])
    svg.addTextCentered("AlQalam Vector Engine", 835, 398, [:fontFamily = "'Segoe UI', sans-serif", :fontSize = 14, :fontWeight = "bold", :fill = "#FDF2F8"])
    svg.addTextCentered("Reads directly via flowFromPtr", 835, 420, [:fontFamily = "Courier New", :fontSize = 10, :fill = "#FBCFE8"])
    svg.addTextCentered("Solves TDVP CG systems in C++", 835, 435, [:fontFamily = "'Segoe UI', sans-serif", :fontSize = 9, :fill = "#F9A8D4"])

    # Arrow connections
    arrowBlue = svg.createArrowMarker(8, "#38BDF8")
    arrowGreen = svg.createArrowMarker(8, "#22C55E")
    arrowPurple = svg.createArrowMarker(8, "#A78BFA")
    arrowPink = svg.createArrowMarker(8, "#EC4899")
    arrowAmber = svg.createArrowMarker(8, "#F59E0B")

    # Allocation: Ring -> RAM Module
    svg.addLine(270, 231, 340, 231, [:stroke = "#F59E0B", :strokeWidth = 2, :markerEnd = arrowAmber])
    svg.addText("Allocates RAM Module", 272, 222, [:fontFamily = "'Segoe UI', sans-serif", :fontSize = 8.5, :fill = "#F59E0B"])

    # Bind pointer: Ring -> RAM pointer
    svg.addLine(270, 365, 340, 365, [:stroke = "#38BDF8", :strokeWidth = 2, :markerEnd = arrowBlue])
    svg.addText("Retrieves pointer & binds", 272, 356, [:fontFamily = "'Segoe UI', sans-serif", :fontSize = 8.5, :fill = "#38BDF8"])

    # RingTensor <--> RAM Module
    svg.addLine(656, 250, 720, 185, [:stroke = "#22C55E", :strokeWidth = 2, :strokeDash = "3,3", :markerEnd = arrowGreen])
    
    # RingQuantum <--> RAM Module
    svg.addLine(656, 300, 720, 300, [:stroke = "#A78BFA", :strokeWidth = 2, :markerEnd = arrowPurple, :markerStart = arrowAmber])
    svg.addText("Zero-Copy Read/Write", 658, 292, [:fontFamily = "'Segoe UI', sans-serif", :fontSize = 8, :fill = "#A78BFA"])
    
    # AlQalam <--> RAM Module
    svg.addLine(656, 350, 720, 410, [:stroke = "#EC4899", :strokeWidth = 2, :strokeDash = "3,3", :markerEnd = arrowPink])

    # Footer note card
    svg.addRoundedRect(50, 495, 900, 50, 6, [:fill = "#1E293B", :stroke = "#475569"])
    svg.addTextCentered("Zero PCIe Bus copies / Zero Memory allocations in iterations. Intel Core thread cache performance optimization.", 500, 524, [
        :fontFamily = "'Segoe UI', sans-serif", :fontSize = 11, :fontWeight = "bold", :fill = "#38BDF8"
    ])

    svg.save("images/zero_copy_pipeline.svg")

# ==============================================================================
# 3. Variational Monte Carlo (VMC) Training Loop (images/vmc_training_pipeline.svg)
# ==============================================================================
func generateVmcTrainingPipeline
    see "Generating: images/vmc_training_pipeline.svg..." + nl
    
    width = 1100
    height = 680
    svg = new SVGWriter(width, height)
    svg.setViewBox(0, 0, width, height)
    
    # Background slate
    bgGrad = svg.createLinearGradient(0, 0, 100, 100, [[0, "#070A13"], [100, "#151B2E"]])
    svg.addRect(0, 0, width, height, [:fill = bgGrad])
    
    # Grid
    grid = svg.createGridPattern(35, 1, "#242B3D", bgGrad)
    svg.addRect(0, 0, width, height, [:fill = grid, :opacity = 0.2])
    
    shadow = svg.createShadowFilter(5, 5, 8, "#020617")
    
    # Header
    svg.addTextCentered("🧠 VARIATIONAL MONTE CARLO (VMC) OPTIMIZATION LOOP", width / 2, 45, [
        :fontFamily = "'Segoe UI', sans-serif", :fontSize = 24, :fontWeight = "bold", :fill = "#F8FAFC"
    ])
    svg.addTextCentered("RBM Wavefunction ground-state search with direct visible constraints & center-normalized REINFORCE", width / 2, 75, [
        :fontFamily = "'Segoe UI', sans-serif", :fontSize = 14, :fill = "#94A3B8"
    ])

    arrow = svg.createArrowMarker(8, "#94A3B8")
    arrowGreen = svg.createArrowMarker(8, "#10B981")
    arrowRed = svg.createArrowMarker(8, "#F43F5E")

    boxFill = "#1E293B"
    boxStroke = "#475569"

    # Step 1: Start Epoch
    svg.addRoundedRect(50, 140, 180, 80, 8, [:fill = "#0369A1", :stroke = "#0EA5E9", :strokeWidth = 1.5, :filter = shadow])
    svg.addTextCentered("1. START EPOCH", 140, 170, [:fontFamily = "'Segoe UI', sans-serif", :fontSize = 13, :fontWeight = "bold", :fill = "#FFFFFF"])
    svg.addTextCentered("Reset: gW, ga, gb = 0", 140, 192, [:fontFamily = "Courier New", :fontSize = 10, :fill = "#BAE6FD"])
    svg.addTextCentered("Prepare batch samples", 140, 207, [:fontFamily = "'Segoe UI', sans-serif", :fontSize = 9, :fill = "#93C5FD"])

    # Step 2: RBM Wavefunction & Sampling (Formula precision!)
    svg.addRoundedRect(280, 140, 230, 110, 8, [:fill = boxFill, :stroke = boxStroke, :strokeWidth = 1, :filter = shadow])
    svg.addTextCentered("2. SAMPLING & ANSATZ", 395, 162, [:fontFamily = "'Segoe UI', sans-serif", :fontSize = 13, :fontWeight = "bold", :fill = "#38BDF8"])
    svg.addTextCentered("ψ(s) = exp(Σ aᵢsᵢ) Π cosh(bⱼ+ΣWᵢⱼsᵢ)", 395, 185, [:fontFamily = "Courier New", :fontSize = 9.5, :fontWeight = "bold", :fill = "#F59E0B"])
    svg.addTextCentered("• Metropolis MCMC (Ising {-1,1})", 395, 207, [:fontFamily = "'Segoe UI', sans-serif", :fontSize = 10, :fill = "#CBD5E1"])
    svg.addTextCentered("• Accept: α = min(1, |ψ(s')|²/|ψ(s)|²)", 395, 227, [:fontFamily = "Courier New", :fontSize = 9.5, :fill = "#38BDF8"])

    # Step 3: Compute Energies & Penalty
    svg.addRoundedRect(550, 140, 230, 110, 8, [:fill = boxFill, :stroke = boxStroke, :strokeWidth = 1, :filter = shadow])
    svg.addTextCentered("3. PORTFOLIO ENERGY", 665, 162, [:fontFamily = "'Segoe UI', sans-serif", :fontSize = 13, :fontWeight = "bold", :fill = "#F59E0B"])
    svg.addTextCentered("E_local = 2·Σ Jᵢⱼxᵢxⱼ + Σ Jᵢᵢxᵢ", 665, 185, [:fontFamily = "Courier New", :fontSize = 9.5, :fontWeight = "bold", :fill = "#34D399"])
    svg.addTextCentered("Binary map: xᵢ = (sᵢ==1) ? 1:0", 665, 207, [:fontFamily = "'Segoe UI', sans-serif", :fontSize = 10, :fill = "#CBD5E1"])
    svg.addTextCentered("+ Constraint Penalty: λ·|nAct-K|²", 665, 227, [:fontFamily = "Courier New", :fontSize = 9.5, :fill = "#F472B6"])

    # Step 4: Center-Normalized Advantage
    svg.addRoundedRect(820, 140, 230, 110, 8, [:fill = boxFill, :stroke = boxStroke, :strokeWidth = 1, :filter = shadow])
    svg.addTextCentered("4. ADVANTAGE ENGINE", 935, 162, [:fontFamily = "'Segoe UI', sans-serif", :fontSize = 13, :fontWeight = "bold", :fill = "#A855F7"])
    svg.addTextCentered("adv = (E_local - avgE) / stdE", 935, 185, [:fontFamily = "Courier New", :fontSize = 10, :fontWeight = "bold", :fill = "#F59E0B"])
    svg.addTextCentered("Z-score prevents gradient explode", 935, 207, [:fontFamily = "'Segoe UI', sans-serif", :fontSize = 10, :fill = "#CBD5E1"])
    svg.addTextCentered("Keeps gradients in range [-4, +4]", 935, 227, [:fontFamily = "'Segoe UI', sans-serif", :fontSize = 9, :fill = "#E9D5FF"])

    # Step 5: Hybrid Constraint Injection
    svg.addRoundedRect(820, 310, 230, 100, 8, [:fill = boxFill, :stroke = "#F43F5E", :strokeWidth = 1.5, :filter = shadow])
    svg.addTextCentered("5. HYBRID GRADIENT", 935, 332, [:fontFamily = "'Segoe UI', sans-serif", :fontSize = 13, :fontWeight = "bold", :fill = "#F43F5E"])
    svg.addTextCentered("ga_re[i] += selectionError * 0.05", 935, 357, [:fontFamily = "Courier New", :fontSize = 10, :fontWeight = "bold", :fill = "#FFAEAE"])
    svg.addTextCentered("Direct visible bias SGD constraint", 935, 378, [:fontFamily = "'Segoe UI', sans-serif", :fontSize = 10, :fill = "#CBD5E1"])
    svg.addTextCentered("Ensures target K assets are selected", 935, 393, [:fontFamily = "'Segoe UI', sans-serif", :fontSize = 9, :fill = "#FBCFE8"])

    # Step 6: Zero-Copy Adam Weight Update
    svg.addRoundedRect(550, 310, 230, 100, 8, [:fill = boxFill, :stroke = boxStroke, :strokeWidth = 1, :filter = shadow])
    svg.addTextCentered("6. ZERO-COPY UPDATE", 665, 332, [:fontFamily = "'Segoe UI', sans-serif", :fontSize = 13, :fontWeight = "bold", :fill = "#10B981"])
    svg.addTextCentered("tensor_update_adam(W, gW, ...)", 665, 357, [:fontFamily = "Courier New", :fontSize = 10, :fontWeight = "bold", :fill = "#A7F3D0"])
    svg.addTextCentered("In-place memory update in C", 665, 378, [:fontFamily = "'Segoe UI', sans-serif", :fontSize = 10, :fill = "#CBD5E1"])
    svg.addTextCentered("No memory serialization copies", 665, 393, [:fontFamily = "'Segoe UI', sans-serif", :fontSize = 9, :fill = "#A7F3D0"])

    # Step 7: Convergence Evaluation
    svg.addRoundedRect(280, 310, 230, 100, 8, [:fill = boxFill, :stroke = boxStroke, :strokeWidth = 1, :filter = shadow])
    svg.addTextCentered("7. STABILITY CHECK", 395, 332, [:fontFamily = "'Segoe UI', sans-serif", :fontSize = 13, :fontWeight = "bold", :fill = "#E2E8F0"])
    svg.addTextCentered("Is energy minimized & stable?", 395, 357, [:fontFamily = "'Segoe UI', sans-serif", :fontSize = 10, :fill = "#CBD5E1"])
    svg.addTextCentered("Are exactly K assets hit?", 395, 378, [:fontFamily = "'Segoe UI', sans-serif", :fontSize = 10, :fill = "#CBD5E1"])
    svg.addTextCentered("Measures standard deviation σ", 395, 393, [:fontFamily = "'Segoe UI', sans-serif", :fontSize = 9, :fill = "#94A3B8"])

    # Step 8: Done / Output
    svg.addRoundedRect(50, 310, 180, 100, 8, [:fill = "#064E3B", :stroke = "#10B981", :strokeWidth = 1.5, :filter = shadow])
    svg.addTextCentered("8. OPTIMAL PORTFOLIO", 140, 338, [:fontFamily = "'Segoe UI', sans-serif", :fontSize = 13, :fontWeight = "bold", :fill = "#FFFFFF"])
    svg.addTextCentered("Stable Ground State", 140, 358, [:fontFamily = "'Segoe UI', sans-serif", :fontSize = 10, :fill = "#A7F3D0"])
    svg.addCheckmark(125, 368, 30, [:color = "#34D399"])

    # Connectors
    svg.addLine(230, 180, 280, 180, [:stroke = "#94A3B8", :strokeWidth = 2, :markerEnd = arrow])
    svg.addLine(510, 180, 550, 180, [:stroke = "#94A3B8", :strokeWidth = 2, :markerEnd = arrow])
    svg.addLine(780, 180, 820, 180, [:stroke = "#94A3B8", :strokeWidth = 2, :markerEnd = arrow])
    
    # Down
    svg.addLine(935, 250, 935, 310, [:stroke = "#94A3B8", :strokeWidth = 2, :markerEnd = arrow])
    
    # Left
    svg.addLine(820, 360, 780, 360, [:stroke = "#94A3B8", :strokeWidth = 2, :markerEnd = arrow])
    svg.addLine(550, 360, 510, 360, [:stroke = "#94A3B8", :strokeWidth = 2, :markerEnd = arrow])
    
    # Green arrow to output
    svg.addLine(280, 360, 230, 360, [:stroke = "#10B981", :strokeWidth = 2, :markerEnd = arrowGreen])
    
    # Not converged loop
    loopPath = svg.createPath()
    loopPath.moveTo(395, 410)
    loopPath.lineTo(395, 465)
    loopPath.lineTo(260, 465)
    loopPath.lineTo(260, 200)
    loopPath.lineTo(280, 200)
    loopPath.draw([:stroke = "#F43F5E", :strokeWidth = 2, :fill = "none", :markerEnd = arrowRed])
    svg.addTextCentered("No (Loop to next epoch)", 320, 480, [:fontFamily = "'Segoe UI', sans-serif", :fontSize = 11, :fill = "#F43F5E"])

    # Mathematical formulation notes card
    svg.addRoundedRect(50, 505, 1000, 125, 8, [:fill = "#1E293B", :stroke = "#334155", :strokeWidth = 1])
    svg.addText("Variational Monte Carlo Ground State Mathematical Formulations (v5.0):", 70, 532, [
        :fontFamily = "'Segoe UI', sans-serif", :fontSize = 12, :fontWeight = "bold", :fill = "#F8FAFC"
    ])
    svg.addText("1. Centered Wavefunction Gradient:  O_W(s) = ∂ ln ψ(s) / ∂ W_ij = s_i * tanh(θ_j)  where activations θ_j = b_j + Σ W_ij * s_i", 70, 555, [
        :fontFamily = "Courier New", :fontSize = 10, :fontWeight = "bold", :fill = "#F59E0B"
    ])
    svg.addText("2. Variational Force Vector:         ∇_W E = 2 * Real [ ⟨ E_local * O_W ⟩ - ⟨ E_local ⟩ * ⟨ O_W ⟩ ]", 70, 578, [
        :fontFamily = "Courier New", :fontSize = 10, :fontWeight = "bold", :fill = "#34D399"
    ])
    svg.addText("3. Constraint SGD Correction:        For visible bias: ga_re[i] += (AverageActive - TargetK) * CorrectionForce", 70, 601, [
        :fontFamily = "Courier New", :fontSize = 10, :fontWeight = "bold", :fill = "#38BDF8"
    ])

    svg.save("images/vmc_training_pipeline.svg")

# ==============================================================================
# 4. Hybrid Solver & Decision Pipeline (images/hybrid_optimization_pipeline.svg)
# ==============================================================================
func generateHybridOptimizationPipeline
    see "Generating: images/hybrid_optimization_pipeline.svg..." + nl
    
    width = 1100
    height = 680
    svg = new SVGWriter(width, height)
    svg.setViewBox(0, 0, width, height)
    
    # Background slate
    bgGrad = svg.createLinearGradient(0, 0, 100, 100, [[0, "#02050E"], [100, "#0C1222"]])
    svg.addRect(0, 0, width, height, [:fill = bgGrad])
    
    # Grid
    grid = svg.createGridPattern(35, 1, "#1C2436", bgGrad)
    svg.addRect(0, 0, width, height, [:fill = grid, :opacity = 0.25])
    
    shadow = svg.createShadowFilter(5, 5, 8, "#020617")
    
    # Header
    svg.addTextCentered("⚛️ HYBRID NEURAL-QUANTUM DISPATCHER & FLOW PIPELINE", width / 2, 45, [
        :fontFamily = "'Segoe UI', sans-serif", :fontSize = 24, :fontWeight = "bold", :fill = "#F8FAFC"
    ])
    svg.addTextCentered("End-to-End ingestion, AlQalam covariance formulation, and dynamic scale routing", width / 2, 75, [
        :fontFamily = "'Segoe UI', sans-serif", :fontSize = 14, :fill = "#94A3B8"
    ])

    arrow = svg.createArrowMarker(8, "#94A3B8")
    arrowGreen = svg.createArrowMarker(8, "#10B981")
    arrowBlue = svg.createArrowMarker(8, "#38BDF8")

    # Step 1: Input Data (Market prices / Physics params)
    svg.addRoundedRect(50, 240, 200, 95, 8, [:fill = "#1D4ED8", :stroke = "#3B82F6", :strokeWidth = 1.5, :filter = shadow])
    svg.addTextCentered("Market Data Ingestion", 150, 268, [:fontFamily = "'Segoe UI', sans-serif", :fontSize = 13, :fontWeight = "bold", :fill = "#FFFFFF"])
    svg.addTextCentered("Yahoo Finance / Portfolios", 150, 288, [:fontFamily = "'Segoe UI', sans-serif", :fontSize = 10, :fill = "#93C5FD"])
    svg.addTextCentered("Outputs: Assets Prices Array", 150, 305, [:fontFamily = "Courier New", :fontSize = 9, :fill = "#BFDBFE"])
    svg.addTextCentered("Data shape: [Time × N]", 150, 318, [:fontFamily = "Courier New", :fontSize = 9, :fill = "#93C5FD"])

    # Connect to Step 2
    svg.addLine(250, 287, 310, 287, [:stroke = "#94A3B8", :strokeWidth = 2, :markerEnd = arrow])

    # Step 2: AlQalam Preprocessor
    svg.addRoundedRect(310, 240, 190, 95, 8, [:fill = "#065F46", :stroke = "#10B981", :strokeWidth = 1.5, :filter = shadow])
    svg.addTextCentered("AlQalam Processing", 405, 268, [:fontFamily = "'Segoe UI', sans-serif", :fontSize = 13, :fontWeight = "bold", :fill = "#FFFFFF"])
    svg.addTextCentered("Computes Hamiltonian", 405, 288, [:fontFamily = "'Segoe UI', sans-serif", :fontSize = 10, :fill = "#A7F3D0"])
    svg.addTextCentered("Covariance J: [N × N] Matrix", 405, 305, [:fontFamily = "Courier New", :fontSize = 9, :fill = "#34D399"])
    svg.addTextCentered("Returns h:    [N × 1] Vector", 405, 318, [:fontFamily = "Courier New", :fontSize = 9, :fill = "#34D399"])

    # Connect to Step 3
    svg.addLine(500, 287, 540, 287, [:stroke = "#94A3B8", :strokeWidth = 2, :markerEnd = arrow])

    # Step 3: Decision Diamond (Scale Router)
    svg.addPolygon([
        [610, 212], # Top
        [680, 287], # Right
        [610, 362], # Bottom
        [540, 287]  # Left
    ], [:fill = "#334155", :stroke = "#64748B", :strokeWidth = 1.5, :filter = shadow])
    svg.addTextCentered("Scale check?", 610, 282, [:fontFamily = "'Segoe UI', sans-serif", :fontSize = 11, :fontWeight = "bold", :fill = "#FFFFFF"])
    svg.addTextCentered("Qubits (N)", 610, 297, [:fontFamily = "Courier New", :fontSize = 9, :fill = "#94A3B8"])

    # Dispatched Engines (Precision dimensions and limitations detail)
    # Engine A (Exact Simulation)
    svg.addRoundedRect(750, 110, 270, 90, 8, [:fill = "#7F1D1D", :stroke = "#F87171", :strokeWidth = 1.5, :filter = shadow])
    svg.addTextCentered("Statevector Engine (Exact QAOA)", 885, 135, [:fontFamily = "'Segoe UI', sans-serif", :fontSize = 13, :fontWeight = "bold", :fill = "#FCA5A5"])
    svg.addTextCentered("Mathematical Limit: N ≤ 25 Qubits", 885, 155, [:fontFamily = "'Segoe UI', sans-serif", :fontSize = 10, :fill = "#CBD5E1"])
    svg.addTextCentered("Memory representation: 2^N floats (128MB)", 885, 172, [:fontFamily = "Courier New", :fontSize = 9, :fill = "#F87171"])
    svg.addTextCentered("Complexity: O(2^N) Bitwise Gates", 885, 187, [:fontFamily = "'Segoe UI', sans-serif", :fontSize = 9, :fill = "#FCA5A5"])

    # Engine B (NQS RBM Engine)
    svg.addRoundedRect(750, 242, 270, 90, 8, [:fill = "#7C2D12", :stroke = "#FB923C", :strokeWidth = 1.5, :filter = shadow])
    svg.addTextCentered("Neural Quantum State (RBM)", 885, 267, [:fontFamily = "'Segoe UI', sans-serif", :fontSize = 13, :fontWeight = "bold", :fill = "#FFEDD5"])
    svg.addTextCentered("Optimization Scale: N ≤ 500 Variables", 885, 287, [:fontFamily = "'Segoe UI', sans-serif", :fontSize = 10, :fill = "#CBD5E1"])
    svg.addTextCentered("Wavefunction ansatz parameters: O(N×M)", 885, 304, [:fontFamily = "Courier New", :fontSize = 9, :fill = "#FDBA74"])
    svg.addTextCentered("Solves with Adam VMC via RingTensor", 885, 319, [:fontFamily = "'Segoe UI', sans-serif", :fontSize = 9, :fill = "#FFEDD5"])

    # Engine C (ANQS Transformer Engine)
    svg.addRoundedRect(750, 375, 270, 90, 8, [:fill = "#4C1D95", :stroke = "#C084FC", :strokeWidth = 1.5, :filter = shadow])
    svg.addTextCentered("Quantum Transformer (ANQS)", 885, 400, [:fontFamily = "'Segoe UI', sans-serif", :fontSize = 13, :fontWeight = "bold", :fill = "#F3E8FF"])
    svg.addTextCentered("Large-Scale Sim: N ≤ 1000+ Qubits", 885, 420, [:fontFamily = "'Segoe UI', sans-serif", :fontSize = 10, :fill = "#CBD5E1"])
    svg.addTextCentered("Exact sampling autoregression attention", 885, 437, [:fontFamily = "Courier New", :fontSize = 9, :fill = "#D8B4FE"])
    svg.addTextCentered("Updates via TDVP Natural Gradient", 885, 452, [:fontFamily = "'Segoe UI', sans-serif", :fontSize = 9, :fill = "#F3E8FF"])

    # Path from Router to A
    pA = svg.createPath()
    pA.moveTo(610, 212)
    pA.lineTo(610, 150)
    pA.lineTo(750, 150)
    pA.draw([:stroke = "#EF4444", :strokeWidth = 2, :fill = "none", :markerEnd = arrow])
    svg.addText("N ≤ 25", 620, 140, [:fontFamily = "'Segoe UI', sans-serif", :fontSize = 9.5, :fill = "#EF4444", :fontWeight = "bold"])

    # Path from Router to B
    svg.addLine(680, 287, 750, 287, [:stroke = "#F97316", :strokeWidth = 2, :markerEnd = arrow])
    svg.addText("N ≤ 500", 695, 275, [:fontFamily = "'Segoe UI', sans-serif", :fontSize = 9.5, :fill = "#F97316", :fontWeight = "bold"])

    # Path from Router to C
    pC = svg.createPath()
    pC.moveTo(610, 362)
    pC.lineTo(610, 420)
    pC.lineTo(750, 420)
    pC.draw([:stroke = "#8B5CF6", :strokeWidth = 2, :fill = "none", :markerEnd = arrow])
    svg.addText("N ≤ 1000+", 620, 435, [:fontFamily = "'Segoe UI', sans-serif", :fontSize = 9.5, :fill = "#8B5CF6", :fontWeight = "bold"])

    # Optimization Loops (Adam & TDVP)
    # Loop B: RBM -> RingTensor Adam -> RBM
    loopGradB = svg.createLinearGradient(0,0,100,0,[[0,"#7C2D12"],[100,"#1B2234"]])
    svg.addRoundedRect(440, 380, 180, 50, 6, [:fill = loopGradB, :stroke = "#FB923C", :strokeWidth = 1, :filter = shadow])
    svg.addTextCentered("RingTensor: Adam", 530, 405, [:fontFamily = "'Segoe UI', sans-serif", :fontSize = 11, :fontWeight = "bold", :fill = "#FDBA74"])
    
    # Path for B loop
    pLoopB = svg.createPath()
    pLoopB.moveTo(750, 300)
    pLoopB.lineTo(530, 300)
    pLoopB.lineTo(530, 380)
    pLoopB.draw([:stroke = "#FB923C", :strokeWidth = 1.5, :strokeDash = "2,2", :fill = "none", :markerEnd = arrow])
    
    pLoopB2 = svg.createPath()
    pLoopB2.moveTo(530, 430)
    pLoopB2.lineTo(530, 455)
    pLoopB2.lineTo(685, 455)
    pLoopB2.lineTo(685, 315)
    pLoopB2.lineTo(750, 315)
    pLoopB2.draw([:stroke = "#FB923C", :strokeWidth = 1.5, :fill = "none", :markerEnd = arrow])

    # Loop C: ANQS -> AlQalam CG -> ANQS
    loopGradC = svg.createLinearGradient(0,0,100,0,[[0,"#4C1D95"],[100,"#1B2234"]])
    svg.addRoundedRect(440, 495, 180, 50, 6, [:fill = loopGradC, :stroke = "#C084FC", :strokeWidth = 1, :filter = shadow])
    svg.addTextCentered("AlQalam: CG Solver (TDVP)", 530, 520, [:fontFamily = "'Segoe UI', sans-serif", :fontSize = 11, :fontWeight = "bold", :fill = "#E9D5FF"])
    
    pLoopC = svg.createPath()
    pLoopC.moveTo(750, 435)
    pLoopC.lineTo(630, 435)
    pLoopC.lineTo(630, 520)
    pLoopC.lineTo(620, 520)
    pLoopC.draw([:stroke = "#C084FC", :strokeWidth = 1.5, :strokeDash = "2,2", :fill = "none", :markerEnd = arrow])
    
    pLoopC2 = svg.createPath()
    pLoopC2.moveTo(440, 520)
    pLoopC2.lineTo(390, 520)
    pLoopC2.lineTo(390, 450)
    pLoopC2.lineTo(750, 450)
    pLoopC2.draw([:stroke = "#C084FC", :strokeWidth = 1.5, :fill = "none", :markerEnd = arrow])

    # Final Output Portfolio (Bottom Right)
    svg.addRoundedRect(800, 505, 200, 65, 8, [:fill = "#064E3B", :stroke = "#34D399", :strokeWidth = 2, :filter = shadow])
    svg.addTextCentered("OPTIMIZED PORTFOLIO", 900, 528, [:fontFamily = "'Segoe UI', sans-serif", :fontSize = 13, :fontWeight = "bold", :fill = "#A7F3D0"])
    svg.addTextCentered("K Optimal Assets Selected", 900, 548, [:fontFamily = "'Segoe UI', sans-serif", :fontSize = 10, :fill = "#FFFFFF"])
    
    # Combined Outputs
    svg.addLine(1020, 150, 1040, 150, [:stroke = "#10B981", :strokeWidth = 2])
    svg.addLine(1040, 150, 1040, 485, [:stroke = "#10B981", :strokeWidth = 2])
    svg.addLine(1040, 485, 900, 485, [:stroke = "#10B981", :strokeWidth = 2])
    svg.addLine(900, 485, 900, 505, [:stroke = "#10B981", :strokeWidth = 2, :markerEnd = arrowGreen])

    svg.addLine(1020, 287, 1030, 287, [:stroke = "#10B981", :strokeWidth = 2])
    svg.addLine(1030, 287, 1030, 485, [:stroke = "#10B981", :strokeWidth = 2])

    svg.addLine(1020, 420, 1025, 420, [:stroke = "#10B981", :strokeWidth = 2])
    svg.addLine(1025, 420, 1025, 485, [:stroke = "#10B981", :strokeWidth = 2])

    svg.save("images/hybrid_optimization_pipeline.svg")
