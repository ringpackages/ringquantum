/*
** RingQuantum Showcase - Quantum Fourier Transform (QFT)
*/

load "ringquantum.ring"

func main
    nQ = 4 
    q  = new QuantumCircuit(nQ)

    see "Preparing state |3> (binary 0011)..." + nl
    q.X(0) q.X(1)
    
    see "Applying QFT (Now built-in function)..." + nl
    q.QFT(nQ)
    
    see "Applying IQFT to return to normal..." + nl
    q.IQFT(nQ)
    
    see "Measuring Result: "
    res = 0
    for i = 0 to nQ-1
        if q.Measure(i) res += pow(2, i) ok
    next
    see "" + res + nl
    
    if res = 3
        see "SUCCESS: QFT/IQFT Verified Perfectly." + nl
    ok