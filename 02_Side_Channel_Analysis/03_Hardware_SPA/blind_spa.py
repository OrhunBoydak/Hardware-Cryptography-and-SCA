import csv
import numpy as np
import matplotlib.pyplot as plt
from scipy.signal import find_peaks
import sys
import os

def analyze_scope_csv(csv_path):
    base_name = os.path.splitext(os.path.basename(csv_path))[0]
    time = []
    voltage = []
    
    print(f"\n--- Analyzing {base_name} ---")
    with open(csv_path, 'r') as f:
        # Skip header lines
        next(f) # x-axis,1
        next(f) # second,Volt
        
        reader = csv.reader(f)
        for row in reader:
            if len(row) >= 2:
                time.append(float(row[0]))
                voltage.append(float(row[1]))
                
    if not time:
        print("No data found!")
        return
        
    time = np.array(time)
    voltage = np.array(voltage)
    
    # Invert voltage if the spikes are negative (common in low-side shunt)
    # Let's check mean vs min/max to see direction of spikes
    v_mean = np.mean(voltage)
    v_max = np.max(voltage)
    v_min = np.min(voltage)
    
    if abs(v_min - v_mean) > abs(v_max - v_mean):
        # Spikes go down, let's invert for easier peak detection
        signal = -voltage
    else:
        signal = voltage
        
    # Smooth signal lightly
    window = 10
    smoothed = np.convolve(signal, np.ones(window)/window, mode='same')
    
    # 1. Blind Peak Detection
    # Using scipy find_peaks with a distance heuristic
    # Distance between peaks should be at least a few samples
    peaks, properties = find_peaks(smoothed, height=np.mean(smoothed) + 0.5*np.std(smoothed), distance=5)
    
    plt.figure(figsize=(15, 6))
    plt.plot(time * 1e6, signal * 1000, label='Raw Signal (mV)', color='gray', alpha=0.5)
    plt.plot(time * 1e6, smoothed * 1000, label='Smoothed Signal', color='blue')
    plt.plot(time[peaks] * 1e6, smoothed[peaks] * 1000, "x", color='red', label='Detected Peaks')
    plt.title("Blind SPA Trace Analysis")
    plt.xlabel("Time (microseconds)")
    plt.ylabel("Voltage (mV)")
    
    # 2. Distance Analysis (Timing Attack aspect)
    # The time between peaks indicates the operation.
    # Short duration = Square (0)
    # Long duration = Square + Multiply (1)
    
    if len(peaks) > 1:
        distances = np.diff(time[peaks])
        
        # We expect a bimodal distribution of distances (short vs long)
        threshold_dist = np.mean(distances)
        
        binary_guess = ""
        for d in distances:
            if d > threshold_dist:
                binary_guess += "1"
            else:
                binary_guess += "0"
                
        print("\n--- BLIND EXTRACTION RESULTS ---")
        print(f"Total peaks found: {len(peaks)}")
        print(f"Total distances measured: {len(distances)}")
        print(f"Threshold used to separate short/long: {threshold_dist*1e6:.2f} microseconds")
        print(f"\nExtracted Binary (Based on {len(distances)} intervals):")
        print(binary_guess)
        
        # Plot distances
        plt.figure(figsize=(10, 4))
        plt.bar(range(len(distances)), distances * 1e6, color=['red' if d > threshold_dist else 'blue' for d in distances])
        plt.axhline(threshold_dist * 1e6, color='black', linestyle='--', label='Threshold')
        plt.title(f"Time Distance Between Peaks ({base_name})")
        plt.xlabel("Peak Interval Index")
        plt.ylabel("Duration (microseconds)")
        plt.legend()
        out_int = f"{base_name}_intervals.png"
        plt.savefig(out_int)
        print(f"Saved interval plot to {out_int}")
    else:
        print("\nNot enough peaks found to do distance analysis.")
        
    plt.figure(1)
    plt.legend()
    out_trace = f"{base_name}_trace.png"
    plt.savefig(out_trace)
    print(f"Saved trace plot to {out_trace}")

if __name__ == "__main__":
    if len(sys.argv) > 1:
        analyze_scope_csv(sys.argv[1])
    else:
        print("Usage: python blind_spa.py <csv_file>")
