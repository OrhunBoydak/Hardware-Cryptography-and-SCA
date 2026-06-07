import json
import matplotlib.pyplot as plt

def plot_hd_trace():
    print("Loading 32-bit extracted Hamming Distances...")
    try:
        with open("data/traces_32bit/extracted_hd_32.json", "r") as f:
            hd_events = json.load(f)
    except FileNotFoundError:
        print("Error: extracted_hd_32.json not found. Run vcd_parser_32.py first.")
        return

    if not hd_events:
        print("No HD events found in the JSON file.")
        return

    times = [event['time'] for event in hd_events]
    hds = [event['hd'] for event in hd_events]
    signal_name = hd_events[0]['signal'] if hd_events else "Unknown Signal"

    plt.figure(figsize=(12, 6))
    plt.step(times, hds, where='post', color='g', linewidth=2)
    plt.title(f"32-Bit Hamming Distance Trace for {signal_name}")
    plt.xlabel("Simulation Time (fs)")
    plt.ylabel("Hamming Distance (HD)")
    plt.grid(True, linestyle='--', alpha=0.7)
    
    # Highlight peaks dynamically
    max_hd = max(hds) if hds else 0
    threshold = max(0, max_hd - 1)
    peaks = [h for h in hds if h > threshold]
    plt.scatter([times[i] for i, h in enumerate(hds) if h > threshold], peaks, color='r', zorder=5, label=f"High HD Activity (>{threshold})")
    plt.legend()
    
    output_path = "data/traces_32bit/hd_plot_32bit.png"
    plt.savefig(output_path, dpi=300, bbox_inches='tight')
    print(f"Plot saved successfully to {output_path}")

if __name__ == "__main__":
    plot_hd_trace()
