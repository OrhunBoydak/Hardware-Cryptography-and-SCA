# Simulated Correlation Power Analysis (CPA) — 16-bit RSA

> **Semester 2, Module 1 · Statistical Key Recovery via Power Modeling**
> Uses GHDL simulation + VCD parsing + Pearson correlation to recover the full RSA private key from power traces — with only 50 trace measurements.

---

## 🎯 Background & Motivation

### Why Simulation Before Physical Hardware?

Physical oscilloscopes introduce several complicating factors:
- **Environmental noise:** 50 Hz mains hum, thermal noise, probe loading
- **Bandwidth limits:** High-frequency transitions may be filtered
- **Trigger jitter:** Misalignment between traces degrades correlation

By first running CPA on *perfect simulation data* (from GHDL VCD files), we can:
1. **Validate the attack methodology** without hardware noise as a confounding factor
2. **Establish the minimum trace count** needed under ideal conditions
3. **Pinpoint exactly which register and which clock cycle** leaks information

Once the simulation attack succeeds, we have a reference to compare against when things get messier with physical hardware.

### What is Correlation Power Analysis (CPA)?

CPA (Kocher, Jaffe & Jun, CRYPTO '99) is a **differential statistical attack** that extracts secret key bits by correlating a theoretical power model against observed power measurements:

1. **Collect** N power traces for N known plaintexts
2. **Model** the theoretical power for every possible key hypothesis using the Hamming Distance of the target register
3. **Correlate** model vs. observation using Pearson's r
4. **The correct key hypothesis** produces |r| ≈ 1 at the exact clock cycle of the leakage; wrong guesses stay near |r| ≈ 0

---

## 🔬 Attack Pipeline

### Step 1: GHDL Simulation → VCD Generation

For each of N random plaintexts:
```bash
ghdl -a mon_pro.vhd mod_exp.vhd rsa_16bit.vhd lfsr_3.vhd tb_rsa_sca.vhd
ghdl -e tb_rsa_sca
ghdl -r tb_rsa_sca -gG_MSG=<message> --vcd=sim_trace_<msg>.vcd
```
The testbench is parameterized with `G_MSG` (generic) to accept the plaintext as a compile-time parameter.

### Step 2: VCD Parsing → Hamming Distance Trace

`vcd_parser.py` traverses the VCD hierarchy to find signal `mod_exp_inst.r_result`, then at every **rising clock edge** computes:
```python
HD(t) = bin(old_value ^ new_value).count('1')
```
This models the instantaneous power consumed by the accumulator register's flip-flop transitions.

### Step 3: Hypothesis Generation

For each key bit position `i` and each guess `g ∈ {0, 1}`:
```python
if g == 0:
    hyp[i] = HW(MonPro(R_state²))          # Only SQUARE
if g == 1:
    hyp[i] = HW(MonPro(MonPro(R_state², M), ...))  # SQUARE + MULTIPLY
```

### Step 4: Pearson Correlation → Key Bit Decision

```python
r(H_j, T(t)) = Σ(H_ij - H̄_j)(T_i(t) - T̄(t)) / (σ_H · σ_T)
```
The key bit is the guess with the highest peak `|r|` across all time samples.

---

## 📊 Results

### 16-bit RSA: Catastrophic Vulnerability

| Metric | Value |
|--------|-------|
| Traces needed | **50** |
| Peak correlation (correct key) | |r| ≈ **0.98** |
| Peak correlation (wrong key) | |r| ≈ 0.05–0.15 |
| Key bits recovered | 16/16 (100%) |
| Attack duration | ~5 min (GHDL simulation limited) |

With 50 traces, the correct key hypothesis separates from the noise floor by a factor of ~6.5×. The separation point (the exact clock sample where |r| peaks) corresponds precisely to the clock cycle when the Montgomery accumulator updates after processing the targeted key bit.

### Why 16-bit is Vulnerable

A 16-bit register has **low algorithmic noise**: only 16 bits can transition per clock cycle. The contribution of the single target bit's Hamming Distance to the total observed power is relatively high (~1/16 of the register's total switching activity), making statistical extraction tractable with few traces.

---

## 📁 Files

```
python/
├── vcd_parser.py        # VCD file parser — extracts HD trace from simulation output
├── cpa_attack_16bit.py  # Main attack script — orchestrates simulation, parsing, and CPA
├── sca_analyzer.py      # Utility: alignment, normalization, correlation utilities
└── spa_attack.py        # Alternative SPA analysis on simulation traces

vhdl/
├── mon_pro.vhd          # Montgomery multiplier (instrumented for VCD output)
├── mod_exp.vhd          # Master FSM exponentiation controller
├── rsa_16bit.vhd        # 16-bit RSA top-level
├── lfsr_3.vhd           # 3-bit LFSR for testbench random message generation
└── tb_rsa_sca.vhd       # SCA-parameterized testbench (G_MSG generic)
```

---

## 🚀 Running the Attack

```bash
cd python/

# Run full CPA attack (collects 50 traces, attacks all 16 bits)
python cpa_attack_16bit.py

# Expected output:
# [*] Collecting 50 traces for 16-bit RSA...
# [*] Attacking Bit 0...
#   - Guess 0 Max Corr: 0.0831
#   - Guess 1 Max Corr: 0.9782
#   => Bit 0 is likely: 1
# ...
# [+] CPA Attack Complete! Recovered Key: 0b0000000000000011
# [SUCCESS] Recovered key matches actual key!
```

**Prerequisites:**
- GHDL installed and in PATH
- Python 3.8+ with `numpy`, `matplotlib`
- The `data/traces/` directory must exist: `mkdir -p data/traces`

---

## 🔗 Related Modules
- [32-bit CPA →](../02_Simulation_32bit/) — Same attack, different result: algorithmic noise study
- [Physical SPA →](../03_Hardware_SPA/) — Real FPGA hardware attack
- [RSA Engine ←](../../01_Hardware_Cryptography/05_RSA_Engine/) — The VHDL being attacked
