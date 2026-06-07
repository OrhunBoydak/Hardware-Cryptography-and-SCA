# Linear Feedback Shift Register & Shrinking Generator

> **Semester 1, Module 1 · Stream Cipher Hardening**
> Demonstrates why a standalone LFSR is cryptographically broken, and how the Shrinking Generator provably fixes this.

---

## 🎯 Background & Motivation

### Why Not Use a Raw LFSR as a Stream Cipher?

An LFSR produces pseudo-random sequences that are fast, compact, and area-efficient in hardware — exactly what a stream cipher needs. But there is a fundamental problem: LFSRs are **mathematically linear**.

The Berlekamp-Massey algorithm can recover the full LFSR internal state (and thus its feedback polynomial and all future output) from exactly `2N` consecutive output bits, where `N` is the register length. For a 64-bit LFSR, an attacker intercepting just 128 output bits can solve 64 linear equations over GF(2) and reconstruct the secret key entirely. This makes standalone LFSRs **cryptographically broken**.

### The Fix: Shrinking Generator

The **Shrinking Generator** (Meier & Staffelbach, CRYPTO '93) introduces non-linearity through *irregular decimation*:

- **LFSR A (64-bit, Selector):** Controls *when* output is produced.
- **LFSR B (63-bit, Data):** Produces the actual keystream bits.

**Rule:** If LFSR A outputs '1' → pass LFSR B's bit to output (`valid_out = 1`). If LFSR A outputs '0' → discard LFSR B's bit (`valid_out = 0`). This makes the output timing unpredictable and destroys the equal-spacing assumption that Berlekamp-Massey requires.

---

## 📐 Mathematical Properties

| Property | Value |
|----------|-------|
| LFSR A polynomial | x⁶⁴ + x⁴ + x³ + x + 1 (primitive) |
| LFSR B polynomial | x⁶³ + x + 1 (primitive) |
| LFSR A period | 2⁶⁴ − 1 ≈ 1.8 × 10¹⁹ |
| LFSR B period | 2⁶³ − 1 ≈ 9.2 × 10¹⁸ |
| gcd(64, 63) | **1** (coprime → maximal combined period) |
| Output period | ≈ 2¹²⁶ (brute-force infeasible) |
| Linear complexity | ≥ 2⁶² · 63 (Berlekamp-Massey resistant) |

The **coprime** bit lengths (gcd=1) are critical: if gcd(N_A, N_B) > 1, the combined period is shorter than optimal. Using primitive polynomials ensures both LFSRs traverse every non-zero state before repeating.

---

## 📁 Files

| File | Description |
|------|-------------|
| `lfsr.vhdl` | Generic, parameterized LFSR entity (configurable width and tap mask) |
| `shrinking_gen.vhdl` | Shrinking Generator top-level, instantiates both LFSR components |
| `tb_shrinking.vhdl` | GHDL testbench — drives clock/reset and dumps VCD |
| `wave.vcd` | Simulation output — open with GTKWave to inspect waveforms |
| `LFSR1.png` | Screenshot showing non-linear `valid_out` pulse behavior |

---

## 🚀 Simulation Instructions

```bash
# Step 1: Analyze (compile) all VHDL units in dependency order
ghdl -a lfsr.vhdl
ghdl -a shrinking_gen.vhdl
ghdl -a tb_shrinking.vhdl

# Step 2: Elaborate the top-level testbench
ghdl -e tb_shrinking

# Step 3: Run simulation and write waveform to VCD
ghdl -r tb_shrinking --vcd=wave.vcd --stop-time=2us

# Step 4: View waveforms
gtkwave wave.vcd
```

**What to observe in GTKWave:**
- `valid_out` should pulse irregularly — **not** at fixed intervals.
- `stream_out` should change only when `valid_out` is high.
- If `valid_out` pulses at a fixed cadence, there is a linearity bug.

---

## 🔬 Key Observations from Simulation

The simulation waveform confirms two critical properties:
1. **Irregular timing:** `valid_out` rises and falls at non-uniform intervals. The intervals between valid pulses vary unpredictably, directly destroying time-domain linearity.
2. **Non-zero output:** `stream_out` never becomes permanently stuck at '0' (the all-zero absorbing state), confirming the seed initialization is correct.

---

## 🔗 Related Modules
- [RSA Engine →](../05_RSA_Engine/) — Next step: asymmetric public-key hardware
- [CPA Attack →](../../02_Side_Channel_Analysis/01_Simulation_16bit/) — How power traces leak LFSR state
