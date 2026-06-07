# RSA Simple Power Analysis (SPA) Plan

## Overview
The goal of this project is to perform a Simple Power Analysis (SPA) attack on a 16-bit RSA implementation running on an Altera DE2-115 FPGA. By analyzing the voltage variations across a 0.5 Ω shunt resistor recorded on an oscilloscope (`IMG_6324.MOV`), we will exploit the time-varying nature of the "Square-and-Multiply" algorithm to extract the secret private key.

The provided Verilog code for `rsa16_core.v` uses a Left-to-Right Binary Exponentiation without constant-time execution:
- Bit `0`: Executes **Square** (~16 cycles of `modmul16`)
- Bit `1`: Executes **Square** and then **Multiply** (~32 cycles of `modmul16`)

This distinct timing difference will be visible in the power trace, allowing us to decode the secret exponent bit by bit.

> [!IMPORTANT]
> **User Review Required**: We will use Python with OpenCV (`cv2`) to process the `IMG_6324.MOV` video, either by OCR on the "Max(1):" text or by tracking the oscilloscope trace graph pixels to generate a time-series voltage array. Is this approach acceptable to you?

## Project Type
**BACKEND** (Analysis Scripting)

## Success Criteria
1. Successfully extract the time-series voltage/power data from the `IMG_6324.MOV` video.
2. Clean and plot the data to clearly visualize the Square (S) and Multiply (M) blocks.
3. Decode the binary sequence from the trace.
4. Verify the recovered key matches the known `SECRET_EXP` parameter (`16'd2753` -> `0000_1010_1100_0001`).

## Tech Stack
- **Language**: Python 3
- **Libraries**: `OpenCV` (cv2) for video processing, `NumPy` for data manipulation, `Matplotlib` for plotting, `pytesseract` (optional, if OCR is needed for text extraction).

## File Structure
```text
.
├── rsa-power-analysis.md         # This plan file
├── scripts/
│   ├── extract_video_trace.py    # Python script to extract voltage data from the video
│   └── spa_key_recovery.py       # Script to plot and decode the sequence
└── artifacts/
    ├── power_trace.csv           # Extracted raw trace data
    └── attack_plot.png           # Plotted graph with annotations
```

## Task Breakdown

| Task | Agent | Skills | Priority | Dependencies | INPUT → OUTPUT → VERIFY |
|------|-------|--------|----------|--------------|-------------------------|
| **1. Setup Data Extraction** | `backend-specialist` | `python-patterns` | P0 | None | **IN**: `IMG_6324.MOV` → **OUT**: `extract_video_trace.py` that processes frames and extracts "Max(1):" variations or graph peaks → **VERIFY**: Generates a valid CSV with time and voltage values. |
| **2. Signal Processing & Plotting** | `backend-specialist` | `python-patterns` | P1 | Task 1 | **IN**: CSV data → **OUT**: `spa_key_recovery.py` which filters noise and plots the trace → **VERIFY**: The generated graph clearly shows short blocks (S) and long blocks (SM). |
| **3. Key Extraction** | `backend-specialist` | `python-patterns` | P2 | Task 2 | **IN**: Cleaned trace data → **OUT**: Decoding algorithm in `spa_key_recovery.py` → **VERIFY**: Extracted binary sequence exactly matches `0000_1010_1100_0001` (2753). |

## Phase X: Verification
- [ ] Run `extract_video_trace.py` and ensure data is captured successfully.
- [ ] Check the `attack_plot.png` to visually confirm SPA leakage (distinct patterns for bit `0` and bit `1`).
- [ ] Ensure the script outputs the exact expected key.
- [ ] Present the final plot and the recovered key to the user.

## ✅ PHASE X COMPLETE
*(To be filled when all tasks and scripts pass successfully)*
