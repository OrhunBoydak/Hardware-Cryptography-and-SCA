import json
import matplotlib.pyplot as plt
import numpy as np

def plot_hd_trace():
    print("Loading extracted Hamming Distances...")
    try:
        with open("data/traces/extracted_hd.json", "r") as f:
            hd_events = json.load(f)
    except FileNotFoundError:
        print("Error: extracted_hd.json not found. Run vcd_parser.py first.")
        return

    if not hd_events:
        print("No HD events found in the JSON file.")
        return

    times = [event['time'] for event in hd_events]
    hds = [event['hd'] for event in hd_events]
    signal_name = hd_events[0]['signal'] if hd_events else "Unknown Signal"

    # Create a visual plot of the Hamming Distance over time
    plt.figure(figsize=(12, 6))
    plt.step(times, hds, where='post', color='b', linewidth=2)
    plt.title(f"Hamming Distance Trace for {signal_name}")
    plt.xlabel("Simulation Time (fs)")
    plt.ylabel("Hamming Distance (HD)")
    plt.grid(True, linestyle='--', alpha=0.7)
    
    # Highlight peaks (potential leakage points) dynamically
    max_hd = max(hds) if hds else 0
    threshold = max(0, max_hd - 1) # Highlight the top HD values
    peaks = [h for h in hds if h > threshold]
    plt.scatter([times[i] for i, h in enumerate(hds) if h > threshold], peaks, color='r', zorder=5, label=f"High HD Activity (>{threshold})")
    plt.legend()
    
    output_path = "data/traces/hd_plot.png"
    plt.savefig(output_path, dpi=300, bbox_inches='tight')
    print(f"Plot saved successfully to {output_path}")

if __name__ == "__main__":
    plot_hd_trace()
