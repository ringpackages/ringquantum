# 🏗️ RingQuantum — Architecture Documentation

## System Overview

RingQuantum is built as a **three-layer architecture** where each layer handles a specific concern:

```
┌──────────────────────────────────────────────────────────────┐
│                     Ring Application Layer                    │
│                                                              │
│  QuantumCircuit     NeuralQuantum     QuantumTransformer     │
│  (ringquantum.ring) (NeuralQuantum.ring) (quantum_transformer.ring)   │
│                                                              │
│  Pure Ring classes providing a clean, object-oriented API    │
├──────────────────────────────────────────────────────────────┤
│                      C Kernel Layer                          │
│                                                              │
│  ring_quantum.c (~95KB)                                      │
│  ┌────────────┬────────────────┬──────────────────────┐      │
│  │ Statevector│  NQS/RBM       │  Transformer/ANQS    │      │
│  │ Engine     │  Engine         │  Engine              │      │
│  │            │                 │                      │      │
│  │ • Gates    │ • MCMC Sampler  │ • Autoregressive     │      │
│  │ • Measure  │ • VMC Step      │   Sampling           │      │
│  │ • QFT      │ • Local Energy  │ • VMC Step           │      │
│  │ • ExpZ     │ • Gradients     │ • Jacobian           │      │
│  │            │ • Hybrid Grad   │ • Apply Update       │      │
│  └────────────┴────────────────┴──────────────────────┘      │
│                                                              │
│  OpenMP (CPU) │ OpenCL (GPU) │ XorShift (Thread-Safe RNG)    │
├──────────────────────────────────────────────────────────────┤
│                  External Dependencies                        │
│                                                              │
│  RingTensor (C)        │  AlQalam (C++)      │  RingML       │
│  • tensor_init         │  • QalamVector      │  • Adam class │
│  • tensor_update_adam  │  • QalamSolver (CG) │               │
│  • tensor_get_data_ptr │  • QalamChronos     │               │
│  • GPU acceleration    │  • Formula Engine   │               │
└──────────────────────────────────────────────────────────────┘
```

---

## Data Structures

### 1. `quantum_t` — Statevector State

```c
typedef struct {
    float *data;          // Interleaved [Re₀, Im₀, Re₁, Im₁, ...]
    size_t size;          // 2^n complex amplitudes
    int nqubits;
    int is_owner;         // Memory ownership flag
    cl_mem gpu_buffer;    // OpenCL GPU buffer
    cl_mem res_buffer;    // Temp buffer for ExpZ results
} quantum_t;
```

**Memory Layout:**
```
Index:  0    1    2    3    4    5    6    7    ...
Data:  Re₀  Im₀  Re₁  Im₁  Re₂  Im₂  Re₃  Im₃  ...
State: |000⟩     |001⟩     |010⟩     |011⟩
```

### 2. `nqs_t` — Neural Quantum State (RBM)

```c
typedef struct {
    int nqubits;          // N — number of visible neurons (assets)
    int nhidden;          // M — number of hidden neurons

    // Learnable Parameters (Zero-Copy with RingTensor)
    double *W_real;       // [N × M] Weight matrix (real)
    double *W_imag;       // [N × M] Weight matrix (imaginary)
    double *a_real;       // [N] Visible biases
    double *b_real;       // [M] Hidden biases

    // State
    int8_t *spins;        // [N] Current spin configuration {-1, +1}

    // Cache (Speed Optimization)
    double *theta_re;     // [M] Pre-computed activations (real)
    double *theta_im;     // [M] Pre-computed activations (imag)

    // OpenCL Buffers (GPU Acceleration)
    cl_mem cl_W_re, cl_W_im, cl_b_re, cl_spins;
    cl_mem cl_h, cl_J, cl_t_re, cl_t_im, cl_res;

    // Float Caches (FP32 GPU Transfer)
    float *h_f, *J_f, *s_f, *w_re_f, ...;
} nqs_t;
```

### 3. `anqs_t` — Autoregressive Transformer

```c
typedef struct {
    int nqubits;          // N — system size
    int nheads;           // Number of attention heads
    int ndim;             // D — attention dimension
    int batch_size;       // Parallel samples (e.g., 1024)

    // Complex Attention Weights (Zero-Copy with RingTensor)
    double *W_q_re, *W_q_im;     // [N × D] Query
    double *W_k_re, *W_k_im;     // [N × D] Key
    double *W_v_re, *W_v_im;     // [N × D] Value
    double *Head_amp_W;           // [D] Amplitude head
    double *Head_phase_W;         // [D] Phase head

    // Batch State
    int8_t *spins;                // [batch_size × N]

    // Per-Qubit Learnable Bias (Direct SGD)
    double *logit_bias;           // [N]

    // OpenCL & Float Caches
    cl_mem cl_W_q_re, cl_W_q_im, ...;
    float *wq_re_f, *wk_re_f, ...;
} anqs_t;
```

---

## Zero-Copy Memory Pipeline

The critical innovation is **shared pointer ownership** between Ring, C, and C++ layers:

```mermaid
sequenceDiagram
    participant Ring as Ring Script
    participant RT as RingTensor (C)
    participant RQ as RingQuantum (C)
    participant AQ as AlQalam (C++)

    Ring->>RT: W = new Tensor(N, M)
    Note over RT: malloc(N × M × sizeof(double))
    RT-->>Ring: W.pData (handle)

    Ring->>RT: ptr = tensor_get_data_ptr(W.pData)
    Note over RT: Returns raw double* pointer

    Ring->>RQ: quantum_nqs_bind(nqs, ptr, ...)
    Note over RQ: nqs->W_real = ptr (NO COPY)

    Note over RQ: Training modifies W_real[i] in-place

    Ring->>RT: tensor_update_adam(W.pData, grad, ...)
    Note over RT: Adam updates the SAME memory

    Ring->>AQ: oVec.flowFromPtr(ptr, size)
    Note over AQ: Reads from the SAME memory
```

**Result:** The weight matrix is allocated **once** by RingTensor and shared across all three engines with zero memory copies.

---

## VMC Training Pipeline (RBM)

```mermaid
flowchart TD
    A[Start VMC Step] --> B[Reset Gradients<br/>memset gW, gA, gB = 0]
    B --> C[Pass 1: Sampling Loop]
    C --> D{For each sample s}
    D --> E[MCMC Sample<br/>Metropolis-Hastings]
    E --> F[Store Configuration<br/>configs/s/ = spins]
    F --> G[Compute Energy<br/>E = xᵀJx + hᵀx]
    G --> H[Add Penalty<br/>E += λ·/nActive - K/²]
    H --> I[Store E in array]
    I --> D
    D -->|Done| J[Compute Statistics<br/>avgE, stdE]
    J --> K[Compute Selection Error<br/>error = avgActive - K]
    K --> L[Pass 2: Gradient Loop]
    L --> M{For each sample s}
    M --> N[Reload Configuration<br/>spins = configs/s/]
    N --> O[Compute Advantage<br/>adv = /E−avgE//stdE]
    O --> P[Accumulate Gradients<br/>gW += adv · sᵢ · tanh/θⱼ/<br/>gA += adv · sᵢ + error·0.05<br/>gB += adv · tanh/θⱼ/]
    P --> M
    M -->|Done| Q[Return Total Energy]
    Q --> R[Adam Update<br/>W, A, B via RingTensor]
```

---

## Transformer Sampling Pipeline

```mermaid
flowchart TD
    A[Start Autoregressive Sampling] --> B{For each qubit i = 0 to N-1}
    B --> C[Compute Attention]
    C --> D[Q = s₀..ᵢ₋₁ × W_q<br/>K = s₀..ᵢ₋₁ × W_k<br/>V = s₀..ᵢ₋₁ × W_v]
    D --> E[Apply Causal Mask<br/>Future qubits = −∞]
    E --> F[Softmax Attention<br/>A = softmax/QKᵀ/√d/]
    F --> G[Context = A × V]
    G --> H[Log-Amplitude = Head_amp · context<br/>Phase = Head_phase · context]
    H --> I[P/sᵢ=1/ = σ/2 × logAmp + bias/]
    I --> J[Sample sᵢ ~ Bernoulli/P/]
    J --> B
    B -->|Done| K[Return batch of 1024 samples]
```

---

## TDVP Natural Gradient Pipeline

```mermaid
flowchart LR
    A[Generate 1024<br/>Samples] --> B[Compute Energy<br/>Gradients<br/>∇E]
    B --> C[Build Jacobian<br/>O matrix<br/>batch × N_params]
    C --> D[Solve S·θ̇ = −½∇E<br/>via CG in AlQalam]
    D --> E[Apply Update<br/>θ += lr · θ̇<br/>via C kernel]
    E --> F[Next Time Step]
```

Where:
- **S** = Oᵀ·O / batch − ⟨O⟩ᵀ·⟨O⟩ (Quantum Fisher Information Matrix)
- **∇E** = Force vector (energy gradients)
- **θ̇** = Natural gradient (solution of the linear system)

---

## File Dependencies

```mermaid
graph TD
    subgraph Ring Layer
        A[ringquantum.ring]
        B[NeuralQuantum.ring]
        C[quantum_transformer.ring]
    end

    subgraph C Kernel
        D[ring_quantum.c]
        E[ring_quantum.h]
    end

    subgraph External
        F[ringtensor.ring / ring_tensor.c]
        G[alqalam.ring / alqalam.cpp]
        H[ringml.ring]
    end

    A --> D
    B --> A
    B --> F
    C --> A
    C --> F
    C --> G
    C --> H
    D --> E

    style A fill:#4CAF50,color:white
    style B fill:#4CAF50,color:white
    style C fill:#4CAF50,color:white
    style D fill:#2196F3,color:white
    style E fill:#2196F3,color:white
    style F fill:#FF9800,color:white
    style G fill:#FF9800,color:white
    style H fill:#FF9800,color:white
```

---

## OpenCL GPU Kernel Architecture

```
┌─────────────────────────────────────────┐
│           GPU Kernel Dispatch           │
├─────────────────────────────────────────┤
│                                         │
│  if (nqubits > threshold && gpu_ready)  │
│    → OpenCL Kernel (FP32)               │
│  else                                   │
│    → OpenMP Kernel (FP64)               │
│                                         │
├─────────────────────────────────────────┤
│  Available GPU Kernels:                 │
│                                         │
│  • gate_h_kernel     — Hadamard         │
│  • gate_x_kernel     — Pauli-X          │
│  • gate_cnot_kernel  — CNOT             │
│  • gate_phase_kernel — Phase rotation   │
│  • nqs_energy_kernel — Local energy     │
│  • anqs_sample_kernel — AR sampling     │
│                                         │
│  Memory: CL_MEM_ALLOC_HOST_PTR          │
│  Precision: FP32 (Intel Optimized)      │
│  Transfer: Zero-Copy (Mapped Buffers)   │
└─────────────────────────────────────────┘
```

---

## Thread Safety Model

| Component | Strategy | Details |
|:----------|:---------|:--------|
| Gate Operations | OpenMP `parallel for` | Safe — independent state indices |
| MCMC Sampling | Sequential per sample | Thread-safe within VMC step |
| Energy Calculation | OpenMP `reduction(+:energy)` | Atomic accumulation |
| Gradient Accumulation | OpenMP `reduction` | Per-sample independence |
| Random Numbers | Thread-local XorShift | No locks, no contention |
| Weight Updates | External (RingTensor Adam) | Sequential, after VMC step |

---

<div align="center">

**RingQuantum Architecture Documentation**  
Version 5.0 — April 2026

</div>
