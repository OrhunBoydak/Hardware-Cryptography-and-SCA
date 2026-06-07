# Hardware Cryptography & Side-Channel Analysis

> **A year-long progressive study of cryptographic hardware construction and physical exploitation.**
> VHDL implementations on Altera DE2-115 FPGA, Correlation Power Analysis (CPA), and Simple Power Analysis (SPA).

---

## 🔍 Overview

This repository documents two semesters of hands-on hardware security research, deliberately structured to traverse both sides of the hardware security boundary:

| Phase | Semester | Focus | Tools |
|-------|----------|-------|-------|
| 🏗️ **Construction** | Semester 1 | Implement cryptographic primitives in VHDL | GHDL, GTKWave |
| ⚔️ **Exploitation** | Semester 2 | Break those same implementations via Side-Channel Analysis | Python, Oscilloscope |

The central thesis: **a mathematically correct hardware implementation is not a secure one.** Physical execution leaks secrets through timing, power consumption, and electromagnetic radiation — independently of the underlying algorithm's mathematical hardness.

---

## 📁 Repository Structure

```
.
├── 01_Hardware_Cryptography/     # Semester 1: VHDL Implementations
│   ├── 01_LFSR/                  # Shrinking Generator stream cipher
│   ├── 02_RSA_16bit/             # Baseline 16-bit RSA
│   ├── 03_RSA_32bit/             # Scaled 32-bit RSA
│   ├── 04_RSA_Montgomery/        # Montgomery multiplier module
│   ├── 05_RSA_Engine/            # Master-Slave FSM RSA engine
│   ├── 06_RSA_Final/             # Fully integrated RSA accelerator
│   └── 07_Elliptic_Curve/        # ECC point arithmetic
│
├── 02_Side_Channel_Analysis/     # Semester 2: Attack Experiments
│   ├── 00_Data_Traces/           # Raw oscilloscope CSV files
│   ├── 01_Simulation_16bit/      # CPA on 16-bit RSA (VCD-based)
│   ├── 02_Simulation_32bit/      # CPA on 32-bit RSA (algorithmic noise study)
│   └── 03_Hardware_SPA/          # Physical SPA on Altera DE2-115 FPGA
│
└── docs/
    ├── reports/                  # LaTeX academic papers
    └── presentations/            # Poster & slides
```

---

## 📘 Semester 1 — Hardware Cryptography Construction

### Why Build Cryptographic Hardware?

Software cryptography runs on general-purpose CPUs — flexible but slow. Hardware implementations in VHDL/FPGA provide orders-of-magnitude speedups for specific operations (e.g., RSA modular exponentiation, AES S-box lookups). However, implementation on physical silicon introduces a new threat surface: the hardware's own physical behavior.

### 01 · LFSR & Shrinking Generator

**The Problem:** Linear Feedback Shift Registers (LFSRs) are the most hardware-efficient pseudo-random sequence generators. However, they are **cryptographically broken**: the Berlekamp-Massey algorithm recovers the entire key from just `2N` consecutive output bits.

**The Solution:** The **Shrinking Generator** uses two LFSRs in a Master-Slave configuration. LFSR A (64-bit) acts as a binary decimator: when it outputs '1', LFSR B's (63-bit) bit passes through; when it outputs '0', LFSR B's bit is discarded. This **irregular decimation** destroys the temporal linearity of the output, making it immune to Berlekamp-Massey. The coprime lengths (gcd(64,63)=1) ensure the combined output period reaches ~2¹²⁷ clock cycles.

→ [Detailed README](./01_Hardware_Cryptography/01_LFSR/README.md)

### 02–06 · RSA Engine with Montgomery Multiplication

**The Problem:** Implementing RSA in hardware requires computing `M^d mod N` where `d` can be 2048+ bits. Naive modular reduction requires hardware integer division — expensive in area, slow in throughput.

**The Solution:** **Montgomery Multiplication** transforms operands into a special domain where modular reduction becomes right-shifts and additions — primitive hardware operations. A **Master-Slave Finite State Machine** architecture was implemented:
- **Slave FSM (`mon_pro`):** Executes one Montgomery product bit-by-bit, signals `done` when complete.
- **Master FSM (`mod_exp`):** Scans exponent bits MSB→LSB, triggers SQUARE and MULTIPLY via the Slave, exits the Montgomery domain via a final domain-conversion multiply.

Implementations were verified at 16-bit and 32-bit datapath widths. The 32-bit variant was specifically constructed to study algorithmic noise effects in Phase 2.

→ [Montgomery README](./01_Hardware_Cryptography/04_RSA_Montgomery/README.md) | [Engine README](./01_Hardware_Cryptography/05_RSA_Engine/README.md)

### 07 · Elliptic Curve Cryptography (ECC)

RSA requires 2048-bit keys for 112-bit security; ECC achieves the same with 224-bit keys (9× smaller). The ECC module establishes the mathematical framework for hardware scalar multiplication (`Q = kP`) using the **Double-and-Add** algorithm — the structural twin of Square-and-Multiply, with the same SPA vulnerability implications.

→ [ECC README](./01_Hardware_Cryptography/07_Elliptic_Curve/README.md)

---

## 🔓 Semester 2 — Side-Channel Exploitation

### Why Physical Attacks?

A textbook RSA implementation is computationally secure. But when hardware computes a Montgomery multiplication, the **switching activity of its flip-flops** — measurable as millivolt fluctuations across a shunt resistor — broadcasts the Hamming weight of the intermediate result to any oscilloscope. The algorithm is unbroken; the device is not.

### 01–02 · Simulated CPA (Correlation Power Analysis)

**Method:** A custom Python pipeline drives GHDL simulations for N random plaintexts, parses the resulting VCD (Value Change Dump) files, extracts the Hamming Distance of the target Montgomery register at every clock edge, and runs a statistical Pearson correlation attack.

**16-bit result:** With only **50 traces**, the correct key hypothesis achieves |r| ≈ 0.98 — catastrophic key recovery.

**32-bit result:** CPA fails — maximum correlation drops to |r| ≈ 0.25. The root cause is **algorithmic noise**: 32 bits toggle per cycle, drowning the single-bit leakage from the targeted register. This is a quantified, reproducible finding confirming the statistical relationship between datapath width and CPA resistance.

→ [CPA 16-bit README](./02_Side_Channel_Analysis/01_Simulation_16bit/README.md) | [CPA 32-bit README](./02_Side_Channel_Analysis/02_Simulation_32bit/README.md)

### 03 · Physical Blind SPA on Altera DE2-115

**Hardware Setup:**
- A **0.5 Ω shunt resistor** placed in series on the low-side FPGA ground return
- Oscilloscope differential probe across the shunt → direct current measurement
- PLL reprogrammed: 50 MHz → **2 MHz** to make operations measurable (~500 ns/cycle)

**Attack:** The blind Python pipeline (`blind_spa.py`) processes raw oscilloscope CSV data:
1. Inversion heuristic (low-side spikes are negative)
2. Moving-average smoothing to suppress noise
3. Statistical peak detection (no hardcoded thresholds)
4. Dynamic threshold classification: short interval → '0' (SQUARE only), long interval → '1' (SQUARE + MULTIPLY)

**Result:** From a single 10 µs oscilloscope trace, the algorithm extracted **12–20 binary key bits** with zero prior knowledge of the secret key. The attack works on a single trace regardless of datapath width — SPA defeats the "algorithmic noise" defense.

→ [Hardware SPA README](./02_Side_Channel_Analysis/03_Hardware_SPA/README.md)

---

## 📄 Documentation

| Document | Description |
|----------|-------------|
| [`extended_annual_report.tex`](./docs/reports/extended_annual_report.tex) | Full IEEE-format academic paper with theory, methodology, and results |
| [`first_semester_works.tex`](./docs/reports/first_semester_works.tex) | Semester 1 detailed technical report |
| [`hardware_spa.tex`](./docs/reports/hardware_spa.tex) | Physical SPA laboratory experiment report |

---

## ⚙️ Requirements

### VHDL Simulation
```bash
# Install GHDL (open-source VHDL simulator)
brew install ghdl         # macOS
sudo apt install ghdl     # Ubuntu/Debian

# Install GTKWave (waveform viewer)
brew install gtkwave
```

### Python Analysis
```bash
pip install numpy matplotlib scipy pandas
```

---

## 🛡️ Key Takeaways

| Finding | Implication |
|---------|-------------|
| LFSR alone is broken | Always use non-linear combination (Shrinking Generator, Grain, etc.) |
| Montgomery Mult. is essential | Hardware RSA is infeasible without it |
| CPA breaks 16-bit RSA in 50 traces | Even "secure" algorithms need power masking |
| SPA breaks any datapath width in 1 trace | **Constant-time algorithms are mandatory** (Montgomery Ladder) |
| Physical SPA needs only an oscilloscope | No specialized equipment needed for real attacks |

---

## 📚 References

1. Meier & Staffelbach — *The Shrinking Generator* (CRYPTO '93)
2. P. L. Montgomery — *Modular Multiplication Without Trial Division* (1985)
3. Kocher, Jaffe & Jun — *Differential Power Analysis* (CRYPTO '99)
4. N. Koblitz — *Elliptic Curve Cryptosystems* (1987)
5. J. L. Massey — *Shift-Register Synthesis and BCH Decoding* (1969)
