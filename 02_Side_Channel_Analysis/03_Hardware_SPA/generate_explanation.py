import matplotlib.pyplot as plt
import numpy as np

def generate_annotated_plot():
    # The secret exponent is 2753 (16-bit binary: 0000 1010 1100 0001)
    # Read from Left (MSB) to Right (LSB)
    bits = [0, 0, 0, 0, 1, 0, 1, 0, 1, 1, 0, 0, 0, 0, 0, 1]
    
    # We will generate a simulated timing trace to clearly explain the concept.
    # High power = operation active. Low power = idle/transition.
    # S (Square) = 1 time unit high, 0.5 low.
    # M (Multiply) = 1 time unit high, 0.5 low.
    
    time = []
    power = []
    
    current_time = 0
    annotations = [] # Store (x, text, bit)
    
    for bit in bits:
        start_t = current_time
        
        # 1. SQUARE OPERATION (always happens)
        time.extend([current_time, current_time, current_time + 1, current_time + 1])
        power.extend([0, 1, 1, 0])
        current_time += 1.0
        
        # Idle between ops
        time.extend([current_time, current_time + 0.5])
        power.extend([0, 0])
        current_time += 0.5
        
        if bit == 1:
            # 2. MULTIPLY OPERATION (only if bit == 1)
            time.extend([current_time, current_time, current_time + 1, current_time + 1])
            power.extend([0, 1, 1, 0])
            current_time += 1.0
            
            # Idle
            time.extend([current_time, current_time + 0.5])
            power.extend([0, 0])
            current_time += 0.5
            
            mid_t = (start_t + current_time) / 2
            annotations.append((mid_t, "S + M", "1"))
        else:
            mid_t = (start_t + current_time) / 2
            annotations.append((mid_t, "S", "0"))
            
    # Plotting
    plt.figure(figsize=(18, 6))
    plt.plot(time, power, color='crimson', linewidth=2)
    plt.fill_between(time, power, color='crimson', alpha=0.3)
    
    plt.title("Simple Power Analysis (SPA) - Left-to-Right Binary Exponentiation", fontsize=16, pad=30)
    plt.xlabel("Zaman (Time)", fontsize=12)
    plt.ylabel("Güç Tüketimi (Power)", fontsize=12)
    
    plt.ylim(-0.2, 1.8)
    plt.yticks([]) # Hide y-axis numbers
    
    # Add annotations
    for (x, op_text, bit) in annotations:
        # Bit label (0 or 1) above the block
        plt.text(x, 1.3, bit, fontsize=18, fontweight='bold', ha='center', color='black', 
                 bbox=dict(facecolor='white', edgecolor='black', boxstyle='round,pad=0.2'))
        
        # Operation label (S or S+M) below the block
        plt.text(x, -0.15, op_text, fontsize=12, fontweight='bold', ha='center', color='blue')
        
    plt.tight_layout()
    plt.savefig("annotated_explanation.png", dpi=150)
    print("Saved annotated_explanation.png")

if __name__ == "__main__":
    generate_annotated_plot()
