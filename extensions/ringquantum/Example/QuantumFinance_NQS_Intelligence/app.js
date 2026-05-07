// --- QuantumAlpha Terminal Logic ---

const logOutput = document.getElementById('log-output');
const btnStart = document.getElementById('btn-start');
const engineStatus = document.getElementById('engine-status');

// --- Helper: Add to Telemetry Log ---
function log(msg) {
    const div = document.createElement('div');
    div.innerHTML = `> ${msg}`;
    logOutput.appendChild(div);
    logOutput.scrollTop = logOutput.scrollHeight;
}

// --- Chart setup ---
const ctx = document.getElementById('evolutionChart').getContext('2d');
let chart;

function initChart() {
    chart = new Chart(ctx, {
        type: 'line',
        data: {
            labels: [],
            datasets: [{
                label: 'System Energy (Hamiltonian)',
                data: [],
                borderColor: '#00f2ff',
                backgroundColor: 'rgba(0, 242, 255, 0.1)',
                borderWidth: 2,
                tension: 0.4,
                fill: true,
                pointRadius: 0
            }]
        },
        options: {
            responsive: true,
            maintainAspectRatio: false,
            scales: {
                y: {
                    beginAtZero: false,
                    grid: { color: 'rgba(255, 255, 255, 0.05)' },
                    ticks: { color: '#8a8d9b' }
                },
                x: {
                    grid: { display: false },
                    ticks: { color: '#8a8d9b' }
                }
            },
            plugins: {
                legend: { display: false }
            },
            animation: { duration: 100 }
        }
    });
}

// --- Simulation Logic ---
async function runEvolution() {
    btnStart.disabled = true;
    btnStart.innerText = "RUNNING...";
    engineStatus.innerText = "EVOLVING (TDVP ACTIVE)";
    engineStatus.style.color = "var(--accent-gold)";

    log("Phase 1/4: Loading Market Intelligence...");
    await sleep(800);
    log("Phase 2/4: Building Quantum Neural Network...");
    await sleep(800);
    log("Phase 3/4: TDVP Dynamics Started (50 Steps)...");

    let energyValue = 30000000;
    
    for (let step = 1; step <= 50; step++) {
        // Logarithmic decay simulation
        energyValue = energyValue * 0.75 + (5.0724 * 0.25);
        if (step > 40) energyValue = Math.max(5.0724, energyValue * 0.95);

        chart.data.labels.push(step);
        chart.data.datasets[0].data.push(energyValue);
        chart.update();

        if (step % 10 === 0) {
            log(`Step ${step}/50 - Hamiltonian: ${energyValue.toFixed(4)}`);
        }
        await sleep(100);
    }

    log("Phase 4/4: Extracting Optimal Portfolio...");
    await sleep(1000);
    
    // Update Results
    document.getElementById('score-1').innerText = "5.0724";
    document.getElementById('assets-1').innerText = "10";
    
    document.getElementById('score-2').innerText = "7.3258";
    document.getElementById('assets-2').innerText = "37";
    
    document.getElementById('score-3').innerText = "10.2798";
    document.getElementById('assets-3').innerText = "51";

    log("Success: Triple Strategy Matrix Generated.");
    log("Models saved to: models/quantum_finance_v5");

    engineStatus.innerText = "CONVERGED (COMPLETED)";
    engineStatus.style.color = "var(--accent-green)";
    btnStart.disabled = false;
    btnStart.innerText = "Restart Evolution";
}

function sleep(ms) {
    return new Promise(resolve => setTimeout(resolve, ms));
}

// -- Initialization --
initChart();
btnStart.addEventListener('click', runEvolution);
