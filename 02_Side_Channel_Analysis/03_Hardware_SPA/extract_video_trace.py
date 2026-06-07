import cv2
import numpy as np
import pytesseract
import re
import csv
import sys
import os

def process_video(video_path, output_csv):
    if not os.path.exists(video_path):
        print(f"Error: Video file {video_path} not found.")
        return

    cap = cv2.VideoCapture(video_path)
    if not cap.isOpened():
        print(f"Failed to open {video_path}")
        return

    fps = cap.get(cv2.CAP_PROP_FPS)
    total_frames = int(cap.get(cv2.CAP_PROP_FRAME_COUNT))
    width = int(cap.get(cv2.CAP_PROP_FRAME_WIDTH))
    height = int(cap.get(cv2.CAP_PROP_FRAME_HEIGHT))
    
    print(f"Video Info: {width}x{height}, {fps} FPS, {total_frames} total frames")
    
    # Analyze the bottom right quadrant where "Max(1):" is located
    x_start = int(width * 0.5)
    y_start = int(height * 0.5)
    
    data = []
    
    frame_idx = 0
    # To speed up, we process every 10th frame
    frame_skip = 10 
    
    while True:
        ret, frame = cap.read()
        if not ret:
            break
            
        if frame_idx % frame_skip == 0:
            roi = frame[y_start:height, x_start:width]
            
            # Convert to grayscale and threshold to isolate the bright oscilloscope text
            gray = cv2.cvtColor(roi, cv2.COLOR_BGR2GRAY)
            
            # Oscilloscope text is usually bright on dark background.
            # We can use binary thresholding or Otsu's
            _, thresh = cv2.threshold(gray, 180, 255, cv2.THRESH_BINARY)
            
            # Run tesseract
            # psm 6 assumes a single uniform block of text
            text = pytesseract.image_to_string(thresh, config='--psm 6')
            
            # Handle newlines and ignore non-digits before the actual voltage value
            # e.g., 'Max(1):\n_279mV' -> extracts '279'
            match = re.search(r'Max\(\s*1\):\s*[^0-9]*(\d+)', text, re.IGNORECASE | re.DOTALL)
            
            if match:
                try:
                    val = float(match.group(1))
                    data.append((frame_idx, val))
                    if len(data) % 10 == 0:
                        print(f"Frame {frame_idx}/{total_frames}: Extracted Max(1) = {val} mV", flush=True)
                except ValueError:
                    pass
            else:
                # If thresholding fails, try directly on gray
                text_gray = pytesseract.image_to_string(gray, config='--psm 6')
                match_gray = re.search(r'Max\(\s*1\):\s*[^0-9]*(\d+)', text_gray, re.IGNORECASE | re.DOTALL)
                if match_gray:
                    try:
                        val = float(match_gray.group(1))
                        data.append((frame_idx, val))
                        if len(data) % 10 == 0:
                            print(f"Frame {frame_idx}/{total_frames}: Extracted Max(1) = {val} mV (from gray)", flush=True)
                    except ValueError:
                        pass
                
        frame_idx += 1

    cap.release()
    
    print(f"\nProcessing complete. Found {len(data)} valid data points out of {total_frames} frames.")
    
    with open(output_csv, 'w', newline='') as f:
        writer = csv.writer(f)
        writer.writerow(['frame', 'voltage'])
        writer.writerows(data)
        
    print(f"Saved trace data to {output_csv}")

if __name__ == "__main__":
    video_file = '../IMG_6324.MOV'
    csv_file = 'trace.csv'
    process_video(video_file, csv_file)
