# Elliptic Curve Cryptography - Point Addition

This directory contains the hardware implementation of Point Addition for Elliptic Curve Cryptography (ECC) over finite fields using VHDL.

## Files
- `point_add.vhd`: Core logic for adding two points on an elliptic curve.
- `mon_pro.vhd`: Montgomery multiplier, often used for efficient modular arithmetic required in ECC.
- `mod_exp.vhd`: Modular exponentiation component.
- `point_add_tb.vhd`: Testbench to verify the correctness of the point addition module.

## Simulation
To simulate the ECC point addition using GHDL:
```bash
ghdl -a mon_pro.vhd
ghdl -a mod_exp.vhd
ghdl -a point_add.vhd
ghdl -a point_add_tb.vhd
ghdl -e point_add_tb
ghdl -r point_add_tb --vcd=ecc_final.vcd
```
