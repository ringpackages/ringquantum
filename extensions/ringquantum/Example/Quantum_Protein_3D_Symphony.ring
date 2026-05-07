load "guilib.ring"
load "ringquantum.ring"
load "ringml.ring"

# --- Simulation settings ---
cSeq = "HPHPPHHPH" # Experimental sequence (H: Hydrophobic, P: Polar)
nLen = len(cSeq)
nLinks = nLen - 1
nQ = nLinks * 3 # 3 qubits per direction (X,Y,Z)
oApp = null
oSim = null

# Display settings (Adapted from your engine)
nWidth = 1200 nHeight = 650 PI = 3.1415926535

func main
    oApp = new qApp {
        oWin = new qWidget() {
            oSim = new QuantumProtein3D("oSim")
        }
        exec()
    }

class QuantumProtein3D from qWidget
    oPos = [] fEnergy = 0.0 nPass = 0
    angleX = 45.0 angleY = 30.0 nZoom = 1.0
    oTimer oPixmap oPainter oLabel
	oObjectName
	oCurrentPos = [] # Positions displayed on the screen
	oTargetPos  = [] # Positions requested by the quantum engine
    
	# Hybrid optimization parameters (Adam)
    W = tensor_init(1, 2) Grad = tensor_init(1, 2)
    M = tensor_init(1, 2) V = tensor_init(1, 2)

    func init ObjectName
		oObjectName = ObjectName
        super.init()
        setupUI()
        tensor_set(W, 1, 1, 0.5) tensor_set(W, 1, 2, 0.5) # Gamma, Beta
        
        oTimer = new QTimer(this) {
            setInterval(50)
            setTimeOutEvent(this.oObjectName + ".quantumCycle()")
            start()
        }
        return self

    func setupUI
        setWindowTitle("Leviathan Quantum 3D: Protein Folding Symphony")
        resize(nWidth, nHeight)
        oLabel = new QLabel(this) { setGeometry(0, 0, nWidth, nHeight) }
        oPixmap = new QPixmap2(nWidth, nHeight)
        oPainter = new QPainter()
        show()

    func quantumCycle
        nPass++
        g = tensor_get(W, 1, 1)
        b = tensor_get(W, 1, 2)

        # 1. Running the quantum engine (GPU Turbo)
        # Searching in 16.7 million states (24 qubits) at once
        q = new QuantumCircuit(nQ)
        
        # QAOA Ansatz
        for i = 0 to nQ-1 q.H(i) next # Superposition for all possible shapes in 3D
        
        # Encoding hydrophobicity (Cost Layer)
        # If the amino acid is H, we change the phase of the qubits responsible for its direction
        for i = 0 to nLinks-1
            if cSeq[i+1] = "H" q.RZ(i*3, g) ok
        next
        
        for i = 0 to nQ-1 q.RX(i, 2.0 * b) next # Mixer Layer

        # 2. Measuring the result (Collapse of the state to a specific 3D shape)
        cResult = ""
        for i = 0 to nQ-1 cResult += q.Measure(i) next
        
        # 3. Translating the quantum code into real 3D coordinates
        Decode3DFold(cResult)
        
        # 4. Calculating the energy (Attraction between H in 3D space)
        fEnergy = Calculate3DEnergy()
        
        # 5. Updating Adam (to improve probabilities next time)
        tensor_set(Grad, 1, 1, fEnergy * 0.01)
        tensor_set(Grad, 1, 2, fEnergy * 0.01)
        tensor_update_adam(W, Grad, M, V, 0.01, 0.9, 0.999, 0.00000001, nPass, 0.0)
        
        drawFrame()

    func Decode3DFold cBitString
        # Every 3 bits represent a move in 3D
        oPos = [[0,0,0]] 
        curX = 0 curY = 0 curZ = 0
        for i = 1 to len(cBitString) step 3
            move = substr(cBitString, i, 3)
            if move = "000" curX++    # +X
            but move = "001" curX--   # -X
            but move = "010" curY++   # +Y
            but move = "011" curY--   # -Y
            but move = "100" curZ++   # +Z
            but move = "101" curZ--   # -Z
            else # Penalty (Diagonal move not allowed increases energy)
                 curX += 0.5 curY += 0.5
            ok
            add(oPos, [curX, curY, curZ])
        next

    func Calculate3DEnergy
        e = 0.0
        for i = 1 to len(oPos)
            for j = i+2 to len(oPos)
                # Euclidean distance in 3D
                dist = sqrt( (oPos[i][1]-oPos[j][1])**2 + 
                             (oPos[i][2]-oPos[j][2])**2 + 
                             (oPos[i][3]-oPos[j][3])**2 )
                if dist < 1.1 # Adjacent in the 3D grid
                    if cSeq[i] = "H" and cSeq[j] = "H" e -= 2.0 ok # Strong stability
                ok
                if dist < 0.1 e += 10.0 ok # Collision penalty (Hydrophobic in the same point)
            next
        next
        return e

    func drawFrame
        oPixmap.fill(new QColor() { setRGB(1, 4, 12, 255) })
        oPainter.begin(oPixmap)
        oPainter.setRenderHint(1, true)
        
        drawProtein3D()
        drawHUD()
        
        oPainter.endpaint()
        oLabel.setPixmap(oPixmap)

    func drawProtein3D
        oRot = getRotationMatrix(angleX, angleY, 0)
        cx = nWidth/2 cy = nHeight/2
        scale = 50.0 * nZoom
        
        # Projecting points to 2D (Same as your professional engine)
        aNodes = []
        for i = 1 to len(oPos)
            v3 = rotatePoint(oPos[i][1], oPos[i][2], oPos[i][3], oRot)
            factor = 15.0 / (15.0 + v3[3])
            px = cx + v3[1] * scale * factor
            py = cy + v3[2] * scale * factor
            add(aNodes, [px, py, v3[3], cSeq[i]])
        next

        # Drawing 3D bonds
        oPainter.setPen(new QPen() { setColor(new QColor(){setRGB(255,255,255,100)}) setWidth(3) })
        for i = 1 to len(aNodes)-1
            oPainter.drawLine(aNodes[i][1], aNodes[i][2], aNodes[i+1][1], aNodes[i+1][2])
        next

        # Drawing balls with depth effect (Simple Z-Buffer)
        for i = 1 to len(aNodes)
            radius = 25 * (15.0 / (15.0 + aNodes[i][3]))
            color = iif(aNodes[i][4]="H", [0, 219, 255], [255, 0, 180])
            oPainter.setBrush(new QBrush() { setStyle(1) setColor(new QColor(){setRGB(color[1],color[2],color[3],200)}) })
            oPainter.setPen(new QPen() { setStyle(0) })
            oPainter.drawEllipse(aNodes[i][1]-radius/2, aNodes[i][2]-radius/2, radius, radius)
        next

    func drawHUD
        oPainter.setPen(new QPen() { setColor(new QColor(){setRGB(255,255,255,255)}) })
        oPainter.setFont(new QFont("Consolas", 14, 75, false))
        oPainter.drawText(50, 50, "Quantum 3D Folding - Epoch: " + nPass)
        oPainter.drawText(50, 80, "System Energy: " + fEnergy + " units")
        oPainter.drawText(50, 110, "Qubits Active: " + nQ + " (GPU Turbo)")

    # --- 3D Math Engine (Your own) ---
    func rotatePoint x, y, z, oRot
        vIn = tensor_init(1, 4)
        tensor_set(vIn, 1, 1, x) tensor_set(vIn, 1, 2, y)
        tensor_set(vIn, 1, 3, z) tensor_set(vIn, 1, 4, 1)
        vOut = tensor_init(1, 4)
        tensor_matmul(vIn, oRot, vOut)
        return [tensor_get(vOut, 1, 1), tensor_get(vOut, 1, 2), tensor_get(vOut, 1, 3)]

    func getRotationMatrix ax, ay, az
        rad = PI / 180
        rx = ax * rad ry = ay * rad rz = az * rad
        oRx = tensor_init(4, 4) tensor_set(oRx, 1, 1, 1) tensor_set(oRx, 4, 4, 1)
        c=cos(rx) s=sin(rx)
        tensor_set(oRx, 2, 2, c) tensor_set(oRx, 2, 3, 0-s)
        tensor_set(oRx, 3, 2, s) tensor_set(oRx, 3, 3, c)
        oRy = tensor_init(4, 4) tensor_set(oRy, 2, 2, 1) tensor_set(oRy, 4, 4, 1)
        c=cos(ry) s=sin(ry)
        tensor_set(oRy, 1, 1, c) tensor_set(oRy, 1, 3, s)
        tensor_set(oRy, 3, 1, 0-s) tensor_set(oRy, 3, 3, c)
        oRz = tensor_init(4, 4) tensor_set(oRz, 3, 3, 1) tensor_set(oRz, 4, 4, 1)
        c=cos(rz) s=sin(rz)
        tensor_set(oRz, 1, 1, c) tensor_set(oRz, 1, 2, 0-s)
        tensor_set(oRz, 2, 1, s) tensor_set(oRz, 2, 2, c)
        temp = tensor_init(4, 4)
        tensor_matmul(oRx, oRy, temp)
        oRes = tensor_init(4, 4)
        tensor_matmul(temp, oRz, oRes)
        return oRes

    func iif c, t, f if c return t ok return f