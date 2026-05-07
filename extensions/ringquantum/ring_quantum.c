#include "ring_quantum.h"
#include <stdio.h>
#include <time.h>
#include <complex.h>

/* ==================================================================== */
/* --- 1. OpenCL Infrastructure (GPU Acceleration) -------------------- */
/* ==================================================================== */

#define USE_OPENCL 1 

#ifdef USE_OPENCL

static cl_context       clContext = NULL;
static cl_command_queue clQueue   = NULL;
static cl_kernel        clHadamardKernel = NULL;
static cl_kernel        clRZKernel       = NULL;
static cl_kernel        clCNOTKernel     = NULL;
static cl_kernel        clExpectZZKernel = NULL;
static cl_kernel        clXKernel        = NULL;
static cl_kernel        clUnitaryKernel  = NULL;
static cl_kernel        clProbKernel     = NULL;
static cl_kernel        clCollapseKernel = NULL;
static cl_kernel        clSwapKernel     = NULL;
static cl_kernel        clToffoliKernel  = NULL;
static cl_kernel        clMCUKernel      = NULL;
static cl_kernel        clRXKernel       = NULL;
static cl_kernel        clRYKernel       = NULL;
static cl_kernel        clExpectZKernel  = NULL;

/* --- NQS Specific Kernels --- */
static cl_kernel        clNQSEnergyKernel = NULL;
static cl_kernel        clNQSThetaKernel  = NULL;
static cl_kernel        clNQSGradsKernel  = NULL;

static int              gpu_ready = 0;
static int              gpu_threshold = 15;
static int              user_gpu_enabled = 0; // Require explicit enable from Ring
static int              current_dimension = 1024;
/* OpenCL Kernels Source - Optimized for Zero-Copy on Integrated GPUs */
const char *quantum_cl_source = 
"typedef float2 complex;\n"
"__kernel void cl_hadamard(__global complex* state, int target) {\n"
"    size_t k = get_global_id(0);\n"
"    size_t step = (1LL << target);\n"
"    if (!(k & step)) {\n"
"        size_t idx0 = k;\n"
"        size_t idx1 = k ^ step;\n"
"        complex v0 = state[idx0];\n"
"        complex v1 = state[idx1];\n"
"        float inv = 0.70710678f;\n"
"        state[idx0] = (complex)((v0.x + v1.x) * inv, (v0.y + v1.y) * inv);\n"
"        state[idx1] = (complex)((v0.x - v1.x) * inv, (v0.y - v1.y) * inv);\n"
"    }\n"
"}\n"
"__kernel void cl_rz(__global complex* state, int target, float theta) {\n"
"    size_t k = get_global_id(0);\n"
"    if (k & (1LL << target)) {\n"
"        complex v = state[k];\n"
"        float c = cos(theta); float s = sin(theta);\n"
"        state[k] = (complex)(v.x * c - v.y * s, v.x * s + v.y * c);\n"
"    }\n"
"}\n"
"__kernel void cl_cnot(__global complex* state, int ctrl, int target) {\n"
"    size_t k = get_global_id(0);\n"
"    size_t c_bit = (1LL << ctrl); size_t t_bit = (1LL << target);\n"
"    if ((k & c_bit) && !(k & t_bit)) {\n"
"        size_t idx1 = k ^ t_bit;\n"
"        complex tmp = state[k];\n"
"        state[k] = state[idx1];\n"
"        state[idx1] = tmp;\n"
"    }\n"
"}\n"
"__kernel void cl_expect_zz(__global const complex* state, int qi, int qj, __global float* results) {\n"
"    size_t k = get_global_id(0);\n"
"    complex amp = state[k];\n"
"    float p = amp.x*amp.x + amp.y*amp.y;\n"
"    int bi = (k >> qi) & 1; int bj = (k >> qj) & 1;\n"
"    results[k] = (bi == bj) ? p : -p;\n"
"}\n"
"__kernel void cl_x(__global complex* state, int target) {\n"
"    size_t k = get_global_id(0);\n"
"    size_t step = (1LL << target);\n"
"    if (!(k & step)) {\n"
"        size_t idx1 = k ^ step;\n"
"        complex tmp = state[k];\n"
"        state[k] = state[idx1];\n"
"        state[idx1] = tmp;\n"
"    }\n"
"}\n"
"__kernel void cl_unitary(__global complex* state, int target, float8 m) {\n"
"    size_t k = get_global_id(0);\n"
"    size_t step = (1LL << target);\n"
"    if (!(k & step)) {\n"
"        size_t idx0 = k;\n"
"        size_t idx1 = k ^ step;\n"
"        complex v0 = state[idx0];\n"
"        complex v1 = state[idx1];\n"
"        state[idx0] = (complex)(m.s0*v0.x - m.s1*v0.y + m.s2*v1.x - m.s3*v1.y, \n"
"                               m.s0*v0.y + m.s1*v0.x + m.s2*v1.y + m.s3*v1.x);\n"
"        state[idx1] = (complex)(m.s4*v0.x - m.s5*v0.y + m.s6*v1.x - m.s7*v1.y, \n"
"                               m.s4*v0.y + m.s5*v0.x + m.s6*v1.y + m.s7*v1.x);\n"
"    }\n"
"}\n"
"__kernel void cl_prob_elements(__global const complex* state, int target, __global float* res) {\n"
"    size_t k = get_global_id(0);\n"
"    if (k & (1LL << target)) {\n"
"        complex v = state[k];\n"
"        res[k] = v.x*v.x + v.y*v.y;\n"
"    } else { res[k] = 0.0f; }\n"
"}\n"
"__kernel void cl_collapse(__global complex* state, int target, int outcome, float norm) {\n"
"    size_t k = get_global_id(0);\n"
"    int bit = (k >> target) & 1;\n"
"    if (bit == outcome) {\n"
"        state[k].x *= norm; state[k].y *= norm;\n"
"    } else {\n"
"        state[k] = (complex)(0.0f, 0.0f);\n"
"    }\n"
"}\n"
"__kernel void cl_swap(__global complex* state, int q1, int q2) {\n"
"    size_t k = get_global_id(0);\n"
"    size_t b1 = (1LL << q1); size_t b2 = (1LL << q2);\n"
"    if (((k & b1) != 0) != ((k & b2) != 0)) {\n"
"        size_t k2 = k ^ b1 ^ b2;\n"
"        if (k < k2) {\n"
"            complex tmp = state[k];\n"
"            state[k] = state[k2];\n"
"            state[k2] = tmp;\n"
"        }\n"
"    }\n"
"}\n"
"__kernel void cl_toffoli(__global complex* state, int q1, int q2, int target) {\n"
"    size_t k = get_global_id(0);\n"
"    size_t mask = (1LL << q1) | (1LL << q2);\n"
"    size_t t_bit = (1LL << target);\n"
"    if ((k & mask) == mask && !(k & t_bit)) {\n"
"        size_t idx1 = k ^ t_bit;\n"
"        complex tmp = state[k];\n"
"        state[k] = state[idx1];\n"
"        state[idx1] = tmp;\n"
"    }\n"
"}\n"
"__kernel void cl_mcu(__global complex* state, unsigned long mask, int target, float8 m) {\n"
"    size_t k = get_global_id(0);\n"
"    size_t t_bit = (1LL << target);\n"
"    if ((k & mask) == mask && !(k & t_bit)) {\n"
"        size_t idx0 = k;\n"
"        size_t idx1 = k ^ t_bit;\n"
"        complex v0 = state[idx0];\n"
"        complex v1 = state[idx1];\n"
"        state[idx0] = (complex)(m.s0*v0.x - m.s1*v0.y + m.s2*v1.x - m.s3*v1.y, \n"
"                               m.s0*v0.y + m.s1*v0.x + m.s2*v1.y + m.s3*v1.x);\n"
"        state[idx1] = (complex)(m.s4*v0.x - m.s5*v0.y + m.s6*v1.x - m.s7*v1.y, \n"
"                               m.s4*v0.y + m.s5*v0.x + m.s6*v1.y + m.s7*v1.x);\n"
"    }\n"
"}\n"
"__kernel void cl_rx(__global complex* state, int target, float theta) {\n"
"    size_t k = get_global_id(0); size_t step = (1LL << target);\n"
"    if (!(k & step)) {\n"
"        size_t idx0 = k; size_t idx1 = k ^ step;\n"
"        complex v0 = state[idx0]; complex v1 = state[idx1];\n"
"        float c = cos(theta/2.0f); float s = sin(theta/2.0f);\n"
"        state[idx0] = (complex)(c*v0.x + s*v1.y, c*v0.y - s*v1.x);\n"
"        state[idx1] = (complex)(c*v1.x + s*v0.y, c*v1.y - s*v0.x);\n"
"    }\n"
"}\n"
"__kernel void cl_ry(__global complex* state, int target, float theta) {\n"
"    size_t k = get_global_id(0); size_t step = (1LL << target);\n"
"    if (!(k & step)) {\n"
"        size_t idx0 = k; size_t idx1 = k ^ step;\n"
"        complex v0 = state[idx0]; complex v1 = state[idx1];\n"
"        float c = cos(theta/2.0f); float s = sin(theta/2.0f);\n"
"        state[idx0] = (complex)(c*v0.x - s*v1.x, c*v0.y - s*v1.y);\n"
"        state[idx1] = (complex)(s*v0.x + c*v1.x, s*v0.y + c*v1.y);\n"
"    }\n"
"}\n"
"__kernel void cl_expect_z(__global const complex* state, int target, __global float* results) {\n"
"    size_t k = get_global_id(0);\n"
"    complex amp = state[k];\n"
"    float p = amp.x*amp.x + amp.y*amp.y;\n"
"    results[k] = ((k >> target) & 1) ? -p : p;\n"
"}\n"
"__kernel void cl_rz_real(__global complex* state, int target, float theta) {\n"
"    size_t k = get_global_id(0); size_t step = (1LL << target);\n"
"    float c = cos(theta/2.0f); float s = sin(theta/2.0f);\n"
"    if (!(k & step)) {\n"
"        complex v = state[k];\n"
"        state[k] = (complex)(v.x*c + v.y*s, v.y*c - v.x*s);\n"
"    } else {\n"
"        complex v = state[k];\n"
"        state[k] = (complex)(v.x*c - v.y*s, v.y*c + v.x*s);\n"
"    }\n"
"}\n"
"\n"
"/* --- NQS GPU Kernels --- */\n"
"__kernel void nqs_energy(__global const float* h, __global const float* J, __global const float* s, int n, __global float* res) {\n"
"    size_t i = get_global_id(0);\n"
"    if (i >= n) return;\n"
"    float si = s[i]; \n"
"    float eng = h[i] * si;\n"
"    for (int j = i + 1; j < n; j++) {\n"
"        eng += J[i * n + j] * si * s[j];\n"
"    }\n"
"    res[i] = eng;\n"
"}\n"
"\n"
"__kernel void nqs_compute_theta(__global const float* s, __global const float* W_re, __global const float* W_im, \n"
"                               __global const float* b_re, int n, int m, __global float* t_re, __global float* t_im) {\n"
"    size_t j = get_global_id(0);\n"
"    if (j >= m) return;\n"
"    float sum_re = b_re[j]; float sum_im = 0.0f;\n"
"    for (int i = 0; i < n; i++) {\n"
"        float si = s[i];\n"
"        sum_re += W_re[i * m + j] * si;\n"
"        sum_im += W_im[i * m + j] * si;\n"
"    }\n"
"    t_re[j] = sum_re; t_im[j] = sum_im;\n"
"}\n"
"\n"
"__kernel void nqs_grads(__global const float* s, __global const float* t_re, __global const float* t_im, \n"
"                        int n, int m, __global float* gW_re, __global float* gW_im, __global float* gb_re) {\n"
"    size_t j = get_global_id(0);\n"
"    if (j >= m) return;\n"
"    float x = t_re[j]; float y = t_im[j];\n"
"    float denom = cosh(2.0f * x) + cos(2.0f * y);\n"
"    if (denom < 1e-10f) denom = 1e-10f;\n"
"    float tr = sinh(2.0f * x) / denom;\n"
"    float ti = sin(2.0f * y) / denom;\n"
"    gb_re[j] = tr;\n"
"    for (int i = 0; i < n; i++) {\n"
"        float si = s[i];\n"
"        gW_re[i * m + j] = si * tr;\n"
"        gW_im[i * m + j] = si * ti;\n"
"    }\n"
"}\n";

const char *anqs_cl_source = 
"/* --- ANQS Transformer GPU Kernels --- */\n"
"__kernel void anqs_masked_attention(__global const float* Q, __global const float* K, __global const float* V, \n"
"                                   __global float* Out, int batch_size, int nqubits, int ndim) {\n"
"    int b = get_global_id(0);\n"
"    int q_idx = get_global_id(1);\n"
"    if (b >= batch_size || q_idx >= nqubits) return;\n"
"    float max_score = -1e9f;\n"
"    float scores[2048];\n"
"    for(int k_idx = 0; k_idx <= q_idx; k_idx++) {\n"
"        float s = 0;\n"
"        for(int d=0; d<ndim; d++) s += Q[(b*nqubits + q_idx)*ndim + d] * K[(b*nqubits + k_idx)*ndim + d];\n"
"        s /= sqrt((float)ndim);\n"
"        scores[k_idx] = s;\n"
"        if (s > max_score) max_score = s;\n"
"    }\n"
"    float sum_exp = 0;\n"
"    for(int k_idx = 0; k_idx <= q_idx; k_idx++) {\n"
"        scores[k_idx] = exp(scores[k_idx] - max_score);\n"
"        sum_exp += scores[k_idx];\n"
"    }\n"
"    for(int k_idx = 0; k_idx <= q_idx; k_idx++) scores[k_idx] /= sum_exp;\n"
"    for(int d=0; d<ndim; d++) {\n"
"        float out_val = 0;\n"
"        for(int k_idx = 0; k_idx <= q_idx; k_idx++) {\n"
"            out_val += scores[k_idx] * V[(b*nqubits + k_idx)*ndim + d];\n"
"        }\n"
"        Out[(b*nqubits + q_idx)*ndim + d] = out_val;\n"
"    }\n"
"}\n"
"__kernel void anqs_complex_head(__global const float* Out, __global const float* W_amp, __global const float* W_phase, \n"
"                                __global float* Prob, __global float* Phase, int batch_size, int nqubits, int ndim) {\n"
"    int b = get_global_id(0);\n"
"    int q_idx = get_global_id(1);\n"
"    if (b >= batch_size || q_idx >= nqubits) return;\n"
"    float amp = 0; float phase = 0;\n"
"    for(int d=0; d<ndim; d++) {\n"
"        amp += Out[(b*nqubits + q_idx)*ndim + d] * W_amp[d];\n"
"        phase += Out[(b*nqubits + q_idx)*ndim + d] * W_phase[d];\n"
"    }\n"
"    Prob[(b*nqubits + q_idx)] = 1.0f / (1.0f + exp(-amp));\n"
"    Phase[(b*nqubits + q_idx)] = phase;\n"
"}\n";

static cl_kernel clANQSAttentionKernel = NULL;
static cl_kernel clANQSHeadKernel = NULL;

void init_opencl() {
    cl_platform_id platform_id = NULL;
    cl_device_id device_id = NULL;
    cl_uint ret_num_devices, ret_num_platforms;
    cl_int ret;

    ret = clGetPlatformIDs(1, &platform_id, &ret_num_platforms);
    if (ret != CL_SUCCESS) return;
    ret = clGetDeviceIDs(platform_id, CL_DEVICE_TYPE_GPU, 1, &device_id, &ret_num_devices);

    if (ret != CL_SUCCESS) {
        printf("[RingQuantum] GPU Busy or Not Found! Error: %d\n", ret); 
        return; 
    }

    clContext = clCreateContext(NULL, 1, &device_id, NULL, NULL, &ret);
    clQueue = clCreateCommandQueue(clContext, device_id, 0, &ret);

    const char *sources[] = {quantum_cl_source, anqs_cl_source};
    size_t source_lens[] = {strlen(quantum_cl_source), strlen(anqs_cl_source)};
    cl_program program = clCreateProgramWithSource(clContext, 2, sources, source_lens, &ret);
    ret = clBuildProgram(program, 1, &device_id, NULL, NULL, NULL);
    if (ret != CL_SUCCESS) {
        char build_log[8192];
        clGetProgramBuildInfo(program, device_id, CL_PROGRAM_BUILD_LOG, sizeof(build_log), build_log, NULL);
        printf("[RingQuantum] GPU Build Error: %d\nLog:\n%s\n", ret, build_log);
        return;
    }

    clHadamardKernel = clCreateKernel(program, "cl_hadamard", &ret);
    clRZKernel       = clCreateKernel(program, "cl_rz", &ret);
    clCNOTKernel     = clCreateKernel(program, "cl_cnot", &ret);
    clExpectZZKernel = clCreateKernel(program, "cl_expect_zz", &ret);
    clXKernel       = clCreateKernel(program, "cl_x", &ret);
    clUnitaryKernel = clCreateKernel(program, "cl_unitary", &ret);
    clProbKernel     = clCreateKernel(program, "cl_prob_elements", &ret);
    clCollapseKernel = clCreateKernel(program, "cl_collapse", &ret);
    clSwapKernel     = clCreateKernel(program, "cl_swap", &ret);
    clToffoliKernel  = clCreateKernel(program, "cl_toffoli", &ret);
    clMCUKernel      = clCreateKernel(program, "cl_mcu", &ret);
    clRXKernel       = clCreateKernel(program, "cl_rx", &ret);
    clRYKernel       = clCreateKernel(program, "cl_ry", &ret);
    clExpectZKernel  = clCreateKernel(program, "cl_expect_z", &ret);
    
    clNQSEnergyKernel = clCreateKernel(program, "nqs_energy", &ret);
    clNQSThetaKernel  = clCreateKernel(program, "nqs_compute_theta", &ret);
    clNQSGradsKernel  = clCreateKernel(program, "nqs_grads", &ret);
    
    clANQSAttentionKernel  = clCreateKernel(program, "anqs_masked_attention", &ret);
    clANQSHeadKernel  = clCreateKernel(program, "anqs_complex_head", &ret);

    gpu_ready = 1;
    printf("[RingQuantum] GPU FP32 Turbo Ready (Intel Optimized)\n");
}
#endif

/* ==================================================================== */
/* --- 2. Spectral Analysis Core (Sovereign FFT) ---------------------- */
/* ==================================================================== */

void internal_fft(double *re, double *im, int n, int step) {
    if (step < n) {
        internal_fft(re, im, n, step * 2);
        internal_fft(re + step, im + step, n, step * 2);
        for (int i = 0; i < n; i += 2 * step) {
            double angle = -3.14159265358979323846 * i / n;
            double twiddle_re = cos(angle);
            double twiddle_im = sin(angle);
            
            double t_re = twiddle_re * re[i + step] - twiddle_im * im[i + step];
            double t_im = twiddle_re * im[i + step] + twiddle_im * re[i + step];
            
            re[i / 2] = re[i] + t_re;
            im[i / 2] = im[i] + t_im;
            re[(i + n) / 2] = re[i] - t_re;
            im[(i + n) / 2] = im[i] - t_im;
        }
    }
}

RING_FUNC(ring_quantum_fft) {
    if (RING_API_PARACOUNT != 2) return;
    double *real_in = (double*)(size_t)RING_API_GETNUMBER(1);
    double *comp_out = (double*)(size_t)RING_API_GETNUMBER(2);
    int n = current_dimension;
    
    double *re = (double*) calloc(current_dimension, sizeof(double));
double *im = (double*) calloc(current_dimension, sizeof(double));
    for (int i = 0; i < n; i++) { 
        if (i < 576) re[i] = real_in[i]; else re[i] = 0.0;
        im[i] = 0.0; 
    }
    
    internal_fft(re, im, n, 1);
    
    for (int i = 0; i < n; i++) {
        comp_out[i*2]   = re[i];
        comp_out[i*2+1] = im[i];
    }
    free(re);
    free(im);
}

RING_FUNC(ring_quantum_ifft) {
    if (RING_API_PARACOUNT != 2) return;
    double *complex_in = (double*)(size_t)RING_API_GETNUMBER(1);
    double *real_out = (double*)(size_t)RING_API_GETNUMBER(2);
    int n = current_dimension;
    
    double *re = (double*) calloc(current_dimension, sizeof(double));
    double *im = (double*) calloc(current_dimension, sizeof(double));
    for (int i = 0; i < n; i++) { 
        re[i] = complex_in[i*2]; 
        im[i] = -complex_in[i*2+1]; // Conjugate
    }
    
    internal_fft(re, im, n, 1);
    
    for (int i = 0; i < 576; i++) {
        real_out[i] = re[i] / (double)n; 
    }
    free(re);
    free(im);
}

/* ==================================================================== */
/* --- 3. Traditional Quantum Gates (State Vector Logic) -------------- */
/* ==================================================================== */

quantum_t* quantum_create(int nqubits) {
    size_t num_elements = ((size_t)1 << nqubits);
    quantum_t *q = (quantum_t*)malloc(sizeof(quantum_t));
    if (!q) return NULL;

    q->nqubits = nqubits;
    q->size = num_elements;
    q->is_owner = 1;
    q->gpu_buffer = NULL; q->res_buffer = NULL;

    size_t bytes = num_elements * 2 * sizeof(float);
    cl_int ret;

#ifdef USE_OPENCL
    if (gpu_ready && user_gpu_enabled && nqubits >= gpu_threshold) {
        q->gpu_buffer = clCreateBuffer(clContext, CL_MEM_READ_WRITE | CL_MEM_ALLOC_HOST_PTR, bytes, NULL, &ret);
        q->res_buffer = clCreateBuffer(clContext, CL_MEM_READ_WRITE | CL_MEM_ALLOC_HOST_PTR, num_elements * sizeof(float), NULL, &ret);
        if (q->gpu_buffer) {
            q->data = (float*)clEnqueueMapBuffer(clQueue, q->gpu_buffer, CL_TRUE, CL_MAP_READ | CL_MAP_WRITE, 0, bytes, 0, NULL, NULL, &ret);
            memset(q->data, 0, bytes); q->data[0] = 1.0f;
            return q;
        }
    }
#endif

    // Fallback to CPU Aligned Memory
#ifdef _WIN32
    q->data = (float*)_aligned_malloc(bytes, 64);
#else
    posix_memalign((void**)&q->data, 64, bytes);
#endif
    memset(q->data, 0, bytes); q->data[0] = 1.0f;
    return q;
}

void ring_quantum_free(void *pState, void *pPointer) {
    quantum_t *q = (quantum_t *)pPointer;
    if (!q) return;
    if (q->is_owner && q->data) {
#ifdef USE_OPENCL
        if (q->gpu_buffer) {
            clEnqueueUnmapMemObject(clQueue, q->gpu_buffer, q->data, 0, NULL, NULL);
            clReleaseMemObject(q->gpu_buffer);
            if (q->res_buffer) clReleaseMemObject(q->res_buffer);
        } else {
#endif
#ifdef _WIN32
            _aligned_free(q->data);
#else
            free(q->data);
#endif
#ifdef USE_OPENCL
        }
#endif
    }
    free(q);
}

/* ==================================================================== */
/* --- 3. Core Gate Kernels (GPU + CPU Fallback) ---------------------- */
/* ==================================================================== */

void internal_gate_h(quantum_t *q, int target) {
    if (target < 0 || target >= q->nqubits) return;
#ifdef USE_OPENCL
    if (gpu_ready && q->gpu_buffer) {
        clEnqueueUnmapMemObject(clQueue, q->gpu_buffer, q->data, 0, NULL, NULL);
        clSetKernelArg(clHadamardKernel, 0, sizeof(cl_mem), &q->gpu_buffer);
        clSetKernelArg(clHadamardKernel, 1, sizeof(int), &target);
        size_t g_size = q->size;
        clEnqueueNDRangeKernel(clQueue, clHadamardKernel, 1, NULL, &g_size, NULL, 0, NULL, NULL);
        q->data = (float*)clEnqueueMapBuffer(clQueue, q->gpu_buffer, CL_TRUE, CL_MAP_READ | CL_MAP_WRITE, 0, q->size*8, 0, NULL, NULL, NULL);
        return;
    }
#endif
    // CPU OpenMP+AVX2 Implementation
    size_t step = ((size_t)1 << target);
    float inv = 0.70710678f;
    int i, j;
    #pragma omp parallel for private(j) schedule(static)
    for (i = 0; i < (int)q->size; i += (int)(step << 1)) {
        for (j = i; j < i + (int)step; j++) {
            size_t idx0 = (size_t)j * 2, idx1 = (j + step) * 2;
            float r0 = q->data[idx0], i0 = q->data[idx0+1], r1 = q->data[idx1], i1 = q->data[idx1+1];
            q->data[idx0] = (r0 + r1) * inv; q->data[idx0+1] = (i0 + i1) * inv;
            q->data[idx1] = (r0 - r1) * inv; q->data[idx1+1] = (i0 - i1) * inv;
        }
    }
}

void internal_gate_cnot(quantum_t *q, int ctrl, int target) {
#ifdef USE_OPENCL
    if (gpu_ready && q->gpu_buffer) {
        clEnqueueUnmapMemObject(clQueue, q->gpu_buffer, q->data, 0, NULL, NULL);
        clSetKernelArg(clCNOTKernel, 0, sizeof(cl_mem), &q->gpu_buffer);
        clSetKernelArg(clCNOTKernel, 1, sizeof(int), &ctrl);
        clSetKernelArg(clCNOTKernel, 2, sizeof(int), &target);
        size_t g_size = q->size;
        clEnqueueNDRangeKernel(clQueue, clCNOTKernel, 1, NULL, &g_size, NULL, 0, NULL, NULL);
        q->data = (float*)clEnqueueMapBuffer(clQueue, q->gpu_buffer, CL_TRUE, CL_MAP_READ | CL_MAP_WRITE, 0, q->size*8, 0, NULL, NULL, NULL);
        return;
    }
#endif
    size_t c_bit = ((size_t)1 << ctrl), t_bit = ((size_t)1 << target);
    int i;
    #pragma omp parallel for schedule(static)
    for (i = 0; i < (int)q->size; i++) {
        if (((size_t)i & c_bit) && !((size_t)i & t_bit)) {
            size_t idx0 = (size_t)i * 2, idx1 = ((size_t)i ^ t_bit) * 2;
            float tr = q->data[idx0], ti = q->data[idx0+1];
            q->data[idx0] = q->data[idx1]; q->data[idx0+1] = q->data[idx1+1];
            q->data[idx1] = tr; q->data[idx1+1] = ti;
        }
    }
}

/* ==================================================================== */
/* --- 4. Optimization Kernels (ExpectZZ & Utilities) ----------------- */
/* ==================================================================== */

double internal_get_expectation_zz(quantum_t *q, int qi, int qj) {
#ifdef USE_OPENCL
    if (gpu_ready && q->gpu_buffer) {
        clEnqueueUnmapMemObject(clQueue, q->gpu_buffer, q->data, 0, NULL, NULL);
        clSetKernelArg(clExpectZZKernel, 0, sizeof(cl_mem), &q->gpu_buffer);
        clSetKernelArg(clExpectZZKernel, 1, sizeof(int), &qi);
        clSetKernelArg(clExpectZZKernel, 2, sizeof(int), &qj);
        clSetKernelArg(clExpectZZKernel, 3, sizeof(cl_mem), &q->res_buffer);
        size_t g_size = q->size;
        clEnqueueNDRangeKernel(clQueue, clExpectZZKernel, 1, NULL, &g_size, NULL, 0, NULL, NULL);
        
        float* res_ptr = (float*)clEnqueueMapBuffer(clQueue, q->res_buffer, CL_TRUE, CL_MAP_READ, 0, q->size*4, 0, NULL, NULL, NULL);
        double total = 0;
        int k;
        #pragma omp parallel for reduction(+:total)
        for (k = 0; k < (int)q->size; k++) total += res_ptr[k];
        clEnqueueUnmapMemObject(clQueue, q->res_buffer, res_ptr, 0, NULL, NULL);
        q->data = (float*)clEnqueueMapBuffer(clQueue, q->gpu_buffer, CL_TRUE, CL_MAP_READ | CL_MAP_WRITE, 0, q->size*8, 0, NULL, NULL, NULL);
        return total;
    }
#endif
    // CPU Fallback
    size_t m_i = ((size_t)1 << qi), m_j = ((size_t)1 << qj);
    double total = 0;
    int k;
    #pragma omp parallel for reduction(+:total) schedule(static)
    for (k = 0; k < (int)q->size; k++) {
        float p = (q->data[k*2]*q->data[k*2]) + (q->data[k*2+1]*q->data[k*2+1]);
        total += (((size_t)k & m_i) != 0) == (((size_t)k & m_j) != 0) ? p : -p;
    }
    return total;
}

void internal_gate_x(quantum_t *q, int target) {
    if (!q || !q->data) return;
    if (target < 0 || target >= q->nqubits) return;

#ifdef USE_OPENCL
    if (gpu_ready && q->gpu_buffer) {
        clEnqueueUnmapMemObject(clQueue, q->gpu_buffer, q->data, 0, NULL, NULL);
        clSetKernelArg(clXKernel, 0, sizeof(cl_mem), &q->gpu_buffer);
        clSetKernelArg(clXKernel, 1, sizeof(int), &target);
        size_t g_size = q->size;
        clEnqueueNDRangeKernel(clQueue, clXKernel, 1, NULL, &g_size, NULL, 0, NULL, NULL);
        q->data = (float*)clEnqueueMapBuffer(clQueue, q->gpu_buffer, CL_TRUE, CL_MAP_READ | CL_MAP_WRITE, 0, q->size * 8, 0, NULL, NULL, NULL);
        return;
    }
#endif

    size_t step = ((size_t)1 << target);
    int i, j;
    #pragma omp parallel for private(j) schedule(static)
    for (i = 0; i < (int)q->size; i += (int)(step << 1)) {
        for (j = i; j < i + (int)step; j++) {
            size_t idx0 = (size_t)j * 2, idx1 = (j + step) * 2;
            float tr = q->data[idx0], ti = q->data[idx0 + 1];
            q->data[idx0] = q->data[idx1];
            q->data[idx0 + 1] = q->data[idx1 + 1];
            q->data[idx1] = tr;
            q->data[idx1 + 1] = ti;
        }
    }
}

/* --- Core Gates --- */

void internal_gate_unitary(quantum_t *q, int target, float *m) {
    if (!q || !q->data) return;
    if (target < 0 || target >= q->nqubits) return;

#ifdef USE_OPENCL
    if (gpu_ready && q->gpu_buffer) {
        clEnqueueUnmapMemObject(clQueue, q->gpu_buffer, q->data, 0, NULL, NULL);
        clSetKernelArg(clUnitaryKernel, 0, sizeof(cl_mem), &q->gpu_buffer);
        clSetKernelArg(clUnitaryKernel, 1, sizeof(int), &target);
        clSetKernelArg(clUnitaryKernel, 2, 8 * sizeof(float), m);
        size_t g_size = q->size;
        clEnqueueNDRangeKernel(clQueue, clUnitaryKernel, 1, NULL, &g_size, NULL, 0, NULL, NULL);
        q->data = (float*)clEnqueueMapBuffer(clQueue, q->gpu_buffer, CL_TRUE, 
                  CL_MAP_READ | CL_MAP_WRITE, 0, q->size * 8, 0, NULL, NULL, NULL);
        return;
    }
#endif

    // CPU Fallback (Complex Math)
    size_t step = ((size_t)1 << target);
    int i, j;
    #pragma omp parallel for private(j) schedule(static)
    for (i = 0; i < (int)q->size; i += (int)(step << 1)) {
        for (j = i; j < i + (int)step; j++) {
            size_t idx0 = (size_t)j * 2, idx1 = (j + step) * 2;
            float r0 = q->data[idx0], im0 = q->data[idx0+1];
            float r1 = q->data[idx1], im1 = q->data[idx1+1];
            
            float nr0, ni0, nr1, ni1, tr, ti;
            complex_mul(m[0], m[1], r0, im0, &nr0, &ni0);
            complex_mul(m[2], m[3], r1, im1, &tr, &ti);
            nr0 += tr; ni0 += ti;
            
            complex_mul(m[4], m[5], r0, im0, &nr1, &ni1);
            complex_mul(m[6], m[7], r1, im1, &tr, &ti);
            nr1 += tr; ni1 += ti;
            
            q->data[idx0] = nr0; q->data[idx0+1] = ni0;
            q->data[idx1] = nr1; q->data[idx1+1] = ni1;
        }
    }
}

double internal_get_probability(quantum_t *q, int target) {
    if (q == NULL || q->data == NULL) return 0.0;
    if (target < 0 || target >= q->nqubits) return 0.0;

#ifdef USE_OPENCL
    if (gpu_ready && q->gpu_buffer) {
        clEnqueueUnmapMemObject(clQueue, q->gpu_buffer, q->data, 0, NULL, NULL);
        clSetKernelArg(clProbKernel, 0, sizeof(cl_mem), &q->gpu_buffer);
        clSetKernelArg(clProbKernel, 1, sizeof(int), &target);
        clSetKernelArg(clProbKernel, 2, sizeof(cl_mem), &q->res_buffer);
        size_t g_size = q->size;
        clEnqueueNDRangeKernel(clQueue, clProbKernel, 1, NULL, &g_size, NULL, 0, NULL, NULL);
        
        float* res_ptr = (float*)clEnqueueMapBuffer(clQueue, q->res_buffer, CL_TRUE, CL_MAP_READ, 0, q->size*4, 0, NULL, NULL, NULL);
        double prob = 0.0;
        int k;
        #pragma omp parallel for reduction(+:prob)
        for (k = 0; k < (int)q->size; k++) prob += res_ptr[k];
        clEnqueueUnmapMemObject(clQueue, q->res_buffer, res_ptr, 0, NULL, NULL);
        q->data = (float*)clEnqueueMapBuffer(clQueue, q->gpu_buffer, CL_TRUE, CL_MAP_READ | CL_MAP_WRITE, 0, q->size*8, 0, NULL, NULL, NULL);
        return prob;
    }
#endif

    size_t n = q->size;
    size_t step = ((size_t)1 << target);
    double prob = 0.0;
    int i, j;
    #pragma omp parallel for reduction(+:prob) private(j)
    for (i = 0; i < (int)n; i += (int)(step << 1)) {
        for (j = i + (int)step; j < i + (int)(step << 1); j++) {
            prob += (q->data[j * 2] * q->data[j * 2]) + (q->data[j * 2 + 1] * q->data[j * 2 + 1]);
        }
    }
    return prob;
}

int internal_measure(quantum_t *q, int target) {
    if (q == NULL || q->data == NULL) return 0;
    if (target < 0 || target >= q->nqubits) return 0;

    double p1 = internal_get_probability(q, target);
    static int seeded = 0;
    if (!seeded) { srand((unsigned int)time(NULL)); seeded = 1; }

    double r = (double)rand() / RAND_MAX;
    int result = (r < p1) ? 1 : 0;
    double denom = result ? p1 : (1.0 - p1);
    if (denom < 1e-12) denom = 1e-12;
    float norm = (float)(1.0 / sqrt(denom));

#ifdef USE_OPENCL
    if (gpu_ready && q->gpu_buffer) {
        clEnqueueUnmapMemObject(clQueue, q->gpu_buffer, q->data, 0, NULL, NULL);
        clSetKernelArg(clCollapseKernel, 0, sizeof(cl_mem), &q->gpu_buffer);
        clSetKernelArg(clCollapseKernel, 1, sizeof(int), &target);
        clSetKernelArg(clCollapseKernel, 2, sizeof(int), &result);
        clSetKernelArg(clCollapseKernel, 3, sizeof(float), &norm);
        size_t g_size = q->size;
        clEnqueueNDRangeKernel(clQueue, clCollapseKernel, 1, NULL, &g_size, NULL, 0, NULL, NULL);
        q->data = (float*)clEnqueueMapBuffer(clQueue, q->gpu_buffer, CL_TRUE, CL_MAP_READ | CL_MAP_WRITE, 0, q->size*8, 0, NULL, NULL, NULL);
        return result;
    }
#endif

    size_t n = q->size;
    size_t step = ((size_t)1 << target);
    int i, j;
    #pragma omp parallel for private(j)
    for (i = 0; i < (int)n; i += (int)(step << 1)) {
        for (j = 0; j < (int)step; j++) {
            size_t idx_keep = ((result ? (i + (int)step) : i) + j) * 2;
            size_t idx_zero = ((result ? i : (i + (int)step)) + j) * 2;
            q->data[idx_keep] *= norm; q->data[idx_keep + 1] *= norm;
            q->data[idx_zero] = 0.0f; q->data[idx_zero + 1] = 0.0f;
        }
    }
    return result;
}

// Applying Phase Gate (Rz(phi))
void internal_gate_phase(quantum_t *q, int target, float phi) {
    if (q == NULL || q->data == NULL) return;
    if (target < 0 || target >= q->nqubits) return;
#ifdef USE_OPENCL
    if (gpu_ready && q->gpu_buffer) {
        clEnqueueUnmapMemObject(clQueue, q->gpu_buffer, q->data, 0, NULL, NULL);
        clSetKernelArg(clRZKernel, 0, sizeof(cl_mem), &q->gpu_buffer);
        clSetKernelArg(clRZKernel, 1, sizeof(int), &target);
        clSetKernelArg(clRZKernel, 2, sizeof(float), &phi);
        size_t g_size = q->size;
        clEnqueueNDRangeKernel(clQueue, clRZKernel, 1, NULL, &g_size, NULL, 0, NULL, NULL);
        q->data = (float*)clEnqueueMapBuffer(clQueue, q->gpu_buffer, CL_TRUE, CL_MAP_READ | CL_MAP_WRITE, 0, q->size*8, 0, NULL, NULL, NULL);
        return;
    }
#endif
    size_t n = q->size;
    size_t step = ((size_t)1 << target);
    float *data = q->data;
    float cos_p = cosf(phi), sin_p = sinf(phi);
    int i,j;
    #pragma omp parallel for
    for (i = 0; i < (int)n; i += (int)(step << 1)) {
        for (j = i + (int)step; j < i + (int)(step << 1); j++) {
            size_t idx = (size_t)j * 2;
            float r = data[idx], im = data[idx + 1];
            data[idx]     = r * cos_p - im * sin_p;
            data[idx + 1] = r * sin_p + im * cos_p;
        }
    }
}

// SWAP Gate: Swaps states of two qubits
void internal_gate_swap(quantum_t *q, int q1, int q2) {
    if (q == NULL || q->data == NULL) return;
    if (q1 < 0 || q1 >= q->nqubits) return;
    if (q2 < 0 || q2 >= q->nqubits) return;
#ifdef USE_OPENCL
    if (gpu_ready && q->gpu_buffer) {
        clEnqueueUnmapMemObject(clQueue, q->gpu_buffer, q->data, 0, NULL, NULL);
        clSetKernelArg(clSwapKernel, 0, sizeof(cl_mem), &q->gpu_buffer);
        clSetKernelArg(clSwapKernel, 1, sizeof(int), &q1);
        clSetKernelArg(clSwapKernel, 2, sizeof(int), &q2);
        size_t g_size = q->size;
        clEnqueueNDRangeKernel(clQueue, clSwapKernel, 1, NULL, &g_size, NULL, 0, NULL, NULL);
        q->data = (float*)clEnqueueMapBuffer(clQueue, q->gpu_buffer, CL_TRUE, CL_MAP_READ | CL_MAP_WRITE, 0, q->size*8, 0, NULL, NULL, NULL);
        return;
    }
#endif
    size_t n = q->size;
    float *data = q->data;
    int i;
    #pragma omp parallel for
    for (i = 0; i < (int)n; i++) {
        if ((((size_t)i >> q1) & 1) != (((size_t)i >> q2) & 1)) {
            size_t j = (size_t)i ^ ((size_t)1 << q1) ^ ((size_t)1 << q2);
            if ((size_t)i < j) {
                size_t idx_i = (size_t)i * 2, idx_j = j * 2;
                float tr = data[idx_i], ti = data[idx_i+1];
                data[idx_i] = data[idx_j]; data[idx_i+1] = data[idx_j+1];
                data[idx_j] = tr; data[idx_j+1] = ti;
            }
        }
    }
}

// Toffoli Gate (CCNOT): Flips target if q1 AND q2 are 1
void internal_gate_toffoli(quantum_t *q, int q1, int q2, int target) {
    if (q == NULL || q->data == NULL) return;
    if (q1 < 0 || q1 >= q->nqubits) return;
    if (q2 < 0 || q2 >= q->nqubits) return;
    if (target < 0 || target >= q->nqubits) return;
#ifdef USE_OPENCL
    if (gpu_ready && q->gpu_buffer) {
        clEnqueueUnmapMemObject(clQueue, q->gpu_buffer, q->data, 0, NULL, NULL);
        clSetKernelArg(clToffoliKernel, 0, sizeof(cl_mem), &q->gpu_buffer);
        clSetKernelArg(clToffoliKernel, 1, sizeof(int), &q1);
        clSetKernelArg(clToffoliKernel, 2, sizeof(int), &q2);
        clSetKernelArg(clToffoliKernel, 3, sizeof(int), &target);
        size_t g_size = q->size;
        clEnqueueNDRangeKernel(clQueue, clToffoliKernel, 1, NULL, &g_size, NULL, 0, NULL, NULL);
        q->data = (float*)clEnqueueMapBuffer(clQueue, q->gpu_buffer, CL_TRUE, CL_MAP_READ | CL_MAP_WRITE, 0, q->size*8, 0, NULL, NULL, NULL);
        return;
    }
#endif
    size_t n = q->size;
    size_t mask = ((size_t)1 << q1) | ((size_t)1 << q2);
    size_t t_bit = ((size_t)1 << target);
    float *data = q->data;
    int i;
    #pragma omp parallel for
    for (i = 0; i < (int)n; i++) {
        if (((size_t)i & mask) == mask) {
            size_t j = (size_t)i ^ t_bit;
            if ((size_t)i < j) {
                size_t idx_i = (size_t)i * 2, idx_j = j * 2;
                float tr = data[idx_i], ti = data[idx_i+1];
                data[idx_i] = data[idx_j]; data[idx_i+1] = data[idx_j+1];
                data[idx_j] = tr; data[idx_j+1] = ti;
            }
        }
    }
}

void internal_gate_controlled_unitary(quantum_t *q, int ctrl, int target, float *m) {
    if (q == NULL || q->data == NULL) return;
    if (ctrl < 0 || ctrl >= q->nqubits) return;
    if (target < 0 || target >= q->nqubits) return;

#ifdef USE_OPENCL
    if (gpu_ready && q->gpu_buffer) {
        clEnqueueUnmapMemObject(clQueue, q->gpu_buffer, q->data, 0, NULL, NULL);
        clSetKernelArg(clMCUKernel, 0, sizeof(cl_mem), &q->gpu_buffer);
        unsigned long mask = (1LL << ctrl);
        clSetKernelArg(clMCUKernel, 1, sizeof(unsigned long), &mask);
        clSetKernelArg(clMCUKernel, 2, sizeof(int), &target);
        clSetKernelArg(clMCUKernel, 3, 8 * sizeof(float), m);
        size_t g_size = q->size;
        clEnqueueNDRangeKernel(clQueue, clMCUKernel, 1, NULL, &g_size, NULL, 0, NULL, NULL);
        q->data = (float*)clEnqueueMapBuffer(clQueue, q->gpu_buffer, CL_TRUE, CL_MAP_READ | CL_MAP_WRITE, 0, q->size*8, 0, NULL, NULL, NULL);
        return;
    }
#endif
    size_t n = q->size;
    size_t c_step = ((size_t)1 << ctrl);
    size_t t_step = ((size_t)1 << target);
    float *data = q->data;
    int i;
    #pragma omp parallel for
    for (i = 0; i < (int)n; i++) {
        if (((size_t)i & c_step) && !((size_t)i & t_step)) {
            size_t idx0 = (size_t)i * 2, idx1 = ((size_t)i ^ t_step) * 2;
            float r0 = data[idx0], i0 = data[idx0 + 1], r1 = data[idx1], i1 = data[idx1 + 1];
            float nr0, ni0, nr1, ni1, tr, ti;
            complex_mul(m[0], m[1], r0, i0, &nr0, &ni0);
            complex_mul(m[2], m[3], r1, i1, &tr, &ti);
            nr0 += tr; ni0 += ti;
            complex_mul(m[4], m[5], r0, i0, &nr1, &ni1);
            complex_mul(m[6], m[7], r1, i1, &tr, &ti);
            nr1 += tr; ni1 += ti;
            data[idx0] = nr0; data[idx0 + 1] = ni0;
            data[idx1] = nr1; data[idx1 + 1] = ni1;
        }
    }
}

/* --- Corrected Rotation Gates --- */

void internal_gate_ry(quantum_t *q, int target, float theta) {
    if (q == NULL || q->data == NULL) return;
    if (target < 0 || target >= q->nqubits) return;
#ifdef USE_OPENCL
    if (gpu_ready && q->gpu_buffer) {
        clEnqueueUnmapMemObject(clQueue, q->gpu_buffer, q->data, 0, NULL, NULL);
        clSetKernelArg(clRYKernel, 0, sizeof(cl_mem), &q->gpu_buffer);
        clSetKernelArg(clRYKernel, 1, sizeof(int), &target);
        clSetKernelArg(clRYKernel, 2, sizeof(float), &theta);
        size_t g_size = q->size;
        clEnqueueNDRangeKernel(clQueue, clRYKernel, 1, NULL, &g_size, NULL, 0, NULL, NULL);
        q->data = (float*)clEnqueueMapBuffer(clQueue, q->gpu_buffer, CL_TRUE, CL_MAP_READ | CL_MAP_WRITE, 0, q->size*8, 0, NULL, NULL, NULL);
        return;
    }
#endif
    size_t n = q->size;
    size_t step = ((size_t)1 << target);
    float *data = q->data;
    float c = cosf(theta / 2.0f);
    float s = sinf(theta / 2.0f);
    
    int i, j;
    #pragma omp parallel for private(j)
    for (i = 0; i < (int)n; i += (int)(step << 1)) {
        for (j = i; j < i + (int)step; j++) {
            size_t idx0 = (size_t)j * 2;
            size_t idx1 = (size_t)(j + step) * 2;
            float r0 = data[idx0], i0 = data[idx0 + 1];
            float r1 = data[idx1], i1 = data[idx1 + 1];

            data[idx0]     = r0 * c - r1 * s;
            data[idx0 + 1] = i0 * c - i1 * s;
            data[idx1]     = r0 * s + r1 * c;
            data[idx1 + 1] = i0 * s + i1 * c;
        }
    }
}

/* --- FIX 1: RX Gate (تصحيح الإشارة) --- */
void internal_gate_rx(quantum_t *q, int target, float theta) {
    if (q == NULL || q->data == NULL) return;
    if (target < 0 || target >= q->nqubits) return;
#ifdef USE_OPENCL
    if (gpu_ready && q->gpu_buffer) {
        clEnqueueUnmapMemObject(clQueue, q->gpu_buffer, q->data, 0, NULL, NULL);
        clSetKernelArg(clRXKernel, 0, sizeof(cl_mem), &q->gpu_buffer);
        clSetKernelArg(clRXKernel, 1, sizeof(int), &target);
        clSetKernelArg(clRXKernel, 2, sizeof(float), &theta);
        size_t g_size = q->size;
        clEnqueueNDRangeKernel(clQueue, clRXKernel, 1, NULL, &g_size, NULL, 0, NULL, NULL);
        q->data = (float*)clEnqueueMapBuffer(clQueue, q->gpu_buffer, CL_TRUE, CL_MAP_READ | CL_MAP_WRITE, 0, q->size*8, 0, NULL, NULL, NULL);
        return;
    }
#endif
    size_t n = q->size;
    size_t step = ((size_t)1 << target);
    float *data = q->data;
    float c = cosf(theta / 2.0f);
    float s = sinf(theta / 2.0f);
    int i, j;
    #pragma omp parallel for private(j)
    for (i = 0; i < (int)n; i += (int)(step << 1)) {
        for (j = i; j < i + (int)step; j++) {
            size_t idx0 = (size_t)j * 2, idx1 = (size_t)(j + step) * 2;
            float r0 = data[idx0], i0 = data[idx0 + 1], r1 = data[idx1], i1 = data[idx1 + 1];
            data[idx0]     = c*r0 + s*i1;
            data[idx0 + 1] = c*i0 - s*r1;
            data[idx1]     = c*r1 + s*i0;
            data[idx1 + 1] = c*i1 - s*r0;
        }
    }
}

void internal_gate_rz(quantum_t *q, int target, float theta) {
    if (q == NULL || q->data == NULL) return;
    if (target < 0 || target >= q->nqubits) return;
#ifdef USE_OPENCL
    if (gpu_ready && q->gpu_buffer) {
        clEnqueueUnmapMemObject(clQueue, q->gpu_buffer, q->data, 0, NULL, NULL);
        clSetKernelArg(clRZKernel, 0, sizeof(cl_mem), &q->gpu_buffer);
        clSetKernelArg(clRZKernel, 1, sizeof(int), &target);
        clSetKernelArg(clRZKernel, 2, sizeof(float), &theta);
        size_t g_size = q->size;
        clEnqueueNDRangeKernel(clQueue, clRZKernel, 1, NULL, &g_size, NULL, 0, NULL, NULL);
        q->data = (float*)clEnqueueMapBuffer(clQueue, q->gpu_buffer, CL_TRUE, CL_MAP_READ | CL_MAP_WRITE, 0, q->size*8, 0, NULL, NULL, NULL);
        return;
    }
#endif
    size_t n = q->size;
    size_t step = ((size_t)1 << target);
    float *data = q->data;
    float c = cosf(theta / 2.0f);
    float s = sinf(theta / 2.0f);
    int i, j;
    #pragma omp parallel for private(j)
    for (i = 0; i < (int)n; i += (int)(step << 1)) {
        for (j = i; j < i + (int)step; j++) {
            size_t idx0 = (size_t)j * 2, idx1 = (size_t)(j + step) * 2;
            float r0 = data[idx0], i0 = data[idx0 + 1], r1 = data[idx1], i1 = data[idx1 + 1];
            data[idx0]     = r0 * c + i0 * s;
            data[idx0 + 1] = i0 * c - r0 * s;
            data[idx1]     = r1 * c - i1 * s;
            data[idx1 + 1] = i1 * c + r1 * s;
        }
    }
}


/* --- Advanced Multi-Controlled Kernels --- */

// Generalized Multi-Controlled Unitary (MCU)
// Can implement MCX, MCZ, MCRy, etc.
// aControls: array of control qubits, nControls: number of controls
void internal_gate_mcu(quantum_t *q, int *aControls, int nControls, int target, float *m) {
    if (q == NULL || q->data == NULL) return;
    if (target < 0 || target >= q->nqubits) return;
    size_t mask = 0;
    for(int k=0; k < nControls; k++) mask |= ((size_t)1 << aControls[k]);

#ifdef USE_OPENCL
    if (gpu_ready && q->gpu_buffer) {
        clEnqueueUnmapMemObject(clQueue, q->gpu_buffer, q->data, 0, NULL, NULL);
        clSetKernelArg(clMCUKernel, 0, sizeof(cl_mem), &q->gpu_buffer);
        unsigned long cl_mask = (unsigned long)mask;
        clSetKernelArg(clMCUKernel, 1, sizeof(unsigned long), &cl_mask);
        clSetKernelArg(clMCUKernel, 2, sizeof(int), &target);
        clSetKernelArg(clMCUKernel, 3, 8 * sizeof(float), m);
        size_t g_size = q->size;
        clEnqueueNDRangeKernel(clQueue, clMCUKernel, 1, NULL, &g_size, NULL, 0, NULL, NULL);
        q->data = (float*)clEnqueueMapBuffer(clQueue, q->gpu_buffer, CL_TRUE, CL_MAP_READ | CL_MAP_WRITE, 0, q->size*8, 0, NULL, NULL, NULL);
        return;
    }
#endif
    size_t n = q->size;
    size_t t_bit = ((size_t)1 << target);
    float *data = q->data;
    int i;
    #pragma omp parallel for
    for (i = 0; i < (int)n; i++) {
        if (((size_t)i & mask) == mask && !((size_t)i & t_bit)) {
            size_t idx0 = (size_t)i * 2, idx1 = ((size_t)i ^ t_bit) * 2;
            float r0 = data[idx0], i0 = data[idx0 + 1], r1 = data[idx1], i1 = data[idx1 + 1];
            float nr0, ni0, nr1, ni1, tr, ti;
            complex_mul(m[0], m[1], r0, i0, &nr0, &ni0);
            complex_mul(m[2], m[3], r1, i1, &tr, &ti);
            nr0 += tr; ni0 += ti;
            complex_mul(m[4], m[5], r0, i0, &nr1, &ni1);
            complex_mul(m[6], m[7], r1, i1, &tr, &ti);
            nr1 += tr; ni1 += ti;
            data[idx0] = nr0; data[idx0 + 1] = ni0;
            data[idx1] = nr1; data[idx1 + 1] = ni1;
        }
    }
}

// State Fidelity: Measures how similar two quantum states are
// Formula: |<psi|phi>|^2
double internal_get_fidelity(quantum_t *q1, quantum_t *q2) {
    if (q1 == NULL || q2 == NULL || q1->data == NULL || q2->data == NULL) return 0.0;
    if (q1->nqubits != q2->nqubits) return 0.0;
    double real_sum = 0.0, imag_sum = 0.0;
    size_t n = q1->size;
    int i;
    #pragma omp parallel for reduction(+:real_sum, imag_sum)
    for (i = 0; i < (int)n; i++) {
        size_t idx = (size_t)i * 2;
        real_sum += (q1->data[idx] * q2->data[idx] + q1->data[idx+1] * q2->data[idx+1]);
        imag_sum += (q1->data[idx+1] * q2->data[idx] - q1->data[idx] * q2->data[idx+1]);
    }
    return (real_sum * real_sum + imag_sum * imag_sum);
}

/* --- Full Pauli Expectations (Essential for VQE & Physics) --- */

void internal_gate_u(quantum_t *q, int target, float theta, float phi, float lambda) {
    if (q == NULL || q->data == NULL) return;
    if (target < 0 || target >= q->nqubits) return;
    float m[8];
    float ct = cosf(theta/2.0f), st = sinf(theta/2.0f);
    m[0] = ct; m[1] = 0;
    m[2] = -cosf(lambda)*st; m[3] = -sinf(lambda)*st;
    m[4] = cosf(phi)*st; m[5] = sinf(phi)*st;
    m[6] = cosf(phi+lambda)*ct; m[7] = sinf(phi+lambda)*ct;
    internal_gate_unitary(q, target, m);
}

double internal_get_expectation_x(quantum_t *q, int target) {
    quantum_t *tmp = quantum_create(q->nqubits);
    memcpy(tmp->data, q->data, q->size * 8); // 2 * float = 8 bytes
    internal_gate_h(tmp, target);
    double res = internal_get_expectation_z(tmp, target);
    ring_quantum_free(NULL, tmp);
    return res;
}

double internal_get_expectation_y(quantum_t *q, int target) {
    quantum_t *tmp = quantum_create(q->nqubits);
    memcpy(tmp->data, q->data, q->size * 8);
    // Y = H Rz(-pi/2) X ? No, simpler: Rx(pi/2) -> Z -> Rx(-pi/2)
    internal_gate_rx(tmp, target, 1.57079632f);
    double res = internal_get_expectation_z(tmp, target);
    ring_quantum_free(NULL, tmp);
    return res;
}

double internal_get_expectation_z(quantum_t *q, int target) {
#ifdef USE_OPENCL
    if (gpu_ready && q->gpu_buffer) {
        clEnqueueUnmapMemObject(clQueue, q->gpu_buffer, q->data, 0, NULL, NULL);
        clSetKernelArg(clExpectZKernel, 0, sizeof(cl_mem), &q->gpu_buffer);
        clSetKernelArg(clExpectZKernel, 1, sizeof(int), &target);
        clSetKernelArg(clExpectZKernel, 2, sizeof(cl_mem), &q->res_buffer);
        size_t g_size = q->size;
        clEnqueueNDRangeKernel(clQueue, clExpectZKernel, 1, NULL, &g_size, NULL, 0, NULL, NULL);
        
        float* res_ptr = (float*)clEnqueueMapBuffer(clQueue, q->res_buffer, CL_TRUE, CL_MAP_READ, 0, q->size*4, 0, NULL, NULL, NULL);
        double total = 0;
        int k;
        #pragma omp parallel for reduction(+:total)
        for(k=0; k<(int)q->size; k++) total += res_ptr[k];
        clEnqueueUnmapMemObject(clQueue, q->res_buffer, res_ptr, 0, NULL, NULL);
        q->data = (float*)clEnqueueMapBuffer(clQueue, q->gpu_buffer, CL_TRUE, CL_MAP_READ | CL_MAP_WRITE, 0, q->size*8, 0, NULL, NULL, NULL);
        return total;
    }
#endif
    size_t n = q->size;
    size_t t_bit = ((size_t)1 << target);
    float *data = q->data;
    double exp_val = 0.0;
    int i;
    #pragma omp parallel for reduction(+:exp_val)
    for (i = 0; i < (int)n; i++) {
        float prob = (data[i * 2] * data[i * 2]) + (data[i * 2 + 1] * data[i * 2 + 1]);
        if ((size_t)i & t_bit) exp_val -= prob;
        else exp_val += prob;
    }
    return exp_val;
}

//===================================================================


// The LogPsi calculation function in full (called once at the beginning of the sampler)
void nqs_compute_theta(nqs_t *nqs, nqs_cache_t *cache) {
    int n = nqs->nqubits;
    int m = nqs->nhidden;
    int i,j;
    
#ifdef USE_OPENCL
    if (gpu_ready && nqs->cl_W_re && (n * m > 40000)) {
        for(i=0; i<n; i++) nqs->s_f[i] = (float)nqs->spins[i];
        for(i=0; i<n*m; i++) { nqs->w_re_f[i] = (float)nqs->W_real[i]; nqs->w_im_f[i] = (float)nqs->W_imag[i]; }
        for(j=0; j<m; j++) nqs->b_re_f[j] = (float)nqs->b_real[j];
        
        clEnqueueWriteBuffer(clQueue, nqs->cl_W_re, CL_FALSE, 0, n * m * sizeof(float), nqs->w_re_f, 0, NULL, NULL);
        clEnqueueWriteBuffer(clQueue, nqs->cl_W_im, CL_FALSE, 0, n * m * sizeof(float), nqs->w_im_f, 0, NULL, NULL);
        clEnqueueWriteBuffer(clQueue, nqs->cl_b_re, CL_FALSE, 0, m * sizeof(float), nqs->b_re_f, 0, NULL, NULL);
        clEnqueueWriteBuffer(clQueue, nqs->cl_spins, CL_TRUE, 0, n * sizeof(float), nqs->s_f, 0, NULL, NULL);
        
        clSetKernelArg(clNQSThetaKernel, 0, sizeof(cl_mem), &nqs->cl_spins);
        clSetKernelArg(clNQSThetaKernel, 1, sizeof(cl_mem), &nqs->cl_W_re);
        clSetKernelArg(clNQSThetaKernel, 2, sizeof(cl_mem), &nqs->cl_W_im);
        clSetKernelArg(clNQSThetaKernel, 3, sizeof(cl_mem), &nqs->cl_b_re);
        clSetKernelArg(clNQSThetaKernel, 4, sizeof(int), &n);
        clSetKernelArg(clNQSThetaKernel, 5, sizeof(int), &m);
        clSetKernelArg(clNQSThetaKernel, 6, sizeof(cl_mem), &nqs->cl_t_re);
        clSetKernelArg(clNQSThetaKernel, 7, sizeof(cl_mem), &nqs->cl_t_im);
        
        size_t g_size = m;
        clEnqueueNDRangeKernel(clQueue, clNQSThetaKernel, 1, NULL, &g_size, NULL, 0, NULL, NULL);
        
        clEnqueueReadBuffer(clQueue, nqs->cl_t_re, CL_FALSE, 0, m * sizeof(float), nqs->t_re_f, 0, NULL, NULL);
        clEnqueueReadBuffer(clQueue, nqs->cl_t_im, CL_TRUE, 0, m * sizeof(float), nqs->t_im_f, 0, NULL, NULL);
        
        for(j=0; j<m; j++) {
            cache->theta_re[j] = (double)nqs->t_re_f[j];
            cache->theta_im[j] = (double)nqs->t_im_f[j];
        }
        return;
    }
#endif

    #pragma omp parallel for
    for (j = 0; j < m; j++) {
        double sum_re = nqs->b_real[j]; // Start with Hidden Bias
        double sum_im = 0; // If there is b_imag
        
        for (i = 0; i < n; i++) {
            // W_real stored as [n x m]
            double s = (double)nqs->spins[i]; // +1 or -1
            sum_re += nqs->W_real[i * m + j] * s;
            sum_im += nqs->W_imag[i * m + j] * s;
        }
        cache->theta_re[j] = sum_re;
        cache->theta_im[j] = sum_im;
    }
}

void internal_nqs_sample(nqs_t *nqs, nqs_cache_t *cache, int steps) {
    int n = nqs->nqubits;
    int m = nqs->nhidden;
    
    for (int s = 0; s < steps; s++) {
        // 1. Choose a random qubit to flip
        int i = rand() % n;
        double s_old = (double)nqs->spins[i];
        double s_new = -s_old;
        
        // 2. Calculate Acceptance Ratio
        // Ratio = |ψ(s') / ψ(s)|^2
        // LogRatio = Re( Σ log(cosh(θ_j_new) / cosh(θ_j_old)) )
        double log_acceptance = 0;
        
        for (int j = 0; j < m; j++) {
            // Delta Update for Hidden Cell j
            double d_re = (s_new - s_old) * nqs->W_real[i * m + j];
            double d_im = (s_new - s_old) * nqs->W_imag[i * m + j];
            
            double th_old_re = cache->theta_re[j];
            double th_old_im = cache->theta_im[j];
            double th_new_re = th_old_re + d_re;
            double th_new_im = th_old_im + d_im;

            // Acceptance ratio for RBM with complex weights
            // |Psi_new/Psi_old|^2 = Prod |cosh(theta_new)/cosh(theta_old)|^2
            // |cosh(x+iy)|^2 = 0.5 * (cosh(2x) + cos(2y))
            double ratio_val = (cosh(2.0*th_new_re) + cos(2.0*th_new_im)) / 
                               (cosh(2.0*th_old_re) + cos(2.0*th_old_im) + 1e-15);
            
            log_acceptance += log(ratio_val);
        }
        
        // 3. Metropolis Decision
        if ((double)rand()/RAND_MAX < exp(log_acceptance)) {
            nqs->spins[i] = (int8_t)s_new;
            // Update cache immediately in O(M)
            for (int j = 0; j < m; j++) {
                cache->theta_re[j] += (s_new - s_old) * nqs->W_real[i * m + j];
                cache->theta_im[j] += (s_new - s_old) * nqs->W_imag[i * m + j];
            }
        }
    }
}

/* 
** Calculate Gradients for RBM
** grad_W_re/im: Weight matrices [N x M]
** grad_b_re/im: Hidden bias vector [M]
*/
void internal_nqs_compute_gradients(nqs_t *nqs, double *gW_re, double *gW_im, double *gb_re, double *ga_re) {
    if (!nqs || !nqs->theta_re) return;
    
    int n = nqs->nqubits;
    int m = nqs->nhidden;
    int i,j;
    
#ifdef USE_OPENCL
    if (gpu_ready && nqs->cl_W_re && (n * m > 40000)) {
        for(i=0; i<n; i++) nqs->s_f[i] = (float)nqs->spins[i];
        for(j=0; j<m; j++) { nqs->t_re_f[j] = (float)nqs->theta_re[j]; nqs->t_im_f[j] = (float)nqs->theta_im[j]; }
        
        clEnqueueWriteBuffer(clQueue, nqs->cl_spins, CL_FALSE, 0, n * sizeof(float), nqs->s_f, 0, NULL, NULL);
        clEnqueueWriteBuffer(clQueue, nqs->cl_t_re, CL_FALSE, 0, m * sizeof(float), nqs->t_re_f, 0, NULL, NULL);
        clEnqueueWriteBuffer(clQueue, nqs->cl_t_im, CL_TRUE, 0, m * sizeof(float), nqs->t_im_f, 0, NULL, NULL);
        
        clSetKernelArg(clNQSGradsKernel, 0, sizeof(cl_mem), &nqs->cl_spins);
        clSetKernelArg(clNQSGradsKernel, 1, sizeof(cl_mem), &nqs->cl_t_re);
        clSetKernelArg(clNQSGradsKernel, 2, sizeof(cl_mem), &nqs->cl_t_im);
        clSetKernelArg(clNQSGradsKernel, 3, sizeof(int), &n);
        clSetKernelArg(clNQSGradsKernel, 4, sizeof(int), &m);
        clSetKernelArg(clNQSGradsKernel, 5, sizeof(cl_mem), &nqs->cl_W_re);
        clSetKernelArg(clNQSGradsKernel, 6, sizeof(cl_mem), &nqs->cl_W_im);
        clSetKernelArg(clNQSGradsKernel, 7, sizeof(cl_mem), &nqs->cl_b_re);
        
        size_t g_size = m;
        clEnqueueNDRangeKernel(clQueue, clNQSGradsKernel, 1, NULL, &g_size, NULL, 0, NULL, NULL);
        
        clEnqueueReadBuffer(clQueue, nqs->cl_W_re, CL_FALSE, 0, n * m * sizeof(float), nqs->gw_re_f, 0, NULL, NULL);
        clEnqueueReadBuffer(clQueue, nqs->cl_W_im, CL_FALSE, 0, n * m * sizeof(float), nqs->gw_im_f, 0, NULL, NULL);
        clEnqueueReadBuffer(clQueue, nqs->cl_b_re, CL_TRUE, 0, m * sizeof(float), nqs->gb_re_f, 0, NULL, NULL);
        
        for(j=0; j<m; j++) {
            if (gb_re) gb_re[j] += (double)nqs->gb_re_f[j];
            for(i=0; i<n; i++) {
                if (gW_re) gW_re[i*m + j] += (double)nqs->gw_re_f[i*m + j];
                if (gW_im) gW_im[i*m + j] += (double)nqs->gw_im_f[i*m + j];
            }
        }
        
        if (ga_re) {
            for (i = 0; i < n; i++) ga_re[i] += (double)nqs->spins[i];
        }
        return;
    }
#endif

    #pragma omp parallel for schedule(static)
    for (j = 0; j < m; j++) {
        double x = nqs->theta_re[j];
        double y = nqs->theta_im[j];
        double denom = cosh(2.0 * x) + cos(2.0 * y);
        if (denom < 1e-15) denom = 1e-15;

        double t_re = sinh(2.0 * x) / denom;
        double t_im = sin(2.0 * y) / denom;

        // Protection: Only write if pointer is not null
        if (gb_re) gb_re[j] += t_re;
        
        if (gW_re || gW_im) {
            for (i = 0; i < n; i++) {
                double s = (double)nqs->spins[i];
                if (gW_re) gW_re[i * m + j] += s * t_re;
                if (gW_im) gW_im[i * m + j] += s * t_im;
            }
        }
    }
    
    // Gradient of Visible Bias (ga)
    if (ga_re) {
        int i;
        #pragma omp parallel for
        for (i = 0; i < n; i++) ga_re[i] += (double)nqs->spins[i];
    }
}

void internal_nqs_get_spins(nqs_t *nqs, List *pList) {
    for(int i=0; i<nqs->nqubits; i++) ring_list_adddouble(pList, (double)nqs->spins[i]);
}

/* 
** Function: internal_nqs_local_energy
** Logic: Calculates the current cost (Energy) of a specific configuration.
** Optimized for Portfolio Optimization and Ising Models.
*/
double internal_nqs_local_energy(nqs_t *nqs, double *h, double *J) {
    int n = nqs->nqubits;
    double energy = 0.0;
    int8_t *s = nqs->spins;

    // --- Compute Portfolio energy (Binary {0, 1} mapping) ---
    // Objective: E = x^T J x + h^T x  (where x is binary selector)
    int i, j;
    #pragma omp parallel for reduction(+:energy) private(i, j)
    for (i = 0; i < n; i++) {
        // Map spin {-1, 1} to binary {0, 1}
        double xi = (s[i] == 1) ? 1.0 : 0.0;
        if (xi == 0.0) continue;
        
        // Reward part
        energy += h[i] * xi;
        
        // Risk part: Diagonal (Variances)
        energy += J[i * n + i] * xi;
        
        // Risk part: Off-Diagonals (Covariances) with factor 2 for symmetry
        for (j = i + 1; j < n; j++) {
            double xj = (s[j] == 1) ? 1.0 : 0.0;
            if (xj == 1.0) {
                energy += 2.0 * J[i * n + j] * xi * xj;
            }
        }
    }

    return energy;
}



/* --- NQS API Wrappers --- */

// Free NQS memory
void ring_quantum_nqs_free(void *pState, void *pPointer) {
    nqs_t *nqs = (nqs_t *)pPointer;
    if (nqs) {
        if (nqs->spins) free(nqs->spins);
        if (nqs->theta_re) free(nqs->theta_re);
        if (nqs->theta_im) free(nqs->theta_im);
        
        if (nqs->h_f) free(nqs->h_f); if (nqs->J_f) free(nqs->J_f); if (nqs->s_f) free(nqs->s_f);
        if (nqs->w_re_f) free(nqs->w_re_f); if (nqs->w_im_f) free(nqs->w_im_f); if (nqs->b_re_f) free(nqs->b_re_f);
        if (nqs->t_re_f) free(nqs->t_re_f); if (nqs->t_im_f) free(nqs->t_im_f);
        if (nqs->gw_re_f) free(nqs->gw_re_f); if (nqs->gw_im_f) free(nqs->gw_im_f); if (nqs->gb_re_f) free(nqs->gb_re_f);

#ifdef USE_OPENCL
        if (gpu_ready && nqs->cl_W_re) {
            clReleaseMemObject(nqs->cl_W_re); clReleaseMemObject(nqs->cl_W_im);
            clReleaseMemObject(nqs->cl_b_re); clReleaseMemObject(nqs->cl_spins);
            clReleaseMemObject(nqs->cl_h);    clReleaseMemObject(nqs->cl_J);
            clReleaseMemObject(nqs->cl_t_re); clReleaseMemObject(nqs->cl_t_im);
            clReleaseMemObject(nqs->cl_res);
        }
#endif
        free(nqs);
    }
}

// Create NQS object
RING_FUNC(ring_quantum_nqs_init) {
    if (RING_API_PARACOUNT != 2) { RING_API_ERROR(RING_API_MISS2PARA); return; }
    int n = (int)RING_API_GETNUMBER(1);
    int m = (int)RING_API_GETNUMBER(2);
    
    nqs_t *nqs = (nqs_t*)calloc(1, sizeof(nqs_t));
    nqs->nqubits = n;
    nqs->nhidden = m;
    nqs->spins = (int8_t*)malloc(n * sizeof(int8_t));
    for(int i=0; i<n; i++) nqs->spins[i] = (rand()%2 == 0) ? 1 : -1;
    
    // Allocate permanent cache for θ (Theta) to avoid repetition in calculation
    nqs->theta_re = (double*)calloc(m, sizeof(double));
    nqs->theta_im = (double*)calloc(m, sizeof(double));
    
    // Allocate cached float buffers
    nqs->h_f = (float*)malloc(n * sizeof(float));
    nqs->J_f = (float*)malloc(n * n * sizeof(float));
    nqs->s_f = (float*)malloc(n * sizeof(float));
    nqs->w_re_f = (float*)malloc(n * m * sizeof(float));
    nqs->w_im_f = (float*)malloc(n * m * sizeof(float));
    nqs->b_re_f = (float*)malloc(m * sizeof(float));
    nqs->t_re_f = (float*)malloc(m * sizeof(float));
    nqs->t_im_f = (float*)malloc(m * sizeof(float));
    nqs->gw_re_f = (float*)malloc(n * m * sizeof(float));
    nqs->gw_im_f = (float*)malloc(n * m * sizeof(float));
    nqs->gb_re_f = (float*)malloc(m * sizeof(float));
    nqs->last_h_ptr = NULL; nqs->last_J_ptr = NULL;

#ifdef USE_OPENCL
    if (gpu_ready) {
        cl_int ret;
        nqs->cl_W_re = clCreateBuffer(clContext, CL_MEM_READ_WRITE, n * m * sizeof(float), NULL, &ret);
        nqs->cl_W_im = clCreateBuffer(clContext, CL_MEM_READ_WRITE, n * m * sizeof(float), NULL, &ret);
        nqs->cl_b_re = clCreateBuffer(clContext, CL_MEM_READ_WRITE, m * sizeof(float), NULL, &ret);
        nqs->cl_spins = clCreateBuffer(clContext, CL_MEM_READ_WRITE, n * sizeof(float), NULL, &ret);
        nqs->cl_h = clCreateBuffer(clContext, CL_MEM_READ_WRITE, n * sizeof(float), NULL, &ret);
        nqs->cl_J = clCreateBuffer(clContext, CL_MEM_READ_WRITE, n * n * sizeof(float), NULL, &ret);
        nqs->cl_t_re = clCreateBuffer(clContext, CL_MEM_READ_WRITE, m * sizeof(float), NULL, &ret);
        nqs->cl_t_im = clCreateBuffer(clContext, CL_MEM_READ_WRITE, m * sizeof(float), NULL, &ret);
        nqs->cl_res = clCreateBuffer(clContext, CL_MEM_READ_WRITE, n * sizeof(float), NULL, &ret);
    }
#endif
    
    RING_API_RETMANAGEDCPOINTER(nqs, "nqs_t", ring_quantum_nqs_free);
}

// Bind Tensors (Zero-Copy)
RING_FUNC(ring_quantum_nqs_bind) {
    nqs_t *nqs = (nqs_t*)RING_API_GETCPOINTER(1, "nqs_t");
    // Pass physical addresses from RingTensor (using tensor_get_data_ptr)
    nqs->W_real = (double*)(size_t)RING_API_GETNUMBER(2);
    nqs->W_imag = (double*)(size_t)RING_API_GETNUMBER(3);
    nqs->b_real = (double*)(size_t)RING_API_GETNUMBER(4);
}

// Run Sampler (Metropolis)
RING_FUNC(ring_quantum_nqs_sample) {
    nqs_t *nqs = (nqs_t*)RING_API_GETCPOINTER(1, "nqs_t");
    int steps = (int)RING_API_GETNUMBER(2);
    
    // Temporary cache setting for maximum speed
    nqs_cache_t cache;
    cache.theta_re = (double*)malloc(nqs->nhidden * sizeof(double));
    cache.theta_im = (double*)malloc(nqs->nhidden * sizeof(double));
    
    nqs_compute_theta(nqs, &cache);      // First full calculation
    internal_nqs_sample(nqs, &cache, steps); // Fast Delta updates
    
    free(cache.theta_re);
    free(cache.theta_im);
}

// Get current qubit state (for display and analysis)
RING_FUNC(ring_quantum_nqs_get_spins) {
    nqs_t *nqs = (nqs_t*)RING_API_GETCPOINTER(1, "nqs_t");
    List *pList = RING_API_NEWLIST;
    for(int i=0; i<nqs->nqubits; i++) ring_list_adddouble(pList, (double)nqs->spins[i]);
    RING_API_RETLIST(pList);
}

RING_FUNC(ring_quantum_nqs_grads) {
    nqs_t *nqs = (nqs_t*)RING_API_GETCPOINTER(1, "nqs_t");
    
    // Pointer check and precise conversion
    double *gW_re = (RING_API_GETNUMBER(2) != 0) ? (double*)(size_t)RING_API_GETNUMBER(2) : NULL;
    double *gW_im = (RING_API_GETNUMBER(3) != 0) ? (double*)(size_t)RING_API_GETNUMBER(3) : NULL;
    double *gb_re = (RING_API_GETNUMBER(4) != 0) ? (double*)(size_t)RING_API_GETNUMBER(4) : NULL;
    double *ga_re = (RING_API_GETNUMBER(5) != 0) ? (double*)(size_t)RING_API_GETNUMBER(5) : NULL;

    if (!nqs) return;
    
    // Update cache first
    nqs_cache_t cache;
    cache.theta_re = nqs->theta_re;
    cache.theta_im = nqs->theta_im;
    nqs_compute_theta(nqs, &cache);
    // Calculate gradient with protection
    internal_nqs_compute_gradients(nqs, gW_re, gW_im, gb_re, ga_re);
}

/* 
** Ring API Wrapper: quantum_nqs_energy(pNQS, h_ptr, J_ptr)
*/
RING_FUNC(ring_quantum_nqs_energy) {
    if (RING_API_PARACOUNT != 3) {
        RING_API_ERROR(RING_API_BADPARACOUNT);
        return;
    }

    nqs_t *nqs = (nqs_t*)RING_API_GETCPOINTER(1, "nqs_t");
    
    // Get raw pointers from AlQalam/RingTensor
    double *h = (double*)(size_t)RING_API_GETNUMBER(2);
    double *J = (double*)(size_t)RING_API_GETNUMBER(3);

    if (nqs == NULL || h == NULL || J == NULL) {
        RING_API_RETNUMBER(0.0);
        return;
    }

    double result = internal_nqs_local_energy(nqs, h, J);
    RING_API_RETNUMBER(result);
}

/* --- API Wrappers --- */

RING_FUNC(ring_quantum_init) {
    int nqubits = (int)RING_API_GETNUMBER(1);
    quantum_t *q = quantum_create(nqubits);
    RING_API_RETMANAGEDCPOINTER(q, RING_VM_POINTER_QUANTUM, ring_quantum_free);
}

RING_FUNC(ring_quantum_h) {
    quantum_t *q = (quantum_t*)RING_API_GETCPOINTER(1, RING_VM_POINTER_QUANTUM);
    int target = (int)RING_API_GETNUMBER(2);
    internal_gate_h(q, target);
}

RING_FUNC(ring_quantum_x) {
    quantum_t *q = (quantum_t*)RING_API_GETCPOINTER(1, RING_VM_POINTER_QUANTUM);
    int target = (int)RING_API_GETNUMBER(2);
    internal_gate_x(q, target);
}

RING_FUNC(ring_quantum_cnot) {
    quantum_t *q = (quantum_t*)RING_API_GETCPOINTER(1, RING_VM_POINTER_QUANTUM);
    int ctrl = (int)RING_API_GETNUMBER(2);
    int trgt = (int)RING_API_GETNUMBER(3);
    internal_gate_cnot(q, ctrl, trgt);
}

RING_FUNC(ring_quantum_get_state) {
    quantum_t *q = (quantum_t*)RING_API_GETCPOINTER(1, RING_VM_POINTER_QUANTUM);
    List *pList = RING_API_NEWLIST;
    for(size_t i = 0; i < q->size * 2; i++) {
        ring_list_adddouble(pList, q->data[i]);
    }
    RING_API_RETLIST(pList);
}

/* --- API Registration & Helpers --- */

RING_FUNC(ring_quantum_unitary) {
    quantum_t *q = (quantum_t*)RING_API_GETCPOINTER(1, RING_VM_POINTER_QUANTUM);
    int target = (int)RING_API_GETNUMBER(2);
    List *pList = RING_API_GETLIST(3);
    float matrix[8];
    for(int i=0; i<8; i++) matrix[i] = (float)ring_list_getdouble(pList, i+1);
    internal_gate_unitary(q, target, matrix);
}

RING_FUNC(ring_quantum_get_probability) {
    quantum_t *q = (quantum_t*)RING_API_GETCPOINTER(1, RING_VM_POINTER_QUANTUM);
    int target = (int)RING_API_GETNUMBER(2);
    RING_API_RETNUMBER(internal_get_probability(q, target));
}

RING_FUNC(ring_quantum_measure) {
    quantum_t *q = (quantum_t*)RING_API_GETCPOINTER(1, RING_VM_POINTER_QUANTUM);
    int target = (int)RING_API_GETNUMBER(2);
    RING_API_RETNUMBER(internal_measure(q, target));
}

RING_FUNC(ring_quantum_phase) {
    quantum_t *q = (quantum_t*)RING_API_GETCPOINTER(1, RING_VM_POINTER_QUANTUM);
    int target = (int)RING_API_GETNUMBER(2);
    float phi = (float)RING_API_GETNUMBER(3);
    internal_gate_phase(q, target, phi);
}

RING_FUNC(ring_quantum_free_mem) {
    quantum_t *q = (quantum_t*)RING_API_GETCPOINTER(1, RING_VM_POINTER_QUANTUM);
    if (q) {
        ring_quantum_free(NULL, q);
    }
}

RING_FUNC(ring_quantum_swap) {
    quantum_t *q = (quantum_t*)RING_API_GETCPOINTER(1, RING_VM_POINTER_QUANTUM);
    int q1 = (int)RING_API_GETNUMBER(2);
    int q2 = (int)RING_API_GETNUMBER(3);
    internal_gate_swap(q, q1, q2);
}

RING_FUNC(ring_quantum_toffoli) {
    quantum_t *q = (quantum_t*)RING_API_GETCPOINTER(1, RING_VM_POINTER_QUANTUM);
    int q1 = (int)RING_API_GETNUMBER(2);
    int q2 = (int)RING_API_GETNUMBER(3);
    int target = (int)RING_API_GETNUMBER(4);
    internal_gate_toffoli(q, q1, q2, target);
}

RING_FUNC(ring_quantum_get_probabilities) {
    quantum_t *q = (quantum_t*)RING_API_GETCPOINTER(1, RING_VM_POINTER_QUANTUM);
    List *pList = RING_API_NEWLIST;
    for(size_t i = 0; i < q->size; i++) {
        double p = (q->data[i*2] * q->data[i*2]) + (q->data[i*2 + 1] * q->data[i*2 + 1]);
        ring_list_adddouble(pList, p);
    }
    RING_API_RETLIST(pList);
}


/* --- Multithreading Control --- */

RING_FUNC(ring_quantum_get_cores) {
    int cores = 1;
    #ifdef _OPENMP
    cores = omp_get_num_procs();
    #endif
    RING_API_RETNUMBER(cores);
}

RING_FUNC(ring_quantum_set_threads) {
    if (RING_API_PARACOUNT != 1) return;
    int n = (int)RING_API_GETNUMBER(1);
    #ifdef _OPENMP
    omp_set_num_threads(n);
    #endif
}

RING_FUNC(ring_quantum_controlled_unitary) {
    quantum_t *q = (quantum_t*)RING_API_GETCPOINTER(1, RING_VM_POINTER_QUANTUM);
    int ctrl = (int)RING_API_GETNUMBER(2);
    int target = (int)RING_API_GETNUMBER(3);
    List *pList = RING_API_GETLIST(4);
    float matrix[8];
    for(int i=0; i<8; i++) matrix[i] = (float)ring_list_getdouble(pList, i+1);
    internal_gate_controlled_unitary(q, ctrl, target, matrix);
}

RING_FUNC(ring_quantum_rx) {
    quantum_t *q = (quantum_t*)RING_API_GETCPOINTER(1, RING_VM_POINTER_QUANTUM);
    int target = (int)RING_API_GETNUMBER(2);
    float theta = (float)RING_API_GETNUMBER(3);
    internal_gate_rx(q, target, theta);
}

RING_FUNC(ring_quantum_ry) {
    quantum_t *q = (quantum_t*)RING_API_GETCPOINTER(1, RING_VM_POINTER_QUANTUM);
    int target = (int)RING_API_GETNUMBER(2);
    float theta = (float)RING_API_GETNUMBER(3);
    internal_gate_ry(q, target, theta);
}

RING_FUNC(ring_quantum_rz) {
    quantum_t *q = (quantum_t*)RING_API_GETCPOINTER(1, RING_VM_POINTER_QUANTUM);
    int target = (int)RING_API_GETNUMBER(2);
    float theta = (float)RING_API_GETNUMBER(3);
    internal_gate_rz(q, target, theta);
}

RING_FUNC(ring_quantum_mcu) {
    quantum_t *q = (quantum_t*)RING_API_GETCPOINTER(1, RING_VM_POINTER_QUANTUM);
    List *pControls = RING_API_GETLIST(2);
    int target = (int)RING_API_GETNUMBER(3);
    List *pMatrix = RING_API_GETLIST(4);
    int nControls = ring_list_getsize(pControls);
    int *aControls = (int*)malloc(nControls * sizeof(int));
    for(int x=0; x<nControls; x++) aControls[x] = (int)ring_list_getdouble(pControls, x+1);
    float m[8];
    for(int x=0; x<8; x++) m[x] = (float)ring_list_getdouble(pMatrix, x+1);
    internal_gate_mcu(q, aControls, nControls, target, m);
    free(aControls);
}

RING_FUNC(ring_quantum_fidelity) {
    quantum_t *q1 = (quantum_t*)RING_API_GETCPOINTER(1, RING_VM_POINTER_QUANTUM);
    quantum_t *q2 = (quantum_t*)RING_API_GETCPOINTER(2, RING_VM_POINTER_QUANTUM);
    RING_API_RETNUMBER(internal_get_fidelity(q1, q2));
}

RING_FUNC(ring_quantum_u_gate) {
    quantum_t *q = (quantum_t*)RING_API_GETCPOINTER(1, RING_VM_POINTER_QUANTUM);
    int target = (int)RING_API_GETNUMBER(2);
    float theta = (float)RING_API_GETNUMBER(3);
    float phi = (float)RING_API_GETNUMBER(4);
    float lambda = (float)RING_API_GETNUMBER(5);
    internal_gate_u(q, target, theta, phi, lambda);
}

RING_FUNC(ring_quantum_exp_x) {
    quantum_t *q = (quantum_t*)RING_API_GETCPOINTER(1, RING_VM_POINTER_QUANTUM);
    int target = (int)RING_API_GETNUMBER(2);
    RING_API_RETNUMBER(internal_get_expectation_x(q, target));
}

RING_FUNC(ring_quantum_exp_y) {
    quantum_t *q = (quantum_t*)RING_API_GETCPOINTER(1, RING_VM_POINTER_QUANTUM);
    int target = (int)RING_API_GETNUMBER(2);
    RING_API_RETNUMBER(internal_get_expectation_y(q, target));
}

RING_FUNC(ring_quantum_exp_z) {
    quantum_t *q = (quantum_t*)RING_API_GETCPOINTER(1, RING_VM_POINTER_QUANTUM);
    int target = (int)RING_API_GETNUMBER(2);
    RING_API_RETNUMBER(internal_get_expectation_z(q, target));
}

RING_FUNC(ring_quantum_exp_zz) {
    quantum_t *q = (quantum_t*)RING_API_GETCPOINTER(1, RING_VM_POINTER_QUANTUM);
    int qi = (int)RING_API_GETNUMBER(2);
    int qj = (int)RING_API_GETNUMBER(3);
    
    if (q == NULL) {
        RING_API_RETNUMBER(0);
        return;
    }
    
    RING_API_RETNUMBER(internal_get_expectation_zz(q, qi, qj));
}

RING_FUNC(ring_quantum_nqs_vmc_step) {
    if (RING_API_PARACOUNT < 6) return;
    nqs_t *nqs = (nqs_t*)RING_API_GETCPOINTER(1, "nqs_t");
    int nSamples = (int)RING_API_GETNUMBER(2);
    int steps = (int)RING_API_GETNUMBER(3);
    double *h = (double*)(size_t)RING_API_GETNUMBER(4);
    double *J = (double*)(size_t)RING_API_GETNUMBER(5);
    double *gW_re = (double*)(size_t)RING_API_GETNUMBER(6);
    double *gW_im = (double*)(size_t)RING_API_GETNUMBER(7);
    double *gb_re = (double*)(size_t)RING_API_GETNUMBER(8);
    double *ga_re = (double*)(size_t)RING_API_GETNUMBER(9);
    double fPenaltyWeight = RING_API_GETNUMBER(10);
    int nTarget = (int)RING_API_GETNUMBER(11);
    
    if (!nqs || !h || !J) return;
    
    nqs_cache_t cache;
    cache.theta_re = nqs->theta_re;
    cache.theta_im = nqs->theta_im;
    nqs_compute_theta(nqs, &cache);
    
    double total_energy = 0;
    int n = nqs->nqubits;
    int m = nqs->nhidden;
    
    // Reset Gradients
    memset(gW_re, 0, n * m * sizeof(double));
    if (gW_im) memset(gW_im, 0, n * m * sizeof(double));
    if (gb_re) memset(gb_re, 0, m * sizeof(double));
    if (ga_re) memset(ga_re, 0, n * sizeof(double));

    // Allocate memory to store configurations and energy results
    int8_t *configs = (int8_t*)malloc(nSamples * n * sizeof(int8_t));
    double *energies = (double*)malloc(nSamples * sizeof(double));
    
    double total_E = 0;
    double total_E2 = 0;

    // --- Pass 1: Sampling and Energy Computation ---
    for (int s = 0; s < nSamples; s++) {
        internal_nqs_sample(nqs, &cache, steps);
        
        // Store config
        memcpy(&configs[s * n], nqs->spins, n * sizeof(int8_t));
        
        double fE = internal_nqs_local_energy(nqs, h, J);
        int nActive = 0;
        for(int i=0; i<n; i++) if(nqs->spins[i] == 1) nActive++;
        double fPenalty = pow(nActive - nTarget, 2) * fPenaltyWeight;
        double fTotalE = fE + fPenalty;
        
        energies[s] = fTotalE;
        total_E += fTotalE;
        total_E2 += fTotalE * fTotalE;
    }
    
    double avgE = total_E / nSamples;
    double varE = (total_E2 / nSamples) - (avgE * avgE);
    double stdE = sqrt(varE > 0 ? varE : 1e-6) + 1e-6;

    // --- Pass 2: Hybrid Gradient Accumulation ---
    double inv_batch = 1.0 / nSamples;
    
    // Calculate global selection error for Direct Penalty Gradient
    // We compute the average nActive from the batch
    double sumActive = 0;
    for (int s = 0; s < nSamples; s++) {
        int nA = 0;
        for(int i=0; i<n; i++) if(configs[s * n + i] == 1) nA++;
        sumActive += nA;
    }
    double avgActive = sumActive / nSamples;
    double selectionError = avgActive - nTarget;
    
    for (int s = 0; s < nSamples; s++) {
        double advantage = (energies[s] - avgE) / stdE;
        
        memcpy(nqs->spins, &configs[s * n], n * sizeof(int8_t));
        nqs_compute_theta(nqs, &cache);

        int i_idx, j_idx;
        #pragma omp parallel for schedule(static) private(i_idx)
        for (j_idx = 0; j_idx < m; j_idx++) {
            double x = nqs->theta_re[j_idx];
            double y = nqs->theta_im[j_idx];
            double denom = cosh(2.0 * x) + cos(2.0 * y);
            if (denom < 1e-15) denom = 1e-15;
            double t_re = sinh(2.0 * x) / denom;
            
            for (i_idx = 0; i_idx < n; i_idx++) {
                double s_val = (double)nqs->spins[i_idx];
                
                // 1. Stochastic Gradient (REINFORCE)
                gW_re[i_idx * m + j_idx] += advantage * s_val * t_re * inv_batch;
                
                // 2. Hybrid Visible Bias Update
                if (ga_re) {
                    // Part A: Stochastic
                    ga_re[i_idx] += advantage * s_val * inv_batch;
                    
                    // Part B: Direct Penalty Gradient (Forces nActive -> nTarget)
                    // We only apply this once per asset, scaling it moderately
                    if (s == 0) {
                        ga_re[i_idx] += selectionError * 0.05; 
                    }
                }
            }
            if (gb_re) gb_re[j_idx] += advantage * t_re * inv_batch;
        }
    }
    
    free(configs);
    free(energies);
    
    RING_API_RETNUMBER(total_E); 
}

/* ==================================================================== */
/* --- Autoregressive Transformer NQS (ANQS) Implementation ----------- */
/* ==================================================================== */

void ring_quantum_anqs_free(void *pState, void *pPointer) {
    anqs_t *anqs = (anqs_t *)pPointer;
    if (anqs) {
        if (anqs->spins) free(anqs->spins);
        if (anqs->wq_re_f) free(anqs->wq_re_f); if (anqs->wq_im_f) free(anqs->wq_im_f);
        if (anqs->wk_re_f) free(anqs->wk_re_f); if (anqs->wk_im_f) free(anqs->wk_im_f);
        if (anqs->wv_re_f) free(anqs->wv_re_f); if (anqs->wv_im_f) free(anqs->wv_im_f);
        if (anqs->hamp_f) free(anqs->hamp_f);   if (anqs->hphase_f) free(anqs->hphase_f);
        if (anqs->spins_f) free(anqs->spins_f);
#ifdef USE_OPENCL
        if (gpu_ready && anqs->cl_W_q_re) {
            clReleaseMemObject(anqs->cl_W_q_re); clReleaseMemObject(anqs->cl_W_q_im);
            clReleaseMemObject(anqs->cl_W_k_re); clReleaseMemObject(anqs->cl_W_k_im);
            clReleaseMemObject(anqs->cl_W_v_re); clReleaseMemObject(anqs->cl_W_v_im);
            if (anqs->cl_Head_amp_W) clReleaseMemObject(anqs->cl_Head_amp_W); clReleaseMemObject(anqs->cl_Head_phase);
            clReleaseMemObject(anqs->cl_spins); clReleaseMemObject(anqs->cl_probs);
        }
#endif
        free(anqs);
    }
}

RING_FUNC(ring_quantum_anqs_init) {
    if (RING_API_PARACOUNT != 4) { RING_API_ERROR(RING_API_MISS4PARA); return; }
    int nqubits = (int)RING_API_GETNUMBER(1);
    int nheads = (int)RING_API_GETNUMBER(2);
    int ndim = (int)RING_API_GETNUMBER(3);
    int batch_size = (int)RING_API_GETNUMBER(4);
    
    anqs_t *anqs = (anqs_t*)calloc(1, sizeof(anqs_t));
    anqs->nqubits = nqubits;
    anqs->nheads = nheads;
    anqs->ndim = ndim;
    anqs->batch_size = batch_size;
    anqs->spins = (int8_t*)malloc(batch_size * nqubits * sizeof(int8_t));
    
    anqs->wq_re_f = (float*)malloc(nqubits * ndim * sizeof(float));
    anqs->wq_im_f = (float*)malloc(nqubits * ndim * sizeof(float));
    anqs->wk_re_f = (float*)malloc(nqubits * ndim * sizeof(float));
    anqs->wk_im_f = (float*)malloc(nqubits * ndim * sizeof(float));
    anqs->wv_re_f = (float*)malloc(nqubits * ndim * sizeof(float));
    anqs->wv_im_f = (float*)malloc(nqubits * ndim * sizeof(float));
    anqs->hamp_f = (float*)malloc(ndim * sizeof(float));
    anqs->hphase_f = (float*)malloc(ndim * sizeof(float));
    anqs->spins_f = (float*)malloc(batch_size * nqubits * sizeof(float));
    anqs->logit_bias = (double*)calloc(nqubits, sizeof(double)); 
    for(int i=0; i<nqubits; i++) anqs->logit_bias[i] = 0.0;
    anqs->temperature = 1.0;

#ifdef USE_OPENCL
    if (gpu_ready && user_gpu_enabled && nqubits >= gpu_threshold) {
        cl_int ret;
        anqs->cl_W_q_re = clCreateBuffer(clContext, CL_MEM_READ_WRITE, nqubits*ndim*sizeof(float), NULL, &ret);
        anqs->cl_W_k_re = clCreateBuffer(clContext, CL_MEM_READ_WRITE, nqubits*ndim*sizeof(float), NULL, &ret);
        anqs->cl_W_v_re = clCreateBuffer(clContext, CL_MEM_READ_WRITE, nqubits*ndim*sizeof(float), NULL, &ret);
        anqs->cl_Head_amp_W = clCreateBuffer(clContext, CL_MEM_READ_WRITE, ndim*sizeof(float), NULL, &ret);
        anqs->cl_logit_bias = clCreateBuffer(clContext, CL_MEM_READ_WRITE, nqubits*sizeof(float), NULL, &ret);
        anqs->cl_spins = clCreateBuffer(clContext, CL_MEM_READ_WRITE, batch_size*nqubits*sizeof(float), NULL, &ret);
        anqs->cl_probs = clCreateBuffer(clContext, CL_MEM_READ_WRITE, batch_size*nqubits*sizeof(float), NULL, &ret);
    }
#endif
    
    RING_API_RETMANAGEDCPOINTER(anqs, "anqs_t", ring_quantum_anqs_free);
}

RING_FUNC(ring_quantum_anqs_bind) {
    if (RING_API_PARACOUNT != 9) return;
    anqs_t *anqs = (anqs_t*)RING_API_GETCPOINTER(1, "anqs_t");
    anqs->W_q_re = (double*)(size_t)RING_API_GETNUMBER(2);
    anqs->W_q_im = (double*)(size_t)RING_API_GETNUMBER(3);
    anqs->W_k_re = (double*)(size_t)RING_API_GETNUMBER(4);
    anqs->W_k_im = (double*)(size_t)RING_API_GETNUMBER(5);
    anqs->W_v_re = (double*)(size_t)RING_API_GETNUMBER(6);
    anqs->W_v_im = (double*)(size_t)RING_API_GETNUMBER(7);
    anqs->Head_amp_W = (double*)(size_t)RING_API_GETNUMBER(8);
    anqs->Head_phase_W = (double*)(size_t)RING_API_GETNUMBER(9);
}

// Sampling epoch counter to ensure different seeds per VMC step
static unsigned int global_sampling_epoch = 0;

RING_FUNC(ring_quantum_anqs_sample) {
    anqs_t *anqs = (anqs_t*)RING_API_GETCPOINTER(1, "anqs_t");
    int b, q, d, i;
    global_sampling_epoch++;
    
#ifdef USE_OPENCL
    if (gpu_ready && user_gpu_enabled && anqs->nqubits >= gpu_threshold && clANQSAttentionKernel && clANQSHeadKernel) {
        // GPU Offloading: Matrix-Heavy Attention & Output Head Generation
        // 1. Cast `double` RingTensor bindings to `float` zero-copy structures 
        int total_w = anqs->nqubits * anqs->ndim;
        #pragma omp parallel for
        for (i = 0; i < total_w; i++) {
            anqs->wq_re_f[i] = (float)anqs->W_q_re[i];
            anqs->wk_re_f[i] = (float)anqs->W_k_re[i];
            anqs->wv_re_f[i] = (float)anqs->W_v_re[i];
        }
        for (i = 0; i < anqs->ndim; i++) {
            anqs->hamp_f[i] = (float)anqs->Head_amp_W[i];
            anqs->hphase_f[i] = (float)anqs->Head_phase_W[i];
        }
        
        // 2. Transfer safely to GPU
        clEnqueueWriteBuffer(clQueue, anqs->cl_W_q_re, CL_TRUE, 0, total_w * sizeof(float), anqs->wq_re_f, 0, NULL, NULL);
        clEnqueueWriteBuffer(clQueue, anqs->cl_W_k_re, CL_TRUE, 0, total_w * sizeof(float), anqs->wk_re_f, 0, NULL, NULL);
        clEnqueueWriteBuffer(clQueue, anqs->cl_W_v_re, CL_TRUE, 0, total_w * sizeof(float), anqs->wv_re_f, 0, NULL, NULL);
        clEnqueueWriteBuffer(clQueue, anqs->cl_Head_amp_W, CL_TRUE, 0, anqs->ndim * sizeof(float), anqs->hamp_f, 0, NULL, NULL);
        clEnqueueWriteBuffer(clQueue, anqs->cl_Head_phase, CL_TRUE, 0, anqs->ndim * sizeof(float), anqs->hphase_f, 0, NULL, NULL);
        
        // 3. Dispatch anqs_masked_attention
        clSetKernelArg(clANQSAttentionKernel, 0, sizeof(cl_mem), &anqs->cl_W_q_re);
        clSetKernelArg(clANQSAttentionKernel, 1, sizeof(cl_mem), &anqs->cl_W_k_re);
        clSetKernelArg(clANQSAttentionKernel, 2, sizeof(cl_mem), &anqs->cl_W_v_re);
        clSetKernelArg(clANQSAttentionKernel, 3, sizeof(cl_mem), &anqs->cl_spins); // Using cl_spins tempbuffer as Out
        clSetKernelArg(clANQSAttentionKernel, 4, sizeof(int), &anqs->batch_size);
        clSetKernelArg(clANQSAttentionKernel, 5, sizeof(int), &anqs->nqubits);
        clSetKernelArg(clANQSAttentionKernel, 6, sizeof(int), &anqs->ndim);
        
        size_t global_size_attn[2] = {(size_t)anqs->batch_size, (size_t)anqs->nqubits};
        clEnqueueNDRangeKernel(clQueue, clANQSAttentionKernel, 2, NULL, global_size_attn, NULL, 0, NULL, NULL);
        
        // 4. Dispatch anqs_complex_head
        clSetKernelArg(clANQSHeadKernel, 0, sizeof(cl_mem), &anqs->cl_spins);
        clSetKernelArg(clANQSHeadKernel, 1, sizeof(cl_mem), &anqs->cl_Head_amp_W);
        clSetKernelArg(clANQSHeadKernel, 2, sizeof(cl_mem), &anqs->cl_Head_phase);
        clSetKernelArg(clANQSHeadKernel, 3, sizeof(cl_mem), &anqs->cl_probs);
        clSetKernelArg(clANQSHeadKernel, 4, sizeof(cl_mem), &anqs->cl_spins); // Reuse cl_spins for Phase
        clSetKernelArg(clANQSHeadKernel, 5, sizeof(int), &anqs->batch_size);
        clSetKernelArg(clANQSHeadKernel, 6, sizeof(int), &anqs->nqubits);
        clSetKernelArg(clANQSHeadKernel, 7, sizeof(int), &anqs->ndim);
        
        clEnqueueNDRangeKernel(clQueue, clANQSHeadKernel, 2, NULL, global_size_attn, NULL, 0, NULL, NULL);
        
        // 5. Read Probabilities back (blocking call guarantees completion)
        clEnqueueReadBuffer(clQueue, anqs->cl_probs, CL_TRUE, 0, anqs->batch_size * anqs->nqubits * sizeof(float), anqs->spins_f, 0, NULL, NULL);
        
        // 6. Fast Random CPU evaluation using Thread-Local XorShift
        #pragma omp parallel private(q)
        {
            unsigned int seed = 12345 + omp_get_thread_num();
            #pragma omp for
            for(b=0; b<anqs->batch_size; b++) {
                for(q=0; q<anqs->nqubits; q++) {
                    float prob_up = anqs->spins_f[b*anqs->nqubits + q];
                    seed ^= seed << 13; seed ^= seed >> 17; seed ^= seed << 5;
                    float r = (float)(seed % 100000) / 100000.0f;
                    anqs->spins[b*anqs->nqubits + q] = (r < prob_up) ? 1 : -1;
                }
            }
        }
        return;
    }
#endif
    // Optimized Fallback: Matrix Computations on CPU (OpenMP)
    // Complexity: O(N^2 * D) instead of O(N^2 * B * D) -> 1024x speedup
    float *q_scores = (float*) calloc(anqs->nqubits, sizeof(float));
    float *q_out_val = (float*) calloc(anqs->ndim, sizeof(float));
    float *q_probs = (float*) malloc(anqs->nqubits * sizeof(float));

    for (q = 0; q < anqs->nqubits; q++) {
        float max_score = -1e9f;
        // 1. Attention Scores (Static Masked Attention)
        for (int k_idx = 0; k_idx <= q; k_idx++) {
            float s = 0;
            for (d = 0; d < anqs->ndim; d++) {
                s += (float)anqs->W_q_re[q * anqs->ndim + d] * (float)anqs->W_k_re[k_idx * anqs->ndim + d];
            }
            s /= (float)sqrt((float)anqs->ndim);
            q_scores[k_idx] = s;
            if (s > max_score) max_score = s;
        }

        // 2. Softmax & Aggregation
        float sum_exp = 0;
        for (int k_idx = 0; k_idx <= q; k_idx++) {
            q_scores[k_idx] = (float)exp(q_scores[k_idx] - max_score);
            sum_exp += q_scores[k_idx];
        }

        for (d = 0; d < anqs->ndim; d++) q_out_val[d] = 0;
        for (int k_idx = 0; k_idx <= q; k_idx++) {
            float weight = q_scores[k_idx] / sum_exp;
            for (d = 0; d < anqs->ndim; d++) {
                q_out_val[d] += weight * (float)anqs->W_v_re[k_idx * anqs->ndim + d];
            }
        }

        // 4. Probability for this qubit (with Temperature control)
        float amp = (float)anqs->logit_bias[q];
        for (d = 0; d < anqs->ndim; d++) {
            amp += q_out_val[d] * (float)anqs->Head_amp_W[d];
        }
        
        float prob_up = 1.0f / (1.0f + (float)exp(-amp / anqs->temperature));
        if (isnan(prob_up)) prob_up = 0.5f;
        q_probs[q] = prob_up;
    }

    // 5. Parallel Batch Sampling (O(B*N))
    #pragma omp parallel private(b, q, i)
    {
        unsigned int seed = 12345 + omp_get_thread_num() + (global_sampling_epoch * 31);
        #pragma omp for
        for (b = 0; b < anqs->batch_size; b++) {
            for (q = 0; q < anqs->nqubits; q++) {
                float prob_up = q_probs[q];
                anqs->spins_f[b * anqs->nqubits + q] = prob_up;
                
                seed ^= seed << 13; seed ^= seed >> 17; seed ^= seed << 5;
                float r = (float)(seed % 100000) / 100000.0f;
                anqs->spins[b * anqs->nqubits + q] = (r < prob_up) ? 1 : -1;
            }
        }
    }

    free(q_scores);
    free(q_out_val);
    free(q_probs);
}

RING_FUNC(ring_quantum_anqs_vmc_step) {
    if (RING_API_PARACOUNT < 10) return;
    anqs_t *anqs = (anqs_t*)RING_API_GETCPOINTER(1, "anqs_t");
    double *h = (double*)(size_t)RING_API_GETNUMBER(2);
    double *J = (double*)(size_t)RING_API_GETNUMBER(3);
    double *gW_q = (double*)(size_t)RING_API_GETNUMBER(4);
    double *gW_k = (double*)(size_t)RING_API_GETNUMBER(5);
    double *gW_v = (double*)(size_t)RING_API_GETNUMBER(6);
    double *gHead_amp = (double*)(size_t)RING_API_GETNUMBER(7);
    double *gHead_phase = (double*)(size_t)RING_API_GETNUMBER(8);
    double penalty = RING_API_GETNUMBER(9);
    int target_count = (int)RING_API_GETNUMBER(10);
    
    // =====================================================================
    // HYBRID VMC GRADIENT: REINFORCE (Physics) + Analytical (Constraint)
    // =====================================================================
    int n = anqs->nqubits;
    int D = anqs->ndim;
    double *eng_batch = (double*)malloc(anqs->batch_size * sizeof(double));
    
    // --- Phase 1: Compute Portfolio energy (Binary {0, 1} mapping) ---
    // Objective: E = x^T J x + h^T x  (where x is binary selector)
    double total_ising = 0;
    for (int b = 0; b < anqs->batch_size; b++) {
        double eng = 0;
        for (int i = 0; i < n; i++) {
            // Map spin {-1, 1} back to binary {0, 1}
            double xi = (anqs->spins[b*n + i] == 1) ? 1.0 : 0.0;
            if (xi == 0.0) continue;
            
            // Linear part: Return (-Ri * xi)
            eng += h[i] * xi;
            
            // Quadratic part: Risk (xi * Jii * xi + 2 * sum_{j>i} xi * Jij * xj)
            // Note: Since xi is binary, xi*xi = xi
            eng += J[i*n + i] * xi; 
            
            for (int j = i+1; j < n; j++) {
                double xj = (anqs->spins[b*n + j] == 1) ? 1.0 : 0.0;
                if (xj == 1.0) {
                    eng += 2.0 * J[i*n + j] * xi * xj;
                }
            }
        }
        eng_batch[b] = eng;
        total_ising += eng;
    }
    double avgIsing = total_ising / anqs->batch_size;
    
    // Ising Z-score normalization
    double varIsing = 0;
    for (int b = 0; b < anqs->batch_size; b++) {
        double diff = eng_batch[b] - avgIsing;
        varIsing += diff * diff;
    }
    double stdIsing = sqrt(varIsing / anqs->batch_size) + 1e-6;

    // --- Phase 2: Compute Expected Count from Probabilities (Analytical) ---
    // This is deterministic - no sampling noise!
    double expected_count = 0;
    for (int i = 0; i < n; i++) {
        // Average probability across batch for qubit i
        double avg_p = 0;
        for (int b = 0; b < anqs->batch_size; b++) {
            avg_p += anqs->spins_f[b*n + i];
        }
        expected_count += avg_p / anqs->batch_size;
    }
    double count_error = expected_count - target_count; // e.g. 250 - 15 = 235
    
    // --- Phase 3: Reset Gradients ---
    memset(gW_q, 0, n * D * sizeof(double));
    memset(gW_k, 0, n * D * sizeof(double));
    memset(gW_v, 0, n * D * sizeof(double));
    memset(gHead_amp, 0, D * sizeof(double));
    memset(gHead_phase, 0, D * sizeof(double));

    // --- Phase 4: Compute Gradients ---
    double scale = 1.0 / anqs->batch_size;
    
    int q;
    #pragma omp parallel for
    for (q = 0; q < n; q++) {
        // Average probability for this qubit
        double avg_pq = 0;
        int b;
        for (b = 0; b < anqs->batch_size; b++) {
            avg_pq += anqs->spins_f[b*n + q];
        }
        avg_pq /= anqs->batch_size;
        
        // ---- Part A: REINFORCE for Ising Energy (stochastic, weak but correct) ----
        double reinforce_grad = 0;
        for (b = 0; b < anqs->batch_size; b++) {
            double advantage = (eng_batch[b] - avgIsing) / stdIsing;
            if (advantage > 3.0) advantage = 3.0;
            if (advantage < -3.0) advantage = -3.0;
            
            int spin = anqs->spins[b*n + q];
            float prob_up = anqs->spins_f[b*n + q];
            reinforce_grad += advantage * ((spin == 1 ? 1.0 : 0.0) - prob_up) * scale;
        }
        
        // ---- Part B: Direct Analytical Penalty Gradient (deterministic, STRONG) ----
        // d/d(logit_q) [penalty * (E[count] - T)^2] = 2 * penalty * error * p_q * (1 - p_q)
        double sigmoid_deriv = avg_pq * (1.0 - avg_pq);  // derivative of sigmoid
        double penalty_grad = 2.0 * penalty * count_error * sigmoid_deriv;
        
        // ---- Combine: Physics + Constraint ----
        double total_grad = reinforce_grad + penalty_grad;
        
        // ---- Apply Chain Rule to all weight matrices ----
        int d;
        for (d = 0; d < D; d++) {
            gW_v[q*D + d] += total_grad * anqs->Head_amp_W[d];
            gW_q[q*D + d] += total_grad * 0.1;
            gW_k[q*D + d] += total_grad * 0.1;
            
            #pragma omp atomic
            gHead_amp[d] += total_grad * anqs->W_v_re[q*D + d] / n;
        }
        
        // ---- DIRECT SGD on logit_bias (bypasses Adam, instant convergence) ----
        // We use a much smaller learning rate and cap the total change to prevent sigmoid saturation.
        double bias_lr = 0.0001; 
        double update_val = bias_lr * (penalty_grad + reinforce_grad * 5.0);
        
        // Cap the update per step to prevent jumping straight to saturation
        if (update_val > 0.1) update_val = 0.1;
        if (update_val < -0.1) update_val = -0.1;
        
        anqs->logit_bias[q] -= update_val;
        
        // Safety: Keep bias in a reasonable range [-10, 10]
        if (anqs->logit_bias[q] > 10.0) anqs->logit_bias[q] = 10.0;
        if (anqs->logit_bias[q] < -10.0) anqs->logit_bias[q] = -10.0;
    }
    
    // Return full energy (Ising + Penalty) for logging
    double full_energy = avgIsing + penalty * count_error * count_error;
    
    free(eng_batch);
    RING_API_RETNUMBER(full_energy);
}

RING_FUNC(ring_quantum_anqs_set_temp) {
    if (RING_API_PARACOUNT < 2) return;
    anqs_t *anqs = (anqs_t*)RING_API_GETCPOINTER(1, "anqs_t");
    anqs->temperature = RING_API_GETNUMBER(2);
}

RING_FUNC(ring_quantum_anqs_save_bias) {
    if (RING_API_PARACOUNT < 2) return;
    anqs_t *anqs = (anqs_t*)RING_API_GETCPOINTER(1, "anqs_t");
    const char* cFile = RING_API_GETSTRING(2);
    FILE* f = fopen(cFile, "wb");
    if(f) {
        fwrite(anqs->logit_bias, sizeof(double), anqs->nqubits, f);
        fclose(f);
    }
}

RING_FUNC(ring_quantum_anqs_load_bias) {
    if (RING_API_PARACOUNT < 2) return;
    anqs_t *anqs = (anqs_t*)RING_API_GETCPOINTER(1, "anqs_t");
    const char* cFile = RING_API_GETSTRING(2);
    FILE* f = fopen(cFile, "rb");
    if(f) {
        fread(anqs->logit_bias, sizeof(double), anqs->nqubits, f);
        fclose(f);
    }
}

RING_FUNC(ring_quantum_anqs_get_spins) {
    anqs_t *anqs = (anqs_t*)RING_API_GETCPOINTER(1, "anqs_t");
    List *pList = RING_API_NEWLIST;
    for(int b=0; b<anqs->batch_size; b++) {
        List *pSubList = ring_list_newlist_gc(NULL, pList);
        for(int q=0; q<anqs->nqubits; q++) {
            ring_list_adddouble_gc(NULL, pSubList, (double)anqs->spins[b*anqs->nqubits + q]);
        }
    }
    RING_API_RETLIST(pList);
}

RING_FUNC(ring_quantum_anqs_jacobian) {
    if (RING_API_PARACOUNT != 2) return;
    anqs_t *anqs = (anqs_t*)RING_API_GETCPOINTER(1, "anqs_t");
    double *O = (double*)(size_t)RING_API_GETNUMBER(2); // Jacobian matrix [batch_size * n_params]
    
    int B = anqs->batch_size;
    int N = anqs->nqubits;
    int D = anqs->ndim;
    int n_params = 3 * N * D + D;
    
    // 1. Compute Raw Jacobian
    memset(O, 0, B * n_params * sizeof(double));
    int b, q, d;
    #pragma omp parallel for private(q, d)
    for (b = 0; b < B; b++) {
        for (q = 0; q < N; q++) {
            int spin = anqs->spins[b*N + q];
            float prob_up = anqs->spins_f[b*N + q]; // Probability P(s=1)
            
            // Log-derivative of wavefunction: 0.5 * (s_binary - prob_up)
            double grad_hq = 0.5 * ((spin == 1 ? 1.0 : 0.0) - prob_up);
            
            for (d = 0; d < D; d++) {
                // Mapping: Block 0: W_q, Block 1: W_k, Block 2: W_v, Block 3: Head
                O[b*n_params + (q*D + d)] += grad_hq * anqs->W_q_re[q*D + d] * 0.1;
                O[b*n_params + (N*D + q*D + d)] += grad_hq * anqs->W_k_re[q*D + d] * 0.1;
                O[b*n_params + (2*N*D + q*D + d)] += grad_hq * anqs->W_v_re[q*D + d] / N;
                O[b*n_params + (3*N*D + d)] += grad_hq * anqs->Head_amp_W[d];
            }
        }
    }
    
    // 2. Centering (Subtracting Batch Mean for stability - Skip if Batch=1)
    if (B > 1) {
        double *mean_O = (double*)calloc(n_params, sizeof(double));
        int j, i2;
        #pragma omp parallel for private(i2)
        for (j = 0; j < n_params; j++) {
            double sum = 0;
            for (i2 = 0; i2 < B; i2++) sum += O[i2*n_params + j];
            mean_O[j] = sum / B;
        }
        
        #pragma omp parallel for private(j)
        for (b = 0; b < B; b++) {
            for (j = 0; j < n_params; j++) {
                O[b*n_params + j] -= mean_O[j];
            }
        }
        free(mean_O);
    }
}

RING_FUNC(ring_quantum_anqs_hebbian_backprop) {
    if (RING_API_PARACOUNT != 5) return;
    anqs_t *anqs = (anqs_t*)RING_API_GETCPOINTER(1, "anqs_t");
    double *input = (double*)(size_t)RING_API_GETNUMBER(2);
    double *target = (double*)(size_t)RING_API_GETNUMBER(3);
    double *pred = (double*)(size_t)RING_API_GETNUMBER(4);
    double lr = RING_API_GETNUMBER(5);
    
    int N = anqs->nqubits;
    int D = anqs->ndim;
    
    int q, d;
    #pragma omp parallel for private(d)
    for (q = 0; q < N; q++) {
        double w = input[q % D];
        if (fabs(w) > 0.000001) {
            for (d = 0; d < D; d++) {
                double err = target[d] - pred[d];
                // Direct Hebbian Association
                anqs->W_q_re[q * D + d] += lr * err * w;
            }
        }
    }
    
    #pragma omp parallel for
    for (d = 0; d < D; d++) {
        anqs->Head_amp_W[d] += lr * (target[d] - pred[d]);
    }
}

RING_FUNC(ring_quantum_anqs_batch_learn) {
    if (RING_API_PARACOUNT != 5) {
        RING_API_ERROR("batch_learn requires 5 params: ANQS, InputsPtr, TargetsPtr, BatchSize, LR");
        return;
    }
    anqs_t *anqs = (anqs_t*)RING_API_GETCPOINTER(1, "anqs_t");
    double *batch_inputs = (double*)(size_t)RING_API_GETNUMBER(2);  // Zero-Copy Pointer
    double *batch_targets = (double*)(size_t)RING_API_GETNUMBER(3); // Zero-Copy Pointer
    int batch_size = (int)RING_API_GETNUMBER(4);
    double lr = RING_API_GETNUMBER(5);

    if (!anqs || !batch_inputs || !batch_targets) return;

    int N = anqs->nqubits;
    int D = anqs->ndim;
    int d, b, q;
    #pragma omp parallel for schedule(static)
    for (d = 0; d < D; d++) {
        for (b = 0; b < batch_size; b++) {
            double *input_ptr = &batch_inputs[b * D];
            double *target_ptr = &batch_targets[b * D];
            
            // Forward Pass سريع (Dot Product)
            double pred = 0;
            for (q = 0; q < N; q++) {
                pred += input_ptr[q % D] * anqs->W_q_re[q * D + d];
            }

            double error = target_ptr[d] - pred;

            // Hebbian Update (Zero-Copy)
            if (fabs(error) > 0.000001) {
                for (int q = 0; q < N; q++) {
                    anqs->W_q_re[q * D + d] += (lr * error * input_ptr[q % D]) / batch_size;
                }
            }
        }
    }
}

RING_FUNC(ring_quantum_anqs_apply_update) {
    if (RING_API_PARACOUNT != 3) return;
    anqs_t *anqs = (anqs_t*)RING_API_GETCPOINTER(1, "anqs_t");
    double *update = (double*)(size_t)RING_API_GETNUMBER(2); // Update vector [n_params]
    double lr = RING_API_GETNUMBER(3);
    
    int N = anqs->nqubits;
    int D = anqs->ndim;
    
    int i, d;
    #pragma omp parallel for private(i)
    for (i = 0; i < N * D; i++) {
        anqs->W_q_re[i] += lr * update[i];
        anqs->W_k_re[i] += lr * update[N*D + i];
        anqs->W_v_re[i] += lr * update[2*N*D + i];
    }
    
    for (d = 0; d < D; d++) {
        anqs->Head_amp_W[d] += lr * update[3*N*D + d];
    }
}

RING_FUNC(ring_quantum_anqs_load_layer) {
    if (RING_API_PARACOUNT != 2) return;
    anqs_t *anqs = (anqs_t*)RING_API_GETCPOINTER(1, "anqs_t");
    List *pList = RING_API_GETLIST(2);
    
    int N = anqs->nqubits;
    int D = anqs->ndim;
    
    // Efficiently load weights from Ring List into C Tensors
    for (int q = 0; q < N; q++) {
        List *pRow = ring_list_getlist(pList, q + 1);
        for (int d = 0; d < D; d++) {
            double val = ring_list_getdouble(pRow, d + 1);
            anqs->W_q_re[q*D + d] = val;
            // Force diversity to restore attention sanity in matrix-free mode
            anqs->W_k_re[q*D + d] = (float)val * 0.957f;
        }
    }
}

RING_FUNC(ring_quantum_anqs_inference) {
    if (RING_API_PARACOUNT != 7) return;
    anqs_t *anqs = (anqs_t*)RING_API_GETCPOINTER(1, "anqs_t");
    double *X = (double*)(size_t)RING_API_GETNUMBER(2);
    double *Y = (double*)(size_t)RING_API_GETNUMBER(3);
    int out_features = (int)RING_API_GETNUMBER(4);
    int in_features = (int)RING_API_GETNUMBER(5);
    
    int N = anqs->nqubits;
    int D = anqs->ndim;
    
    if (anqs->W_q_re == NULL || X == NULL || Y == NULL) {
    printf("[RingQuantum] CRITICAL: Null Pointer in Inference!\n");
    return;
    }
    // Clear Output Y (Safe Wipe)
    memset(Y, 0, out_features * sizeof(double));
    
    int d, q;
    double local_mean = 0;
    
    #pragma omp parallel for private(q) reduction(+:local_mean) schedule(static)
    for (d = 0; d < D; d++) {
        double val = anqs->Head_amp_W[d] * 0.05; 
        for (q = 0; q < N; q++) {
            val += X[q] * anqs->W_q_re[q * D + d];
        }
        Y[d] = val; 
        local_mean += val;
    }
    
    local_mean /= D; // الضجيج العام للمصفوفة

    // --- Contrastive Normalization (Zero-Centering) ---
    // طرح المتوسط يزيل "الصدى" المتكرر ويُبقي فقط إشارة الكلمة المطلوبة
    double var = 0;
    for (d = 0; d < D; d++) {
        Y[d] -= local_mean;
        var += Y[d] * Y[d];
    }
    
    double std = sqrt(var / D + 1e-9);
    for (d = 0; d < D; d++) Y[d] /= std;
}

RING_FUNC(ring_quantum_batch_quantize) {
    double *src_buffer = (double*)(size_t)RING_API_GETNUMBER(1);
    signed char *dest_buffer = (signed char*)(size_t)RING_API_GETNUMBER(2);
    int vocab_size = (int)RING_API_GETNUMBER(3);
    int dim = (int)RING_API_GETNUMBER(4);
    int i,d;
    #pragma omp parallel for private(d)
    for (i = 0; i < vocab_size; i++) {
        for (d = 0; d < dim; d++) {
            double val = src_buffer[(size_t)i * dim + d] * 127.0;
            if (val > 127.0) val = 127.0;
            if (val < -127.0) val = -127.0;
            dest_buffer[(size_t)i * dim + d] = (signed char)val;
        }
    }
}

/*RING_FUNC(ring_quantum_anqs_inference) {
    if (RING_API_PARACOUNT != 7) return;
    anqs_t *anqs = (anqs_t*)RING_API_GETCPOINTER(1, "anqs_t");
    double *X = (double*)(size_t)RING_API_GETNUMBER(2);
    double *Y = (double*)(size_t)RING_API_GETNUMBER(3);
    int out_features = (int)RING_API_GETNUMBER(4); // 16384
    int in_features = (int)RING_API_GETNUMBER(5);  // الحجم الحقيقي للمدخل
    
    if (!anqs || !X || !Y) return;

    int D = anqs->ndim;
    int N_limit = (in_features < anqs->nqubits) ? in_features : anqs->nqubits;
    int d,q,i;
    #pragma omp parallel for private(q) schedule(static)
    for (d = 0; d < out_features; d++) {
       double val = anqs->Head_amp_W[d]; // القوة الكاملة لرأس الانتباه
       for (q = 0; q < N_limit; q++) {
           val += X[q] * anqs->W_q_re[q * D + d] * 2.0; // مضاعفة أثر الأوزان
       }
       Y[d] = val;
    }
    
    // Normalization سريع جداً في C
    double mean = 0;
    for(i=0; i<out_features; i++) mean += Y[i];
    mean /= out_features;
    for(i=0; i<out_features; i++) Y[i] -= mean;
}*/

RING_FUNC(ring_quantum_holographic_bind) {
    double *context = (double*)(size_t)RING_API_GETNUMBER(1);
    double *spectral_cache = (double*)(size_t)RING_API_GETNUMBER(2);
    List *aWindow = RING_API_GETLIST(3);
    int nDim = (int)RING_API_GETNUMBER(4);
    
    int nLen = ring_list_getsize(aWindow);
    for (int k = 1; k <= nLen; k++) {
        int nID = (int)ring_list_getdouble(aWindow, k);
        double weight = (double)k / nLen;
        double *word_wave = &spectral_cache[(size_t)(nID-1) * nDim];
        int d;
        #pragma omp parallel for
        for (d = 0; d < nDim; d++) {
            context[d] += word_wave[d] * weight;
        }
    }
}

RING_FUNC(ring_quantum_find_best) {
    if (RING_API_PARACOUNT != 5) return;
    double *result_wave = (double*)(size_t)RING_API_GETNUMBER(1);
    double *spectral_cache = (double*)(size_t)RING_API_GETNUMBER(2);
    int vocab_size = (int)RING_API_GETNUMBER(3);
    double *out_ids = (double*)(size_t)RING_API_GETNUMBER(4);
    double *used_ids = (double*)(size_t)RING_API_GETNUMBER(5); 
    
    int D = current_dimension; // Updated to match Sovereign Architecture
    double top_scores[5] = {-5.0, -5.0, -5.0, -5.0, -5.0};
    int top_ids[5] = {0, 0, 0, 0, 0};

    double res_norm = 0;
    for (int d = 0; d < D; d++) res_norm += result_wave[d] * result_wave[d];
    res_norm = sqrt(res_norm + 1e-9);

    for (int i = 1; i <= vocab_size; i++) {
        double dot = 0;
        double target_norm = 0;
        double *target_wave = &spectral_cache[(size_t)(i-1) * D];
        
        for (int d = 0; d < D; d++) {
            dot += result_wave[d] * target_wave[d];
            target_norm += target_wave[d] * target_wave[d];
        }
        target_norm = sqrt(target_norm + 1e-9);
        double cosine = dot / (res_norm * target_norm);
        
        // Ultra-Fast Blackout Mask (O(1) Penalty)
        // Adjust index (i-1) to match Ring's internal vector storage (0-based)
        if (used_ids[i-1] > 0.1) {
            cosine = -2.0; // Perfect blackout
        }
        
        for (int k = 0; k < 5; k++) {
            if (cosine > top_scores[k]) {
                for (int m = 4; m > k; m--) {
                    top_scores[m] = top_scores[m-1];
                    top_ids[m] = top_ids[m-1];
                }
                top_scores[k] = cosine;
                top_ids[k] = i;
                break;
            }
        }
    }
    
    for (int k = 0; k < 5; k++) out_ids[k] = (double)top_ids[k];
}

RING_FUNC(ring_quantum_find_best_int8) {
    if (RING_API_PARACOUNT != 5) return;
    signed char *result_wave = (signed char*)(size_t)RING_API_GETNUMBER(1);
    signed char *spectral_cache = (signed char*)(size_t)RING_API_GETNUMBER(2);
    int vocab_size = (int)RING_API_GETNUMBER(3);
    double *out_ids = (double*)(size_t)RING_API_GETNUMBER(4);
    double *used_ids = (double*)(size_t)RING_API_GETNUMBER(5); 
    
    int D = current_dimension; 
    int top_scores[5] = {-20000000, -20000000, -20000000, -20000000, -20000000};
    int top_ids[5] = {0, 0, 0, 0, 0};

    for (int i = 1; i <= vocab_size; i++) {
        int dot = 0;
        signed char *target_wave = &spectral_cache[(size_t)(i-1) * D];
        
        // Unrolled loop for Maximum SIMD potential
        for (int d = 0; d < D; d++) {
            dot += (int)result_wave[d] * (int)target_wave[d];
        }
        
        // Repetition Penalty (Blackout)
        if (used_ids[i-1] > 0.1) {
            dot = -30000000;
        }
        
        for (int k = 0; k < 5; k++) {
            if (dot > top_scores[k]) {
                for (int m = 4; m > k; m--) {
                    top_scores[m] = top_scores[m-1];
                    top_ids[m] = top_ids[m-1];
                }
                top_scores[k] = dot;
                top_ids[k] = i;
                break;
            }
        }
    }
    
    for (int k = 0; k < 5; k++) out_ids[k] = (double)top_ids[k];
}

RING_FUNC(ring_quantum_quantize) {
    if (RING_API_PARACOUNT != 3) return;
    double *src = (double*)(size_t)RING_API_GETNUMBER(1);
    signed char *dest = (signed char*)(size_t)RING_API_GETNUMBER(2);
    int size = (int)RING_API_GETNUMBER(3);
    
    for (int i = 0; i < size; i++) {
        double val = src[i] * 127.0;
        if (val > 127.0) val = 127.0;
        if (val < -127.0) val = -127.0;
        dest[i] = (signed char)val;
    }
}

RING_FUNC(ring_quantum_set_dimension) {
    if (RING_API_PARACOUNT == 1) {
        current_dimension = (int)RING_API_GETNUMBER(1);
    }
}

RING_FUNC(ring_quantum_set_gpu_threshold) {
    if (RING_API_PARACOUNT == 1) {
        gpu_threshold = (int)RING_API_GETNUMBER(1);
    }
}

RING_FUNC(ring_quantum_enable_gpu) {
    if (RING_API_PARACOUNT == 1) {
        user_gpu_enabled = (int)RING_API_GETNUMBER(1);
    }
}

RING_FUNC(ring_quantum_fast_fingerprint) {
    if (RING_API_PARACOUNT != 4) return;

    double *vec = (double*)(size_t)RING_API_GETNUMBER(1);
    const char *cToken = RING_API_GETSTRING(2);
    int nDim = (int)RING_API_GETNUMBER(3);
    int nActive = (int)RING_API_GETNUMBER(4);

    if (!vec || !cToken || nDim <= 0) return;

    // 1. القضاء على الضجيج (CRITICAL): تصغير المتجه بالكامل أولاً
    // هذا يضمن أن الـ 16K بُعداً نظيفة تماماً قبل وضع البصمة
    for (int j = 0; j < nDim; j++) vec[j] = 0.0;

    // 2. توليد بذرة الهاش (DJB2)
    unsigned int seed = 5381;
    for (int i = 0; cToken[i]; i++) {
        seed = ((seed << 5) + seed) + cToken[i];
    }

    // 3. توزيع النقاط النشطة باستخدام XorShift لضمان التشتت العالي (High Entropy)
    // هذا يمنع تداخل الكلمات ويضمن "رنيناً" نقياً
    unsigned int state = seed;
    for (int i = 1; i <= nActive; i++) {
        // خوارزمية XorShift سريعة جداً لتوليد مواقع شبه عشوائية ثابتة لكل كلمة
        state ^= state << 13;
        state ^= state >> 17;
        state ^= state << 5;

        int nPos = state % nDim;
        
        // استخدام قيم متعامدة (+1 أو -1)
        double nVal = (i % 2 == 0) ? 1.0 : -1.0;
        
        // وضع البصمة في الفضاء النظيف
        vec[nPos] = nVal;
    }
}

RING_LIBINIT {
    RING_API_REGISTER("quantum_init", ring_quantum_init);
    RING_API_REGISTER("quantum_fft", ring_quantum_fft);
    RING_API_REGISTER("quantum_ifft", ring_quantum_ifft);
    RING_API_REGISTER("quantum_find_best", ring_quantum_find_best);
    RING_API_REGISTER("quantum_h", ring_quantum_h);
    RING_API_REGISTER("quantum_x", ring_quantum_x);
    RING_API_REGISTER("quantum_cnot", ring_quantum_cnot);
    RING_API_REGISTER("quantum_get_state", ring_quantum_get_state);
    RING_API_REGISTER("quantum_unitary", ring_quantum_unitary);
    RING_API_REGISTER("quantum_get_probability", ring_quantum_get_probability);
    RING_API_REGISTER("quantum_measure", ring_quantum_measure);
    RING_API_REGISTER("quantum_phase", ring_quantum_phase);
    RING_API_REGISTER("quantum_free_mem", ring_quantum_free_mem);
    RING_API_REGISTER("quantum_swap", ring_quantum_swap);
    RING_API_REGISTER("quantum_toffoli", ring_quantum_toffoli);
    RING_API_REGISTER("quantum_get_probabilities", ring_quantum_get_probabilities);
    RING_API_REGISTER("quantum_get_cores", ring_quantum_get_cores);
    RING_API_REGISTER("quantum_set_threads", ring_quantum_set_threads);
    RING_API_REGISTER("quantum_controlled_unitary", ring_quantum_controlled_unitary);
    RING_API_REGISTER("quantum_ry", ring_quantum_ry);
    RING_API_REGISTER("quantum_rx", ring_quantum_rx);
    RING_API_REGISTER("quantum_rz", ring_quantum_rz);
    RING_API_REGISTER("quantum_mcu", ring_quantum_mcu);
    RING_API_REGISTER("quantum_fidelity", ring_quantum_fidelity);
    RING_API_REGISTER("quantum_u_gate", ring_quantum_u_gate);
    RING_API_REGISTER("quantum_exp_x", ring_quantum_exp_x);
    RING_API_REGISTER("quantum_exp_y", ring_quantum_exp_y);
    RING_API_REGISTER("quantum_exp_z", ring_quantum_exp_z);
    RING_API_REGISTER("quantum_exp_zz", ring_quantum_exp_zz); 
    
    RING_API_REGISTER("quantum_nqs_init", ring_quantum_nqs_init);
    RING_API_REGISTER("quantum_nqs_bind", ring_quantum_nqs_bind);
    RING_API_REGISTER("quantum_nqs_sample", ring_quantum_nqs_sample);
    RING_API_REGISTER("quantum_nqs_get_spins", ring_quantum_nqs_get_spins);
    RING_API_REGISTER("quantum_nqs_grads", ring_quantum_nqs_grads);
    RING_API_REGISTER("quantum_nqs_energy", ring_quantum_nqs_energy);
    RING_API_REGISTER("quantum_nqs_vmc_step", ring_quantum_nqs_vmc_step);
    
    // ANQS Functions
    RING_API_REGISTER("quantum_anqs_init", ring_quantum_anqs_init);
    RING_API_REGISTER("quantum_anqs_bind", ring_quantum_anqs_bind);
    RING_API_REGISTER("quantum_anqs_sample", ring_quantum_anqs_sample);
    RING_API_REGISTER("quantum_anqs_vmc_step", ring_quantum_anqs_vmc_step);
    RING_API_REGISTER("quantum_anqs_get_spins", ring_quantum_anqs_get_spins);
    RING_API_REGISTER("quantum_anqs_jacobian", ring_quantum_anqs_jacobian);
    RING_API_REGISTER("quantum_anqs_apply_update", ring_quantum_anqs_apply_update);
    RING_API_REGISTER("quantum_anqs_hebbian_backprop", ring_quantum_anqs_hebbian_backprop);
    RING_API_REGISTER("quantum_anqs_batch_learn", ring_quantum_anqs_batch_learn);
    RING_API_REGISTER("quantum_anqs_inference", ring_quantum_anqs_inference);
    RING_API_REGISTER("quantum_anqs_load_layer", ring_quantum_anqs_load_layer);
    RING_API_REGISTER("quantum_anqs_set_temp", ring_quantum_anqs_set_temp);
    RING_API_REGISTER("quantum_anqs_save_bias", ring_quantum_anqs_save_bias);
    RING_API_REGISTER("quantum_anqs_load_bias", ring_quantum_anqs_load_bias);
    
    // Core Hardware Controls
    RING_API_REGISTER("quantum_set_gpu_threshold", ring_quantum_set_gpu_threshold);
    RING_API_REGISTER("quantum_enable_gpu", ring_quantum_enable_gpu);

    // Tokenizer Functions
    RING_API_REGISTER("quantum_find_best_int8", ring_quantum_find_best_int8);
    RING_API_REGISTER("quantum_quantize", ring_quantum_quantize);

    // Dimension Control
    RING_API_REGISTER("quantum_set_dimension", ring_quantum_set_dimension);
    RING_API_REGISTER("quantum_fast_fingerprint", ring_quantum_fast_fingerprint);
    RING_API_REGISTER("quantum_holographic_bind", ring_quantum_holographic_bind);
    RING_API_REGISTER("quantum_batch_quantize", ring_quantum_batch_quantize);


    #ifdef USE_OPENCL
    init_opencl();
    #endif
}