import sys
import json
from typing import List, Dict, Generator

def hamming_weight(val: int) -> int:
    return bin(val).count("1")

def hamming_distance(val1: int, val2: int) -> int:
    return hamming_weight(val1 ^ val2)

def extract_hd_from_vcd(vcd_path: str, target_signals: List[str]) -> Generator[Dict[str, int], None, None]:
    signal_ids = {}
    current_values = {}
    previous_values = {}
    
    current_scopes = []
    
    with open(vcd_path, 'r') as f:
        for line in f:
            parts = line.strip().split()
            if not parts:
                continue
                
            if parts[0] == "$scope":
                current_scopes.append(parts[2])
            elif parts[0] == "$upscope":
                if current_scopes:
                    current_scopes.pop()
            elif parts[0] == "$var":
                var_id = parts[3]
                var_name = parts[4]
                full_name = ".".join(current_scopes + [var_name])
                
                for target in target_signals:
                    if target in full_name:
                        signal_ids[var_id] = full_name
                        current_values[var_id] = 0
                        previous_values[var_id] = 0
            elif parts[0] == "$enddefinitions":
                break

        if not signal_ids:
            print("Warning: No target signals found in VCD header. Checked scopes.")
            return

        print(f"Found target signals: {list(signal_ids.values())}")
        
        current_time = 0
        for line in f:
            line = line.strip()
            if not line:
                continue
            
            if line.startswith('#'):
                current_time = int(line[1:])
            elif line.startswith('b') or line.startswith('B'):
                parts = line.split()
                if len(parts) == 2:
                    val_str = parts[0][1:]
                    var_id = parts[1]
                    if var_id in signal_ids:
                        clean_val = ''.join(['0' if c in 'xXzZuU-' else c for c in val_str])
                        if not clean_val:
                            clean_val = '0'
                        new_val = int(clean_val, 2)
                        
                        previous_values[var_id] = current_values[var_id]
                        current_values[var_id] = new_val
                        hd = hamming_distance(previous_values[var_id], current_values[var_id])
                        
                        yield {
                            'time': current_time,
                            'signal': signal_ids[var_id],
                            'hd': hd,
                            'value': new_val
                        }
            else:
                val_str = line[0]
                var_id = line[1:].strip()
                if var_id in signal_ids:
                    clean_val = '0' if val_str in 'xXzZuU-' else val_str
                    new_val = int(clean_val, 2)
                    
                    previous_values[var_id] = current_values[var_id]
                    current_values[var_id] = new_val
                    hd = hamming_distance(previous_values[var_id], current_values[var_id])
                    
                    yield {
                        'time': current_time,
                        'signal': signal_ids[var_id],
                        'hd': hd,
                        'value': new_val
                    }

if __name__ == "__main__":
    vcd_file = "data/traces_32bit/sim_trace_32bit.vcd"
    targets = ["mod_exp_inst.r_result"]
    
    print(f"Parsing {vcd_file} for HD changes on {targets}...")
    try:
        traces = []
        for hd_event in extract_hd_from_vcd(vcd_file, targets):
            traces.append(hd_event)
            
        print(f"Successfully extracted {len(traces)} HD events.")
        
        with open("data/traces_32bit/extracted_hd_32.json", "w") as f:
            json.dump(traces, f)
            
    except FileNotFoundError:
        print(f"Error: {vcd_file} not found. Run GHDL simulation first.")
