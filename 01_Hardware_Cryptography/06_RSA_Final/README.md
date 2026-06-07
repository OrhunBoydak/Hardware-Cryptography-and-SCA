# Final RSA Hardware Implementation

This directory contains the finalized, fine-tuned RSA hardware implementation combining all optimizations (Montgomery multiplication, scaled data paths) developed during the first semester.

## Files
- `mon_pro.vhd`: Montgomery multiplier component.
- `mod_exp.vhd`: Modular exponentiation logic.
- `mod_exp_tb.vhd`: Final testbench to verify the optimized RSA implementation.

## Simulation
To compile and run the simulation:
```bash
ghdl -a mon_pro.vhd
ghdl -a mod_exp.vhd
ghdl -a mod_exp_tb.vhd
ghdl -e mod_exp_tb
ghdl -r mod_exp_tb --vcd=final_zafer.vcd
```
