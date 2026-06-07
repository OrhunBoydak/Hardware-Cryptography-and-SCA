# Physical Blind Simple Power Analysis (SPA) — Altera DE2-115 FPGA

> **Semester 2, Module 3 · Real Hardware, Real Attack**
> A live laboratory SPA attack on an Altera DE2-115 FPGA running the RSA Square-and-Multiply engine. Key bits are extracted from a single oscilloscope trace using a zero-knowledge, fully adaptive Python pipeline.

---

## 🎯 Background & Motivation

### Why Physical, Not Simulation?

CPA simulation proved the attack is theoretically correct. But simulation uses perfect VCD data — no noise, no probe loading, no 50 Hz mains interference. Physical reality is different:

1. **The shunt resistor technique introduces impedance into the power supply path**, which can distort the power trace.
2. **Oscilloscope quantization noise** (ADC step errors) adds random measurement uncertainty.
3. **Environmental EM interference** from nearby equipment couples into the measurement.
4. **Temperature drift** changes CMOS transistor characteristics between measurements.

Demonstrating a successful attack on real hardware with all these complications proves that the threat is not theoretical.

### Why SPA and Not CPA on Physical Hardware?

CPA failed on 32-bit RSA in simulation because of algorithmic noise. But SPA doesn't care about the *data* inside the registers — it only looks at the *duration* of each state machine step. The Square-and-Multiply algorithm's **timing vulnerability** exists regardless of how many bits the registers contain: a '1' key bit always takes longer than a '0' key bit. SPA bypasses the algorithmic noise defense entirely.

---

## 🔧 Hardware Setup

### Shunt Resistor Instrumentation

To measure the FPGA's dynamic power consumption, current must be measured indirectly via a **shunt resistor** in series with the power supply:

```
                                              ┌──────────────────┐
DC Power Adaptor (–) ──[ 0.5 Ω Shunt ]──────► FPGA GND          │
                              │               │                  │
                    Oscilloscope Probe        │  Altera DE2-115  │
                    (Differential)            │                  │
                                              └──────────────────┘
```

By Ohm's Law: `V_shunt = I_FPGA × 0.5 Ω`

Any change in the FPGA's power consumption directly appears as a proportional voltage change across the shunt. The oscilloscope captures this voltage over time, producing the power trace.

**Why low-side?** Placing the shunt between the FPGA ground pin and the adaptor ground (low-side) keeps both shunt terminals near 0V, minimizing common-mode voltage that would saturate the oscilloscope probe differential amplifier.

### Clock Frequency Scaling

| Parameter | Original | Modified |
|-----------|---------|----------|
| FPGA clock | 50 MHz | **2 MHz** |
| Time per clock cycle | 20 ns | **500 ns** |
| Time per Montgomery loop (N=16) | ~320 ns | **~8 µs** |
| Total SQUARE operation duration | ~microseconds | **~16 µs** |
| Total SQUARE+MULTIPLY duration | ~microseconds | **~32 µs** |

At 50 MHz, one Montgomery multiplication takes ~320 ns — below the temporal resolution of standard oscilloscopes. Scaling to 2 MHz via the PLL extends operations to the **microsecond regime**, making each power burst clearly visible. The cryptographic operation is identical; only the physical measurement bandwidth requirement changes.

---

## 🐍 The Blind SPA Python Pipeline

"Blind" means the algorithm extracts key bits **without any prior knowledge** of: the secret key, the FPGA clock speed, the hardware parameters, or the oscilloscope settings. It adapts entirely from the measured data.

### Pipeline Steps

```
Raw CSV from oscilloscope
        │
        ▼
1. INVERSION HEURISTIC
   Low-side shunt spikes are negative (current spike = voltage drop)
   If |min - mean| > |max - mean|: invert signal
        │
        ▼
2. MOVING-AVERAGE SMOOTHING  (window = 10 samples)
   Suppresses high-frequency noise while preserving burst shapes
        │
        ▼
3. SCIPY PEAK DETECTION
   find_peaks(height = mean + 0.5σ, min_distance = 5 samples)
   Each peak = start of a new Montgomery operation
        │
        ▼
4. INTER-PEAK INTERVAL MEASUREMENT
   distances[i] = time[peaks[i+1]] - time[peaks[i]]
        │
        ▼
5. DYNAMIC THRESHOLD CLASSIFICATION
   threshold = mean(distances)   ← no hardcoding!
   d > threshold  →  '1'  (SQUARE + MULTIPLY, long)
   d ≤ threshold  →  '0'  (SQUARE only, short)
        │
        ▼
Extracted binary key segment
```

### Why Dynamic Thresholding Is Critical

A fixed threshold would require knowing:
- The exact clock frequency (we changed it, so it's known, but...)
- The exact Montgomery loop count for this hardware
- The precise voltage scale of the current oscilloscope gain setting
- The temperature at time of measurement

The **mean of measured intervals** as the threshold makes the algorithm work across different FPGA configurations, temperatures, and oscilloscope settings — and even partially corrupted traces.

---

## 📊 Experimental Results

### scope_0.csv — 10 µs Window

| Parameter | Value |
|-----------|-------|
| Total peaks detected | 13 |
| Intervals measured | 12 |
| Dynamic threshold | self-computed |
| Extracted key bits | `010101010110` |
| Single trace needed? | **Yes** |

### scope_2.csv — Extended Window, Higher Noise

| Parameter | Value |
|-----------|-------|
| Total peaks detected | 22 |
| Intervals measured | 21 |
| Dynamic threshold | **0.23 µs** (auto-computed) |
| Extracted key bits | `00000000011010000110` |
| Single trace needed? | **Yes** |

The algorithm correctly adapted its threshold to the higher noise environment of the second trace without any manual tuning.

---

## 📁 Files

| File | Description |
|------|-------------|
| `blind_spa.py` | Main blind SPA pipeline — processes any scope CSV file |
| `spa_key_recovery.py` | Post-processing: maps extracted binary to key segment |
| `extract_video_trace.py` | Extracts frames from oscilloscope video for analysis |
| `generate_explanation.py` | Generates annotated explanation plots |
| `scope_0.csv` | Raw oscilloscope trace — 10 µs capture |
| `scope_1.csv` | Secondary trace |
| `scope_2.csv` | Extended trace — 20+ bit extraction |
| `blind_trace.png` | Peak detection visualization |
| `blind_intervals.png` | Inter-peak interval bar chart with threshold |
| `scope_2_trace.png` | scope_2 peak detection |
| `scope_2_intervals.png` | scope_2 interval analysis |
| `attack_plot.png` | Combined annotation |
| `IMG_6324.MOV` | Lab video: oscilloscope screen capture during attack |

---

## 🚀 Running the Attack

```bash
# Install dependencies
pip install numpy matplotlib scipy

# Run blind SPA on any oscilloscope CSV file
python blind_spa.py scope_0.csv
python blind_spa.py scope_2.csv

# Expected output:
# --- BLIND EXTRACTION RESULTS ---
# Total peaks found: 13
# Total distances measured: 12
# Threshold used to separate short/long: X.XX microseconds
#
# Extracted Binary (Based on 12 intervals):
# 010101010110
```

### CSV Format Expected
The oscilloscope must export in the following format:
```
x-axis,1
second,Volt
<time1>,<voltage1>
<time2>,<voltage2>
...
```

---

## ⚠️ Key Security Conclusions

This experiment proves:

1. **A single oscilloscope trace is sufficient** to extract key bits from unprotected hardware.
2. **Algorithmic noise (which defeated CPA on 32-bit RSA) provides zero protection** against SPA, which operates on timing, not data.
3. **The attack requires no specialized equipment** — any oscilloscope with CSV export and 50 lines of Python suffice.
4. **Constant-time algorithms are mandatory.** The Montgomery Ladder must replace Square-and-Multiply in any production RSA implementation.

---

## 🔗 Related Modules
- [CPA 16-bit ←](../01_Simulation_16bit/) — Statistical power attack
- [CPA 32-bit ←](../02_Simulation_32bit/) — Why wider registers resist CPA (but not SPA)
- [RSA Engine ←](../../01_Hardware_Cryptography/05_RSA_Engine/) — The VHDL being physically attacked
