/*
** RingQuantum - Grover's Algorithm
** Grover's Algorithm for Quantum Search
** This file demonstrates the engine's ability to perform searches in large probability spaces
*/

load "ringquantum.ring"

func main
    nQ = 6          # 6 Qubits = 64 states
    target = 42     # The target is state number 42
    
    see "============================================" + nl
    see "      Grover's Quantum Search Algorithm" + nl
    see "============================================" + nl
    see "Finding target state: |" + target + "> in a space of " + (2^nQ) + " states..." + nl
    
    q = new QuantumCircuit(nQ)
    
    # 1. Superposition
    for i = 0 to nQ-1 q.H(i) next
    
    # Optimal number of iterations (sqrt(N) * pi/4)
    # For 6 qubits (64 states), the optimal iteration is about 6 times
    iterations = 6
    
    for iter = 1 to iterations
        see "Iteration " + iter + " processing..." + nl
        
        # --- Oracle ---
        # Flips the phase of the target state only
        apply_oracle(q, target, nQ)
        
        # --- Diffusion (Reflection about average) ---
        apply_diffusion(q, nQ)
    next
    
    see nl + "Calculations Complete. Retrieving probabilities..." + nl
    probs = q.GetProbabilities()
    
    # Finding the highest probability
    max_p = 0
    best_s = 0
    for i = 1 to len(probs)
        if probs[i] > max_p
            max_p = probs[i]
            best_s = i - 1
        ok
    next
    
    see "--------------------------------------------" + nl
    see "Result: Found |" + best_s + "> with Prob: " + (max_p * 100) + "%" + nl
    if best_s = target
        see "Status: SUCCESS! Target discovered." + nl
    else
        see "Status: FAILED. Check algorithm parameters." + nl
    ok
    see "--------------------------------------------" + nl

# The Oracle function: Flips the phase of the target state
func apply_oracle q, target, nQ
    # 1. Initialize bits to match the target state with the controlled gate
    for i = 0 to nQ-1
        if !((target >> i) & 1)
            q.X(i)
        ok
    next
    
    # 2. Multi-Controlled Z gate
    # Z matrix
    m_z = [1,0,0,0,0,0,-1,0]
    controls = []
    for c = 0 to nQ-2 add(controls, c) next
    q.MCU(controls, nQ-1, m_z)
    
    # 3. إعادة البتات لحالتها الأصلية
    for i = 0 to nQ-1
        if !((target >> i) & 1)
            q.X(i)
        ok
    next

# The Diffusion function: Reflection about average to increase the probability of the target
func apply_diffusion q, nQ
    for i = 0 to nQ-1
        q.H(i)
        q.X(i)
    next
    
    # Multi-Controlled Z
    m_z = [1,0,0,0,0,0,-1,0]
    controls = []
    for c = 0 to nQ-2 add(controls, c) next
    q.MCU(controls, nQ-1, m_z)
    
    for i = 0 to nQ-1
        q.X(i)
        q.H(i)
    next