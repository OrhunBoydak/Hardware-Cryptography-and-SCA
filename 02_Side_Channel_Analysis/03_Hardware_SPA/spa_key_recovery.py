import csv
import matplotlib.pyplot as plt
import numpy as np

def analyze_trace(csv_path):
    frames = []
    voltages = []
    
    # Read the extracted data
    try:
        with open(csv_path, 'r') as f:
            reader = csv.DictReader(f)
            for row in reader:
                frames.append(int(row['frame']))
                voltages.append(float(row['voltage']))
    except FileNotFoundError:
        print(f"Error: Could not find {csv_path}. Please run extract_video_trace.py first.")
        return

    if len(voltages) == 0:
        print("Error: No data found in CSV.")
        return

    frames = np.array(frames)
    voltages = np.array(voltages)
    
    # Simple moving average to smooth the signal
    window_size = 5
    if len(voltages) > window_size:
        smoothed_voltages = np.convolve(voltages, np.ones(window_size)/window_size, mode='same')
    else:
        smoothed_voltages = voltages
        
    # Plot the raw and smoothed trace
    plt.figure(figsize=(15, 5))
    plt.plot(frames, voltages, label="Raw Max(1) Voltage", alpha=0.5, color='gray')
    plt.plot(frames, smoothed_voltages, label="Smoothed Voltage", color='blue')
    plt.title("Simple Power Analysis (SPA) Trace from Oscilloscope")
    plt.xlabel("Frame")
    plt.ylabel("Voltage (V)")
    plt.legend()
    plt.grid(True)
    
    # Save the plot
    plot_path = "attack_plot.png"
    plt.savefig(plot_path)
    print(f"Saved plot to {plot_path}")
    
    # Key extraction logic
    # This heavily depends on the data. For SPA, we look for distances between operations.
    # In rsa16_core.v:
    # Bit 0 -> Square only
    # Bit 1 -> Square + Multiply
    # Since Multiply takes extra time, the distance to the NEXT operation will be longer for bit 1.
    
    # To properly extract, we normally find peaks or valleys (when the operation starts/stops)
    # Since we don't have the data yet, we will just print out the array 
    # to let the user visually inspect or adjust the threshold.
    
    print("--- SPA KEY RECOVERY ---")
    print("Please inspect attack_plot.png to see the S and M blocks.")
    print("A short duration between blocks corresponds to a '0' bit (Square).")
    print("A long duration between blocks corresponds to a '1' bit (Square + Multiply).")
    
    print("\nExpected Key: 16'd2753 -> Binary: 0000 1010 1100 0001")
    print("Expected Pattern (Left to Right):")
    print("Bits 15 to 0: 0 0 0 0 1 0 1 0 1 1 0 0 0 0 0 1")
    print("Operations: S S S S SM S SM S SM SM S S S S S SM")
    
if __name__ == "__main__":
    analyze_trace('trace.csv')
