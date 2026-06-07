# Simulated CPA — 32-bit RSA: Algorithmic Noise Study

> **Semester 2, Module 2 · Why CPA Fails Against Wider Datapaths**
> Applies the identical CPA methodology from Module 1 to the 32-bit RSA architecture and quantifies the role of algorithmic noise in CPA resistance.

---

## 🎯 Background & Motivation

### The Question This Module Answers

After successfully recovering the 16-bit RSA key in 50 traces, a natural engineering question arises: **does simply widening the datapath provide meaningful SCA resistance?** Specifically, if a hardware designer increases the Montgomery multiplier's internal register width from 16 to 32 bits — without changing any algorithm or adding masking — does CPA become harder?

The answer is: **yes, quantifiably, but not indefinitely.** This module demonstrates exactly why, using the same attack infrastructure with the only change being the target datapath width.

---

## 🔬 Algorithmic Noise: A Quantitative Analysis

### What is Algorithmic Noise?

In a 16-bit register, the Hamming Distance contribution of a single targeted bit is a significant fraction (~1/16) of the total register's switching activity per clock cycle. In a 32-bit register, that contribution drops to ~1/32.

The remaining 31 bits (in a 32-bit system) also transition each clock cycle. Their transitions are **uncorrelated with the key hypothesis** — they are purely data-dependent noise from the algorithm's internal arithmetic. This is called **algorithmic noise**: power variation that originates inside the device but is independent of the targeted key bit.

### Signal-to-Noise Ratio Model

The CPA SNR scales approximately as:
```
SNR_CPA ≈ 1 / sqrt(N_bits - 1)
```

Where `N_bits` is the register width. Therefore:

| Register Width | Relative SNR | Traces Required (est.) |
|---------------|-------------|----------------------|
| 16-bit | 1.00× (baseline) | ~50 |
| 32-bit | 0.70× | ~100 |
| 64-bit | 0.50× | ~200 |
| 128-bit | 0.35× | ~400 |
| 2048-bit (real RSA) | 0.09× | ~6,000+ |

*Traces required scales as SNR⁻², meaning doubling the datapath width quadruples the required trace count.*

---

## 📊 Experimental Results

### 32-bit CPA: Attack Failure at 50 Traces

| Metric | 16-bit (Module 1) | 32-bit (This module) |
|--------|-------------------|---------------------|
| Traces collected | 50 | 50 |
| Peak |r| (correct key) | **0.98** | 0.25 |
| Peak |r| (all hypotheses) | 0.98 | 0.27 |
| Key bits recovered | 16/16 | **0/32** |
| Status | ✅ Success | ❌ Failed |

With 50 traces, the maximum observed correlation drops from 0.98 to 0.25 — below the statistical significance threshold needed to distinguish the correct key hypothesis from noise. The 31 uncorrelated bits in the 32-bit register are generating enough power variation to drown out the single bit of information the attack is trying to extract.

### What This Tells Hardware Designers

- **Algorithmic noise is real but not a full defense.** With sufficient traces (theoretically ~200 for 32-bit), CPA would eventually succeed.
- **Wider datapaths raise the attack cost, not eliminate it.** It is a probabilistic delay, not a cryptographic guarantee.
- **The correct defense is masking**, not datapath inflation.

---

## 📁 Files

```
python/
├── cpa_attack_32bit.py  # CPA attack script for 32-bit RSA (same structure as 16-bit)
└── vcd_parser.py        # Shared VCD parser utility

vhdl/
├── mon_pro_32bit.vhd    # 32-bit Montgomery multiplier
├── mod_exp_32bit.vhd    # 32-bit exponentiation controller
└── tb_rsa_32bit_sca.vhd # SCA testbench for 32-bit
```

---

## 🚀 Running the Attack

```bash
cd python/

# Run 32-bit CPA (same 50 traces, expected failure)
python cpa_attack_32bit.py

# Expected output:
# [*] Collecting 50 traces for 32-bit RSA...
# [*] Attacking Bit 0...
#   - Guess 0 Max Corr: 0.2234
#   - Guess 1 Max Corr: 0.2501
#   => Bit 0 is likely: 1   ← WARNING: may be incorrect
# ...
# [WARNING] Need more traces for stable recovery.
```

---

## 🔗 Related Modules
- [16-bit CPA ←](../01_Simulation_16bit/) — Successful baseline attack
- [Physical SPA →](../03_Hardware_SPA/) — An attack that bypasses algorithmic noise entirely
- [RSA Engine ←](../../01_Hardware_Cryptography/05_RSA_Engine/) — VHDL being attacked
