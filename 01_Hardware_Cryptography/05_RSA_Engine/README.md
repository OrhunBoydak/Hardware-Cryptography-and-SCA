# RSA Engine — Master-Slave FSM Architecture

> **Semester 1, Module 5 · Full RSA Modular Exponentiation**
> Integrates the Montgomery Multiplier (Slave) with a Square-and-Multiply controller (Master) to produce a complete, functional RSA hardware accelerator.

---

## 🎯 Background & Motivation

### Why a Two-FSM Architecture?

RSA's core operation — modular exponentiation `M^d mod N` — decomposes into a loop of modular multiplications controlled by the bits of the private exponent `d`. Two separate concerns must be addressed:

1. **Arithmetic (Slave):** Execute a single modular multiplication as fast as possible using Montgomery's algorithm.
2. **Control (Master):** Scan the exponent bits and orchestrate the correct sequence of squarings and multiplications.

Merging both into a single FSM creates an unwieldy, hard-to-verify state machine. Instead, a clean **Master-Slave (Producer-Consumer) FSM hierarchy** separates the two concerns. This is a standard pattern in hardware microarchitecture (analogous to an ALU + control unit).

---

## 🏗️ Architecture Overview

```
┌─────────────────────────────────────────────────────┐
│                  mod_exp (Master FSM)                │
│                                                      │
│  Load → INIT → SCAN → SQUARE ──► CHECK ──► MULTIPLY │
│                  ▲                          │        │
│                  └──── SHIFT ◄─────────────┘        │
│                           │                          │
│                       FINALIZE → DONE                │
│                                                      │
│         start/done handshake ↕                       │
│                                                      │
│         ┌─────────────────────────┐                  │
│         │   mon_pro (Slave FSM)   │                  │
│         │   IDLE → COMPUTE → DONE│                  │
│         └─────────────────────────┘                  │
└─────────────────────────────────────────────────────┘
```

### Master FSM State Descriptions

| State | Action | SCA Relevance |
|-------|--------|---------------|
| `INIT` | Load M, N; compute R² mod N for domain entry | — |
| `SCAN` | Read current MSB of exponent `d` | Key bit determines next state |
| `SQUARE` | Trigger MonPro(R², R²); wait for `done` | Always executes (both key bits) |
| `CHECK` | Branch on key bit: '1'→MULTIPLY, '0'→SHIFT | **SPA vulnerability point** |
| `MULTIPLY` | Trigger MonPro(result, M); wait for `done` | Only executes for key bit '1' |
| `SHIFT` | Advance to next exponent bit | — |
| `FINALIZE` | MonPro(result, 1) to exit Montgomery domain | — |
| `DONE` | Assert `done_flag`, output result | — |

---

## ⚠️ SPA Vulnerability: The CHECK State

The `CHECK` state is the architectural root cause of Simple Power Analysis vulnerability:

- **Key bit = '0':** The execution path is `SQUARE → CHECK → SHIFT`. Total duration ≈ `T_square`.
- **Key bit = '1':** The execution path is `SQUARE → CHECK → MULTIPLY → SHIFT`. Total duration ≈ `T_square + T_multiply`.

Since `T_multiply ≈ T_square` (both are Montgomery loops of the same length), a '1' bit produces a power burst approximately **twice as long** as a '0' bit. This is directly measurable on an oscilloscope without any statistics.

The fix is the **Montgomery Ladder** algorithm, which performs both squaring and multiplication for every bit, using the key bit only to select which result to retain — making both paths identical in duration and power profile.

---

## 📁 Files

| File | Description |
|------|-------------|
| `mon_pro.vhd` | Montgomery multiplier Slave FSM |
| `mod_exp.vhd` | Square-and-Multiply Master FSM, orchestrates `mon_pro` |
| `mod_exp_tb.vhd` | Testbench: loads key/modulus, verifies `M = (M^e)^d mod N` |
| `dalga_entegre.vcd` | Full system waveform |
| `RSA_engine.png` | Annotated state machine waveform |

---

## 🚀 Simulation Instructions

```bash
# Must compile in dependency order
ghdl -a mon_pro.vhd
ghdl -a mod_exp.vhd
ghdl -a mod_exp_tb.vhd
ghdl -e mod_exp_tb
ghdl -r mod_exp_tb --vcd=dalga_entegre.vcd --stop-time=50us

# View
gtkwave dalga_entegre.vcd
```

**What to verify in the waveform:**
- For each '1' bit in the exponent, two consecutive Montgomery pulses (SQUARE + MULTIPLY) appear.
- For each '0' bit, only one Montgomery pulse (SQUARE) appears.
- The `done_flag` rises after all bits have been processed.
- The final output equals the expected decrypted/encrypted value.

---

## 🔗 Related Modules
- [Montgomery Multiplier ←](../04_RSA_Montgomery/) — The Slave component
- [16-bit Full RSA →](../02_RSA_16bit/) — The 16-bit top-level (includes rsa_top.vhd)
- [Physical SPA Attack →](../../02_Side_Channel_Analysis/03_Hardware_SPA/) — See this architecture attacked in real hardware
