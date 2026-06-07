# 16-bit RSA Hardware Implementation

This directory contains a basic 16-bit implementation of the RSA cryptographic algorithm in VHDL. The implementation focuses on the core modular exponentiation operation necessary for RSA encryption and decryption.

## Files
- `mod_exp.vhd`: Core 16-bit modular exponentiation logic.
- `mod_exp_tb.vhd`: Testbench to verify the 16-bit RSA modular exponentiation.

## Simulation
To compile and run the simulation:
```bash
ghdl -a mod_exp.vhd
ghdl -a mod_exp_tb.vhd
ghdl -e mod_exp_tb
ghdl -r mod_exp_tb --vcd=dalga.vcd
```
