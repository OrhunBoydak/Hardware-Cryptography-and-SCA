# 32-bit RSA Hardware Implementation

This directory contains a scaled-up 32-bit implementation of the RSA cryptographic algorithm in VHDL, extending the 16-bit design to handle larger prime numbers and data.

## Files
- `mod_exp.vhd`: Core 32-bit modular exponentiation logic.
- `mod_exp_tb.vhd`: Testbench to verify the 32-bit RSA modular exponentiation.

## Simulation
To compile and run the simulation:
```bash
ghdl -a mod_exp.vhd
ghdl -a mod_exp_tb.vhd
ghdl -e mod_exp_tb
ghdl -r mod_exp_tb --vcd=dalga_32bit.vcd
```
