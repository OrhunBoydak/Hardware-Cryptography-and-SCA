# RSA Montgomery Multiplier

> **Semester 1, Module 4 · The Core Arithmetic Engine**
> Implements the Montgomery Multiplication algorithm in VHDL — the technique that makes hardware RSA computationally feasible by eliminating integer division.

---

## 🎯 Background & Motivation

### The Hardware RSA Problem: Why Division Is Catastrophic

RSA encryption and decryption require computing `C = M^e mod N` and `M = C^d mod N`. For a standard 2048-bit RSA key, `d` has ~2048 bits, requiring ~3000 modular multiplications, each followed by a modular reduction (`mod N`). A hardware integer divider for 2048-bit operands requires:
- Thousands of logic cells
- A long combinational critical path
- Many clock cycles per operation

This makes naive hardware RSA physically unrealizable for reasonable clock frequencies or silicon budgets.

### The Solution: Montgomery's Domain Transform

Peter L. Montgomery (1985) discovered that modular reduction can be **replaced by right-shifts and additions** if operands are first transformed into a special representation called the **Montgomery domain**.

Given a modulus `N` and a transformation constant `R = 2^k` where `k ≥ log₂(N)` and `gcd(R, N) = 1`, the Montgomery form of integer `a` is:
```
ã = a · R (mod N)
```

The **Montgomery Product** of two domain-transformed values computes:
```
MonPro(ã, b̃) = ã · b̃ · R⁻¹ (mod N)
```

The magic: this result can be computed using only **additions and right-shifts** — no division required. This is possible because `R = 2^k`, making `R⁻¹` a logical operation (right shift by k positions).

---

## ⚙️ Architecture: The Slave FSM

`mon_pro.vhd` implements the Montgomery Product as a **Slave Finite State Machine** with three states:

```
IDLE ──[start]──► COMPUTE ──[bit_counter = WIDTH]──► DONE ──► IDLE
                    │  ▲
                    └──┘  (iterate WIDTH times)
```

### Core Loop Logic (per clock cycle, per bit of operand A)

```
1. if A[i] = '1'  →  T := T + B          (conditional add)
2. if T[0] = '1'  →  T := T + N          (modular adjustment)
3. T := T >> 1                            (right-shift = division by 2)
```

After `WIDTH` iterations, `T = A · B · R⁻¹ (mod N)` — the Montgomery product.

### Why This Is Correct
- The right-shift at step 3 accumulates the `R⁻¹` factor: after 16 right-shifts, the result has been divided by `2¹⁶ = R`.
- The conditional addition at step 2 ensures `T` remains even before the shift (preserving modular equivalence), without using a remainder/division operation.

---

## 📁 Files

| File | Description |
|------|-------------|
| `mon_pro.vhd` | Montgomery multiplier — the core `mon_pro` entity with `start`/`done` handshake interface |
| `mon_pro_tb.vhd` | Testbench — applies known operands and verifies the result against software reference |
| `dalga_montgomery.vcd` | Simulation waveform output |
| `RSA_montgomery.png` | Annotated waveform showing bit-serial loop iterations |

---

## 🚀 Simulation Instructions

```bash
# Compile and simulate
ghdl -a mon_pro.vhd
ghdl -a mon_pro_tb.vhd
ghdl -e mon_pro_tb
ghdl -r mon_pro_tb --vcd=dalga_montgomery.vcd --stop-time=10us

# View waveforms
gtkwave dalga_montgomery.vcd
```

**What to verify in the waveform:**
- The `done` flag rises exactly `WIDTH` clock cycles after `start`.
- The output `result` matches the software-computed Montgomery product.
- Each clock cycle shows a conditional accumulation pattern in the internal `t_reg` signal.

---

## 🔬 Manual Verification Example

For a 16-bit instance with `A=5, B=7, N=17, R=2^16=65536`:

1. Compute `ã = 5 · 65536 mod 17 = 5` (happens to be identical for this N)
2. `MonPro(5, 7)` should yield `5 · 7 · 65536⁻¹ mod 17 = 35 · R⁻¹ mod 17`
3. Verify `done` asserts on cycle 16 and the output matches expected.

---

## 🔗 Related Modules
- [RSA Engine →](../05_RSA_Engine/) — The Master FSM that uses this module for Square-and-Multiply
- [CPA Attack →](../../02_Side_Channel_Analysis/01_Simulation_16bit/) — The `r_result` register inside `mon_pro` is the exact leakage target
