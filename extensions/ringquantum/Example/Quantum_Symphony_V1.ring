load "guilib.ring"
load "ringquantum.ring"
load "alqalam.ring"
load "ringtensor.ring"

# Quantitative protein settings
cSeq = "HPHPPHHHPHPPH" # H: hydrophobic, P: polar
nLen = len(cSeq)
nQ   = (nLen - 1) * 2 # Each link needs 2 qubits for direction
oApp = null
oSim = null

func main
    oApp = new qApp {
        oWin = new qWidget() {
            oSim = new QuantumProteinSimulator("oSim")
        }
        exec()
    }

class QuantumProteinSimulator from qWidget
    oPos = []   #Coordinates resulting from quantitative measurement
    oTimer oPixmap oPainter oLabel
    fEnergy = 0.0
    nEpoch  = 0
    oObjectName
    # Adam and quantitative parameters
    W = tensor_init(1, 2) # [gamma, beta]
    Grad = tensor_init(1, 2)
    M = tensor_init(1, 2) V = tensor_init(1, 2)

    func init ObjectName
        oObjectName = ObjectName
        super.init()
        setupUI()
        # Initialize Adam with the initial state
        tensor_set(W, 1, 1, 0.5) tensor_set(W, 1, 2, 0.5)
        
        oTimer = new QTimer(this) {
            setInterval(100)
            setTimeOutEvent(this.oObjectName + ".quantumStep()")
            start()
        }
        return self

    func setupUI
        setWindowTitle("Leviathan Quantum Engine: Protein Folder")
        resize(1200, 650)
        oLabel = new QLabel(this) { setGeometry(0, 0, 1200, 650) }
        oPixmap = new QPixmap2(1200, 650)
        oPainter = new QPainter()
        show()

    func quantumStep
        nEpoch++
        g = tensor_get(W, 1, 1)
        b = tensor_get(W, 1, 2)

        # 1.Running the quantum simulator (GPU Turbo) to find the power distribution
        q = new QuantumCircuit(nQ)
        ApplyFoldingCircuit(q, g, b)
        
        # 2. Measuring the result (Collapse to a specific fold)
        cResult = ""
        for i = 1 to nQ cResult += q.Measure(i) next
        
        # 3. Translating the quantum code into 3D coordinates
        DecodeFold(cResult)
        
        # 4. Calculating the physical energy of the resulting shape
        fEnergy = CalculateLatticeEnergy()
        
        # 5. Updating Adam (to improve folding in the next step)
        # We simplify the gradient here for display
        tensor_set(Grad, 1, 1, fEnergy * 0.01)
        tensor_set(Grad, 1, 2, fEnergy * 0.01)
        tensor_update_adam(W, Grad, M, V, 0.01, 0.9, 0.999, 0.00000001, nEpoch, 0.0)
        
        drawFrame()

    func ApplyFoldingCircuit q, g, b
        # Initial superposition: all possible shapes exist together
        for i = 1 to nQ q.H(i) next
        
        # Interaction layer (Cost Layer): encoding hydrophobicity
        for i = 1 to nLen
            if cSeq[i] = "H"
                q.RZ(i*2, g) # Phase shift based on amino acid type
            ok
        next
        
        # Mixer layer: Allowing the protein to "change its mind"
        for i = 1 to nQ q.RX(i, 2.0 * b) next

    func DecodeFold cBitString
        # Converting 00, 01, 10, 11 to X, Y directions
        oPos = [[0,0,0]] # Starting from the center
        curX = 0 curY = 0
        for i = 1 to len(cBitString) step 2
            move = substr(cBitString, i, 2)
            if move = "00" curY++    # Up
            but move = "01" curY--   # Down
            but move = "10" curX++   # Right
            else curX--              # Left
            ok
            add(oPos, [curX * 30, curY * 30, 0])
        next

    func CalculateLatticeEnergy
        # Simple energy: gives a negative value (stability) if H's get closer
        e = 0.0
        for i = 1 to len(oPos)
            for j = i+2 to len(oPos)
                dist = sqrt( (oPos[i][1]-oPos[j][1])**2 + (oPos[i][2]-oPos[j][2])**2 )
                if dist < 35 # Adjacent in the lattice
                    if cSeq[i] = "H" and cSeq[j] = "H" e -= 1.0 ok # stability
                ok
            next
        next
        return e

    func drawFrame
        oPixmap.fill(new QColor() { setRGB(1, 4, 12, 255) })
        oPainter.begin(oPixmap)
        
        # Drawing the bonds (Protein skeleton)
        oPainter.setPen(new QPen() { setColor(new QColor() { setRGB(255, 255, 255, 150) }) setWidth(3) })
        for i = 1 to len(oPos)
            oPainter.drawLine(600+oPos[i][1], 325+oPos[i][2], 600+oPos[i][1], 325+oPos[i][2])
        next
        
        # Drawing amino acids
        for i = 1 to len(oPos)
            color = iif(cSeq[i]="H", [0, 219, 255], [255, 0, 180])
            oPainter.setBrush(new QBrush() { setStyle(1) setColor(new QColor(){setRGB(color[1],color[2],color[3],255)}) })
            oPainter.drawEllipse(600+oPos[i][1]-10, 325+oPos[i][2]-10, 20, 20)
        next
        
        # Displaying data
        oPainter.setPen(new QPen() { setColor(new QColor() { setRGB(255, 255, 255, 255) }) })
        oPainter.drawText(50, 50, "Quantum Epoch: " + nEpoch)
        oPainter.drawText(50, 80, "Folding Energy: " + fEnergy + " units")
        
        oPainter.endpaint()
        oLabel.setPixmap(oPixmap)

    func iif c, t, f if c return t ok return f