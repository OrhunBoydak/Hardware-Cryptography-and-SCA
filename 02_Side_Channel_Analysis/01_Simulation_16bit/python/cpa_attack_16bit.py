import os
import subprocess
import json
import numpy as np
from typing import List, Dict
import matplotlib.pyplot as plt
import sys

# Ensure vcd_parser is accessible
sys.path.append(os.path.dirname(os.path.abspath(__file__)))
from vcd_parser import extract_hd_from_vcd

def run_ghdl_simulation(msg: int, bit_width: int = 16) -> str:
    """Runs GHDL simulation for a specific message and returns the VCD path."""
    vcd_path = f"data/traces/sim_trace_{msg}.vcd"
    
    # Compile and run
    compile_cmd = [
        "ghdl", "-a", "src/vhdl/mon_pro.vhd", "src/vhdl/mod_exp.vhd", 
        "src/vhdl/rsa_16bit.vhd", "src/vhdl/lfsr_3.vhd", "src/vhdl/tb_rsa_sca.vhd"
    ]
    elab_cmd = ["ghdl", "-e", "tb_rsa_sca"]
    run_cmd = [
        "ghdl", "-r", "tb_rsa_sca",
        f"-gG_MSG={msg}",
        f"--vcd={vcd_path}"
    ]
    
    # We suppress output as we will run this many times
    subprocess.run(compile_cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    subprocess.run(elab_cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    subprocess.run(run_cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    
    return vcd_path

def collect_traces(num_traces: int) -> tuple[np.ndarray, np.ndarray, List[int]]:
    """Collects power traces (HD) for N random messages."""
    traces = []
    messages = np.random.randint(1, 2**15, size=num_traces) # 15-bit to avoid mod reduction on input
    
    print(f"[*] Collecting {num_traces} traces for 16-bit RSA...")
    
    max_len = 0
    raw_traces = []
    
    for i, msg in enumerate(messages):
        if i % 10 == 0:
            print(f"  - Progress: {i}/{num_traces}")
            
        vcd_file = run_ghdl_simulation(msg)
        
        # Target internal Montgomery Register
        targets = ["mod_exp_inst.r_result"]
        
        hd_events = []
        for event in extract_hd_from_vcd(vcd_file, targets):
            hd_events.append(event['hd'])
            
        raw_traces.append(hd_events)
        max_len = max(max_len, len(hd_events))
        
        # Cleanup large VCD to save disk space
        os.remove(vcd_file)
        
    print(f"[*] Trace collection complete. Aligning traces...")
    
    # Align traces (pad with zeros if some finished earlier)
    aligned_traces = np.zeros((num_traces, max_len))
    for i, trace in enumerate(raw_traces):
        aligned_traces[i, :len(trace)] = trace
        
    return aligned_traces, messages

def calculate_pearson(hypotheses: np.ndarray, traces: np.ndarray) -> np.ndarray:
    """Calculates Pearson correlation between hypotheses and traces."""
    num_traces = traces.shape[0]
    num_samples = traces.shape[1]
    
    # Mean of traces and hypotheses over column
    mean_t = np.mean(traces, axis=0)
    mean_h = np.mean(hypotheses)
    
    # Numerator
    diff_t = traces - mean_t
    diff_h = hypotheses - mean_h
    
    num = np.sum(diff_t * diff_h[:, np.newaxis], axis=0)
    
    # Denominator
    den_t = np.sqrt(np.sum(diff_t**2, axis=0))
    den_h = np.sqrt(np.sum(diff_h**2))
    
    # Avoid division by zero
    den = den_t * den_h
    den[den == 0] = 1e-10
    
    return num / den

def mon_pro_model(a: int, b: int, n: int, bit_width: int) -> int:
    """Software model of Montgomery Multiplication for hypothesis."""
    # Simplified Montgomery model A*B*R^-1 mod N
    # For CPA, we just need intermediate values that correlate with hardware
    res = 0
    for i in range(bit_width):
        res_bit = res & 1
        a_bit = (a >> i) & 1
        
        # Simplified add/shift model mimicking VHDL
        if a_bit:
            res += b
            
        if res & 1:
            res += n
            
        res >>= 1
        
    if res >= n:
        res -= n
        
    return res

def perform_cpa(traces: np.ndarray, messages: np.ndarray):
    """Executes the Correlation Power Analysis attack to recover the key."""
    # Hardware parameters
    n = 17 # modulus from tb
    bit_width = 16
    
    print(f"[*] Starting CPA Attack on 16-bit RSA...")
    
    recovered_key = 0
    
    # Attack all 16 bits for Full Key Recovery
    bits_to_attack = 16
    
    # Pre-computation (R mod N)
    # In VHDL tb, start_value = 1 (we ignored R transformation for simplicity)
    current_state = np.ones(len(messages), dtype=int)
    
    for bit_idx in range(bits_to_attack):
        print(f"\n[*] Attacking Bit {bit_idx}...")
        
        correlations = np.zeros((2, traces.shape[1])) # 2 hypotheses (0 or 1) x Samples
        
        for guess in [0, 1]:
            # Generate Hypothesis for this guess
            hyp_hd = np.zeros(len(messages))
            
            for i, msg in enumerate(messages):
                # Simulate Square operation (always happens)
                sq_res = mon_pro_model(current_state[i], current_state[i], n, bit_width)
                
                # If guess is 1, also simulate Multiply operation
                if guess == 1:
                    mult_res = mon_pro_model(sq_res, msg, n, bit_width)
                    # We model HD leakage as HW(prev_state ^ new_state)
                    # For simplicity, HW of the result is also a good approximation
                    hyp_hd[i] = bin(mult_res).count('1')
                else:
                    hyp_hd[i] = bin(sq_res).count('1')
                    
            # Calculate correlation
            correlations[guess] = calculate_pearson(hyp_hd, traces)
            
        # Find the best guess
        max_corr_0 = np.max(np.abs(correlations[0]))
        max_corr_1 = np.max(np.abs(correlations[1]))
        
        print(f"  - Guess 0 Max Corr: {max_corr_0:.4f}")
        print(f"  - Guess 1 Max Corr: {max_corr_1:.4f}")
        
        best_guess = 1 if max_corr_1 > max_corr_0 else 0
        recovered_key |= (best_guess << bit_idx)
        print(f"  => Bit {bit_idx} is likely: {best_guess}")

        # Plot correlation for the first few bits to visualize the attack
        if bit_idx < 2:
            plt.figure(figsize=(10, 5))
            plt.plot(np.abs(correlations[0]), label="Guess 0 (Incorrect)", color='gray', alpha=0.7)
            plt.plot(np.abs(correlations[1]), label="Guess 1 (Correct/Peak)", color='red', linewidth=1.5)
            plt.title(f"16-Bit RSA: Pearson Correlation for Bit {bit_idx}")
            plt.xlabel("Time Samples (Simulation Cycles)")
            plt.ylabel("Absolute Pearson Correlation |r|")
            plt.legend()
            plt.grid(True, linestyle='--', alpha=0.6)
            plt.savefig(f"data/traces/cpa_corr_16bit_bit{bit_idx}.png", dpi=300, bbox_inches='tight')
            plt.close()
        
        # Update state for next bit iteration based on best guess
        for i, msg in enumerate(messages):
            sq_res = mon_pro_model(current_state[i], current_state[i], n, bit_width)
            if best_guess == 1:
                current_state[i] = mon_pro_model(sq_res, msg, n, bit_width)
            else:
                current_state[i] = sq_res

    print(f"\n[+] CPA Attack Complete! Recovered Partial Key (First {bits_to_attack} bits): {bin(recovered_key)}")
    print(f"    (Actual Key in tb_rsa_sca.vhd is x\"0003\" -> binary ...0011)")
    
    if bin(recovered_key) == bin(3):
        print("    [SUCCESS] Recovered key matches actual key!")
    else:
        print("    [WARNING] Need more traces for stable recovery.")

if __name__ == "__main__":
    # Collect traces
    num_traces = 50
    traces, messages = collect_traces(num_traces)
    
    # Run Attack
    perform_cpa(traces, messages)
