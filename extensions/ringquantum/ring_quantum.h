/*
** RingQuantum Extension - Header
** Purpose: Quantum Computing Simulation Engine (Standalone)
** Architecture: Statevector-based Engine with Zero-Copy support
*/

#ifndef RING_QUANTUM_H
#define RING_QUANTUM_H

#include "ring.h"
#include "opencl_stub.h"
#include <math.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>

#ifdef _OPENMP
#include <omp.h>
#endif

#ifdef _WIN32
#define RING_EXPORT __declspec(dllexport)
#else
#define RING_EXPORT extern
#endif

/*
** Quantum State Structure
** Data layout: Interleaved [Re0, Im0, Re1, Im1, ..., ReN, ImN]
*/
typedef struct {
    float *data;          // CPU Pointer (Mapped from GPU - float precision)
    size_t size;          // 2^n
    int nqubits;
    int is_owner;
    
    // --- OpenCL Specific ---
    cl_mem gpu_buffer;    // The actual memory on iGPU
    cl_mem res_buffer;    // Temporary buffer for ExpectZZ results
} quantum_t;

#define RING_VM_POINTER_QUANTUM "quantum_t"

/* Neural quantum states data structure*/
typedef struct {
    double *data;         // CPU/GPU Data
    size_t size;          // 2^n
    int nqubits;
    int nhidden;
    // --- NQS Specific ---
    double *W_real; double *W_imag;
    double *a_real; double *b_real;
    int8_t *spins;
    // --- Permanent Cache (for protection and speed) ---
    double *theta_re; double *theta_im;
    // --- OpenCL Buffers ---
    cl_mem cl_W_re; cl_mem cl_W_im;
    cl_mem cl_b_re; cl_mem cl_spins;
    cl_mem cl_h;    cl_mem cl_J;
    cl_mem cl_t_re; cl_mem cl_t_im;
    cl_mem cl_res;
    int cl_h_ready;
    // --- Cached Float Buffers (to avoid repeated malloc) ---
    float *h_f; float *J_f; float *s_f;
    float *w_re_f; float *w_im_f; float *b_re_f;
    float *t_re_f; float *t_im_f;
    float *gw_re_f; float *gw_im_f; float *gb_re_f;
    void *last_h_ptr; void *last_J_ptr;
} nqs_t;

/* Autoregressive Neural Quantum States (ANQS) data structure*/
typedef struct {
    double *W_q_re; double *W_q_im;
    double *W_k_re; double *W_k_im;
    double *W_v_re; double *W_v_im;
    double *W_out_re; double *W_out_im;
    double *Head_amp_W;
    double *Head_phase_W;
    
    int8_t *spins; // [batch_size * nqubits]
    
    int nqubits;
    int nheads;
    int ndim;
    int nlayers;
    int batch_size;
    
    // OpenCL Buffers
    cl_mem cl_W_q_re, cl_W_q_im;
    cl_mem cl_W_k_re, cl_W_k_im;
    cl_mem cl_W_v_re, cl_W_v_im;
    cl_mem cl_Head_amp_W, cl_Head_phase;
    cl_mem cl_logit_bias;
    cl_mem cl_spins; // Input / Samples
    cl_mem cl_probs; // Sample probabilities
    
    // Cached Float Memory for FP32 Zero-Copy
    float *wq_re_f; float *wq_im_f;
    float *wk_re_f; float *wk_im_f;
    float *wv_re_f; float *wv_im_f;
    float *hamp_f; float *hphase_f;
    float *spins_f;
    
    // Per-qubit learnable bias (self-optimized via SGD inside C kernel)
    double *logit_bias;
    double temperature;
} anqs_t;

/* 
** We use θ (Theta) as an intermediate matrix to store (Hidden Activations)
** θ_j = b_j + Σ W_ij * s_i
** This allows us to calculate the ratio in O(M) instead of O(N*M)
*/
typedef struct {
    double *theta_re; // Real part of θ
    double *theta_im; // Imaginary part of θ
} nqs_cache_t;


/* --- Complex Arithmetic Helpers (Inline for Performance) --- */
static inline void complex_mul(float re1, float im1, float re2, float im2, float *re_out, float *im_out) {
    *re_out = re1 * re2 - im1 * im2;
    *im_out = re1 * im2 + im1 * re2;
}

/* --- Library Entry Point --- */
RING_EXPORT void ringlib_init(RingState *pRingState);

/* --- Memory Lifecycle --- */
void ring_quantum_free(void *pState, void *pPointer);

/* --- Core Quantum Kernels --- */

quantum_t* quantum_create(int nqubits);

// Primitive Gates
void internal_gate_h(quantum_t *q, int target);
void internal_gate_x(quantum_t *q, int target);
void internal_gate_cnot(quantum_t *q, int control, int target);
void internal_gate_phase(quantum_t *q, int target, float phi);

// Advanced Gate: Custom Unitary (2x2 Matrix)
// matrix: [r00, i00, r01, i01, r10, i10, r11, i11]
void internal_gate_unitary(quantum_t *q, int target, float *matrix);

// Observability
double internal_get_probability(quantum_t *q, int target);
int internal_measure(quantum_t *q, int target);

// SWAP Gate
void internal_gate_swap(quantum_t *q, int q1, int q2);

// Toffoli Gate (CCNOT)
void internal_gate_toffoli(quantum_t *q, int q1, int q2, int target);

// Get Probabilities of all states
void internal_get_probabilities(quantum_t *q, List *pList);

// Multi-Controlled Unitary (MCU)
void internal_gate_mcu(quantum_t *q, int *aControls, int nControls, int target, float *m);

// State Fidelity
double internal_get_fidelity(quantum_t *q1, quantum_t *q2);

// Universal Single-Qubit Gate
void internal_gate_u(quantum_t *q, int target, float theta, float phi, float lambda);

// Expectation Values
double internal_get_expectation_x(quantum_t *q, int target);
double internal_get_expectation_y(quantum_t *q, int target);
double internal_get_expectation_z(quantum_t *q, int target);

// Neural Quantum States (RBM)
void nqs_compute_theta(nqs_t *nqs, nqs_cache_t *cache);

void internal_nqs_compute_gradients(nqs_t *nqs, double *gW_re, double *gW_im, double *gb_re, double *ga_re);

void internal_nqs_sample(nqs_t *nqs, nqs_cache_t *cache, int steps);

void ring_quantum_nqs_free(void *pState, void *pPointer);

void internal_nqs_get_spins(nqs_t *nqs, List *pList);

double internal_nqs_local_energy(nqs_t *nqs, double *h, double *J);

/* --- Ring API Wrappers --- */
RING_FUNC(ring_quantum_init);
RING_FUNC(ring_quantum_h);
RING_FUNC(ring_quantum_x);
RING_FUNC(ring_quantum_cnot);
RING_FUNC(ring_quantum_phase);
RING_FUNC(ring_quantum_unitary);
RING_FUNC(ring_quantum_get_probability);
RING_FUNC(ring_quantum_measure);
RING_FUNC(ring_quantum_get_state);
RING_FUNC(ring_quantum_free_mem);
RING_FUNC(ring_quantum_swap);
RING_FUNC(ring_quantum_toffoli);
RING_FUNC(ring_quantum_get_probabilities);
RING_FUNC(ring_quantum_get_cores);
RING_FUNC(ring_quantum_set_threads);
RING_FUNC(ring_quantum_controlled_unitary);
RING_FUNC(ring_quantum_ry);
RING_FUNC(ring_quantum_rx);
RING_FUNC(ring_quantum_rz);
RING_FUNC(ring_quantum_mcu);
RING_FUNC(ring_quantum_fidelity);
RING_FUNC(ring_quantum_u_gate);
RING_FUNC(ring_quantum_exp_x);
RING_FUNC(ring_quantum_exp_y);
RING_FUNC(ring_quantum_exp_z);
RING_FUNC(ring_quantum_exp_zz);

/* --- Neural Quantum States (RBM) --- */

// Create NQS object
RING_FUNC(ring_quantum_nqs_init);

// Bind NQS with RingTensor weights (Zero-Copy)
RING_FUNC(ring_quantum_nqs_bind);

// Sampling using Gibbs Sampling
RING_FUNC(ring_quantum_nqs_sample);

// Get current Spins state
RING_FUNC(ring_quantum_nqs_get_spins);

// Calculate Gradients for training
RING_FUNC(ring_quantum_nqs_grads);

// Calculate Local Energy (QUBO)
RING_FUNC(ring_quantum_nqs_energy);

// VMC Step (Single Call)
RING_FUNC(ring_quantum_nqs_vmc_step);

/* --- Autoregressive Transformer NQS (ANQS) --- */

RING_FUNC(ring_quantum_anqs_init);
RING_FUNC(ring_quantum_anqs_bind);
RING_FUNC(ring_quantum_anqs_sample);
RING_FUNC(ring_quantum_anqs_vmc_step);
RING_FUNC(ring_quantum_anqs_get_spins);
RING_FUNC(ring_quantum_anqs_apply_update);
RING_FUNC(ring_quantum_anqs_hebbian_backprop);
RING_FUNC(ring_quantum_anqs_batch_learn);
RING_FUNC(ring_quantum_anqs_inference);
RING_FUNC(ring_quantum_anqs_set_temp);
RING_FUNC(ring_quantum_anqs_save_bias);
RING_FUNC(ring_quantum_anqs_load_bias);

// Hardware Controls
RING_FUNC(ring_quantum_set_gpu_threshold);
RING_FUNC(ring_quantum_enable_gpu);

RING_FUNC(ring_quantum_anqs_jacobian);

RING_FUNC(ring_quantum_anqs_load_layer);

RING_FUNC(ring_quantum_fft);
RING_FUNC(ring_quantum_ifft);
RING_FUNC(ring_quantum_find_best);
RING_FUNC(ring_quantum_find_best_int8);
RING_FUNC(ring_quantum_quantize);

// Dimension Control
RING_FUNC(ring_quantum_set_dimension);
RING_FUNC(ring_quantum_fast_fingerprint);
RING_FUNC(ring_quantum_holographic_bind);
RING_FUNC(ring_quantum_batch_quantize);

#endif