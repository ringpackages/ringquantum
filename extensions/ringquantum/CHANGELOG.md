# 📝 Changelog

All notable changes to RingQuantum are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

---

## [5.0] — 2026-04-19

### Added
- **TDVP Dynamics Engine**: Time-Dependent Variational Principle for quantum natural gradient
  - `quantum_anqs_jacobian()` — Compute batch Jacobian matrix in C
  - `quantum_anqs_apply_update()` — Apply TDVP update vector to weights
  - `QuantumTransformer.UpdateTDVP()` — Full natural gradient step in Ring
  - Integration with AlQalam's `QalamSolver.solveCGTDVP()` for matrix-free CG
- **Adaptive Constraint Annealing**: Dynamic penalty scheduling for portfolio constraints
- **Per-Qubit Logit Bias**: Learnable bias in ANQS with capped SGD updates
- **Binary Portfolio Mapping**: Correct {0,1} energy calculation for financial optimization
- **Configuration-Locked Gradients**: Memory buffer to store spin configurations during VMC
- **Advantage Normalization**: Z-score normalization for REINFORCE stability
- **Hybrid Constraint Gradient**: Direct bias correction force for asset count convergence
- **Full Bias Optimization**: Adam updates for visible biases (a) and hidden biases (b) in RBM
- **Professional Documentation**: Complete README, Architecture Diagram, Technical Report

### Changed
- `internal_nqs_local_energy()` — Remapped from Ising {-1,+1} to binary portfolio {0,1}
- `ring_quantum_nqs_vmc_step()` — Two-pass architecture with config storage and Z-score normalization
- NeuralQuantum class — Full parameter optimization (W, a, b) with independent Adam states
- VMC step now accepts 11 parameters (added `ga_re` for visible bias gradients)
- Technical report expanded from 3 pages to comprehensive 10-section document

### Fixed
- Energy divergence in NQS/RBM training (root cause: Ising vs. portfolio mapping mismatch)
- Gradient explosion in large-qubit systems (root cause: missing normalization)
- Slow constraint convergence (root cause: biases not being optimized)
- Memory leak in VMC step (added `free(configs)` and `free(energies)`)

### Performance
- 500-qubit RBM converges to exact target (15 assets) in 310 epochs
- Energy trajectory stabilizes at -3.37 with zero oscillation in settling phase

---

## [4.0] — 2026-04-17

### Added
- **Autoregressive Quantum Transformer (ANQS)**
  - Causal masked attention with complex-valued weights
  - Exact sampling (no MCMC autocorrelation)
  - Batch parallel sampling (1024 samples)
  - `QuantumTransformer` class in Ring
- **Lock-Free XorShift RNG**: Thread-local random number generation
- **Smart GPU Dispatch**: `EnableQuantumGPU()`, `SetQuantumGPUThreshold()`
- `test_transformer_1000q.ring` — 1000-qubit benchmark

### Changed
- Shifted primary architecture from RBM to Transformer for 1000+ qubit systems
- Adam optimizer now uses RingML's `Adam` class for Transformer training

### Performance
- 1000-qubit system: energy collapsed from -1763 to -1210 in <10 epochs
- Eliminated multi-threading deadlock caused by MSVC `rand()` locks

---

## [3.0] — 2026-04-15

### Added
- **Neural Quantum States (NQS/RBM)** engine
  - Restricted Boltzmann Machine wavefunction ansatz
  - Metropolis-Hastings MCMC sampler with delta updates
  - Centered VMC gradient computation
  - `NeuralQuantum` class in Ring
- **Fused VMC Kernel**: `quantum_nqs_vmc_step()` — entire loop in C
- **Hardware-Aware Scheduling**: OpenMP (CPU) vs OpenCL (GPU) auto-selection
- **Persistent Memory Mirrors**: Zero reallocation during training
- **Dynamic Annealing**: Quadratic penalty constraints for portfolio size
- `NeuralQuantum.ring` — Professional RBM wrapper class
- `NeuralQuantum_1000Qubits.ring` — Large-scale demo

### Performance
- 100 qubits (10³⁰ states) in 1 minute 19 seconds
- 15x speedup from fused VMC kernel vs Ring-level loops

---

## [2.0] — 2026-04-12

### Added
- **OpenCL GPU Acceleration**
  - FP32 Turbo Mode for Intel integrated GPUs
  - Zero-Copy memory via `clEnqueueMapBuffer`
  - GPU kernels for H, X, CNOT, Phase gates
  - NQS energy calculation on GPU
- `quantum_enable_gpu()` — Runtime GPU toggle
- `quantum_set_gpu_threshold()` — Minimum size for GPU offloading

### Performance
- 25-qubit QAOA loop: 25 minutes → 18 minutes (GPU accelerated)
- GPU utilization: 99% during gate operations

---

## [1.0] — 2026-04-10

### Added
- **Statevector Simulator** — exact quantum circuit simulation
  - Interleaved complex memory layout `[Re, Im, Re, Im, ...]`
  - OpenMP parallelized gate kernels
  - Bitwise index manipulation for in-place operations
- **Complete Gate Set**: H, X, Y, Z, CNOT, Swap, Toffoli, Phase, Rx, Ry, Rz, U-Gate
- **Multi-Controlled Gates**: MCX, MCU for arbitrary control qubits
- **Measurement**: Single-qubit collapse, probabilities, full state readout
- **Expectation Values**: ⟨σₓ⟩, ⟨σᵧ⟩, ⟨σᵤ⟩ for any qubit
- **State Fidelity**: Compare two quantum states
- **Algorithms**: QFT, IQFT, Controlled-Z
- **`QuantumCircuit` class**: Clean Ring interface with `RevealState()` visualization
- `ringquantum.ring` — Extension loader with helper functions

### Performance
- 25 qubits: 33.5 million states in ~35 seconds per gate cycle
- Hardware: Intel i3-5005U, 6GB RAM

---

<div align="center">

**RingQuantum Changelog**  
Maintained by Azzeddine Remmal

</div>
