# import cv2
# import serial
# import numpy as np

# # Configure UART: Use the highest stable baud rate for Basys 3
# # Change 'COM3' to your specific port (e.g., /dev/ttyUSB1 on Linux)
# BAUD_RATE = 921600
# try:
#     ser = serial.Serial('COM8', BAUD_RATE, timeout=1)
#     print(f"Connected to port at {BAUD_RATE} baud.")
# except Exception as e:
#     print(f"Failed to connect: {e}")
#     exit()

# cap = cv2.VideoCapture(0)

# while True:
#     ret, frame = cap.read()
#     if not ret:
#         break

#     # 1. Convert to Grayscale and Resize to 128x128
#     gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)
#     resized = cv2.resize(gray, (128, 128), interpolation=cv2.INTER_AREA)

#     # 2. Prevent Sync Byte Collision
#     # If a pixel naturally equals our sync byte (0x55 / 85), change it to 84.
#     resized[resized == 0x55] = 0x54

#     # 3. Transmit Data
#     # Send the Sync Byte first, followed by the raw 16,384 bytes of image data
#     ser.write(bytearray([0x55])) 
#     ser.write(resized.tobytes())

#     # Preview on Laptop
#     cv2.imshow('Sending to FPGA (128x128)', resized)
#     if cv2.waitKey(1) & 0xFF == ord('q'):
#         break

# cap.release()
# ser.close()
# cv2.destroyAllWindows()


# import cv2
# import serial
# import numpy as np

# # Configure UART: Use the highest stable baud rate for Basys 3
# # Change 'COM3' to your specific port (e.g., /dev/ttyUSB1 on Linux)
# BAUD_RATE = 921600
# try:
#     ser = serial.Serial('COM8', BAUD_RATE, timeout=1)
#     print(f"Connected to port at {BAUD_RATE} baud.")
# except Exception as e:
#     print(f"Failed to connect: {e}")
#     exit()

# cap = cv2.VideoCapture(0)

# while True:
#     ret, frame = cap.read()
#     if not ret:
#         break

#     # 1. Convert to Grayscale and Resize to 128x128
#     gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)
#     resized = cv2.resize(gray, (128, 128), interpolation=cv2.INTER_AREA)

#     # 2. Prevent Sync Byte Collision
#     # If a pixel naturally equals our sync byte (0x55 / 85), change it to 84.
#     resized[resized == 0x55] = 0x54

#     # 3. Transmit Data
#     # Send the Sync Byte first, followed by the raw 16,384 bytes of image data
#     ser.write(bytearray([0x55])) 
#     ser.write(resized.tobytes())

#     # Preview on Laptop
#     cv2.imshow('Sending to FPGA (128x128)', resized)
#     if cv2.waitKey(1) & 0xFF == ord('q'):
#         break

# cap.release()
# ser.close()
# cv2.destroyAllWindows()

# import serial
# import time
# from PIL import Image

# # --- Configuration ---
# SERIAL_PORT = 'COM8' 
# BAUD_RATE = 115200
# IMAGE_PATH = r'D:\SIFT-FPGA-Basys3\data\image.png'
# WIDTH = 128
# HEIGHT = 128
# SYNC_BYTE = b'\x55' # 0x55 as defined in top.v

# def send_image():
#     try:
#         # 1. Initialize Serial Connection
#         print(f"Connecting to {SERIAL_PORT} at {BAUD_RATE} baud...")
#         ser = serial.Serial(SERIAL_PORT, BAUD_RATE, timeout=1)
#         time.sleep(2) # Give the connection a moment to stabilize

#         # 2. Process the Image
#         print(f"Loading and resizing {IMAGE_PATH}...")
#         img = Image.open(IMAGE_PATH).convert('L') # Convert to Grayscale ('L')
#         img = img.resize((WIDTH, HEIGHT))        # Resize to 128x128
#         pixel_data = list(img.getdata())         # Get flat list of 16,384 pixels

#         # 3. Send Sync Byte
#         # This tells the FPGA to reset the write_addr to 0
#         print("Sending sync byte...")
#         ser.write(SYNC_BYTE)
        
#         # Small delay to ensure the FPGA processes the sync
#         time.sleep(0.01)

#         # 4. Send Pixel Data
#         print(f"Sending {len(pixel_data)} pixels...")
#         # Convert list to bytes and send
#         ser.write(bytes(pixel_data))

#         print("Transmission complete!")
#         ser.close()

#     except Exception as e:
#         print(f"Error: {e}")

# if __name__ == "__main__":
#     send_image()
    
# import cv2
# import serial
# import time
# import numpy as np

# # --- CONFIGURATION ---
# # Replace 'COM8' with your actual port (e.g., '/dev/ttyUSB0' on Linux)
# SERIAL_PORT = 'COM8' 
# BAUD_RATE = 921600
# SYNC_BYTE = 0x55  # Decimal 85

# try:
#     ser = serial.Serial(SERIAL_PORT, BAUD_RATE, timeout=1)
#     print(f"Connected to {SERIAL_PORT} at {BAUD_RATE} baud.")
# except Exception as e:
#     print(f"Error: Could not open serial port: {e}")
#     exit()

# cap = cv2.VideoCapture(0)

# if not cap.isOpened():
#     print("Error: Could not open webcam.")
#     exit()

# print("Streaming... Press 'q' to quit.")

# try:
#     while True:
#         ret, frame = cap.read()
#         if not ret:
#             break

#         # 1. Pre-processing
#         # Convert to Grayscale and resize to 128x128
#         gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)
#         resized = cv2.resize(gray, (128, 128), interpolation=cv2.INTER_AREA)

#         # 2. Prevent Sync Byte Collision
#         # If any pixel is 85 (0x55), change it to 84 (0x54).
#         # This ensures the FPGA only sees 0x55 at the start of a frame.
#         resized[resized == SYNC_BYTE] = 0x54

#         # 3. Packaging and Sending
#         # [Sync Byte] + [16384 bytes of image data]
#         payload = bytearray([SYNC_BYTE]) + resized.tobytes()
        
#         ser.write(payload)

#         # 4. Local Preview
#         cv2.imshow('PC Preview (Original)', resized)

#         # Press 'q' to exit
#         if cv2.waitKey(1) & 0xFF == ord('q'):
#             break

# finally:
#     cap.release()
#     ser.close()
#     cv2.destroyAllWindows()
#     print("Serial connection closed.")

# import cv2
# import serial
# import numpy as np

# SERIAL_PORT = 'COM8'
# BAUD_RATE = 921600
# SYNC_BYTE = 0x55

# # Amplification factor for enhancing faint DoG contrast
# AMPLIFIER_GAIN = 8

# try:
#     ser = serial.Serial(SERIAL_PORT, BAUD_RATE, timeout=2)  # 2 sec timeout for safety
#     print(f"Connected to {SERIAL_PORT}")
# except Exception as e:
#     print(f"Error: {e}")
#     exit()

# cap = cv2.VideoCapture(0)

# try:
#     while True:
#         ret, frame = cap.read()
#         if not ret:
#             break

#         # --- 1. SEND ---
#         gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)
#         resized = cv2.resize(gray, (128, 128), interpolation=cv2.INTER_AREA)
#         resized[resized == SYNC_BYTE] = 0x54  # Filter sync byte collisions

#         # Flush input buffer before sending to avoid stale data
#         ser.reset_input_buffer()
#         ser.write(bytearray([SYNC_BYTE]) + resized.tobytes())

#         # --- 2. RECEIVE ---
#         # Wait for FPGA sync byte
#         sync_found = False
#         while not sync_found:
#             byte_in = ser.read(1)
#             if len(byte_in) == 0:
#                 print("Timeout waiting for FPGA...")
#                 break
#             if byte_in[0] == SYNC_BYTE:
#                 sync_found = True

#         if sync_found:
#             # Read exactly one processed frame
#             dog_bytes = ser.read(16384)

#             if len(dog_bytes) == 16384:
#                 # Convert received bytes into image
#                 dog_img = np.frombuffer(dog_bytes, dtype=np.uint8).reshape((128, 128))

#                 # Optional debug: print center sample values
#                 print("Raw FPGA DoG Data (centered at 128):")
#                 print(dog_img[61:66, 61:66])
#                 print("-" * 20)

#                 # --- APPLY AMPLIFICATION ---
#                 # Convert centered uint8 data into signed range
#                 dog_signed = dog_img.astype(np.int16) - 128

#                 # Amplify subtle DoG differences
#                 dog_amplified = dog_signed * AMPLIFIER_GAIN

#                 # Shift back to displayable uint8 range
#                 dog_display = (dog_amplified + 128).clip(0, 255).astype(np.uint8)

#                 # --- 3. DISPLAY ---
#                 combined = np.hstack((resized, dog_display))
#                 cv2.imshow(
#                     'Left: Raw | Right: FPGA DoG Processing (Amplified)',
#                     combined
#                 )
#             else:
#                 print(f"Frame dropped: Expected 16384, got {len(dog_bytes)}")

#         if cv2.waitKey(1) & 0xFF == ord('q'):
#             break

# finally:
#     cap.release()
#     ser.close()
#     cv2.destroyAllWindows()

# import cv2
# import serial
# import numpy as np
# import time

# SERIAL_PORT = 'COM8' 
# BAUD_RATE = 921600
# SYNC_BYTE = 0x55
# AMPLIFIER_GAIN = 8

# # The exact sequence of sizes the FPGA will transmit
# # Octave 1 (3 scales of 128x128), Octave 2 (3 scales of 64x64)
# PYRAMID_DIMS = [(128, 128), (128, 128), (128, 128), (64, 64), (64, 64), (64, 64)]

# def wait_for_sync(ser):
#     start_time = time.time()
#     while time.time() - start_time < 1.0:
#         if ser.in_waiting > 0:
#             header = ser.read(1)
#             if header[0] == SYNC_BYTE:
#                 return True
#     return False

# def read_dog_frame(ser, dim_tuple):
#     w, h = dim_tuple
#     expected_bytes = w * h
    
#     if not wait_for_sync(ser):
#         return None

#     raw_data = ser.read(expected_bytes)
#     if len(raw_data) != expected_bytes:
#         return None

#     # Convert, center, and amplify
#     dog_img = np.frombuffer(raw_data, dtype=np.uint8).reshape((h, w))
#     dog_signed = dog_img.astype(np.int16) - 128
#     dog_amplified = (dog_signed * AMPLIFIER_GAIN) + 128
#     dog_final = np.clip(dog_amplified, 0, 255).astype(np.uint8)
#     return dog_final

# def run_sift_bridge():
#     try:
#         ser = serial.Serial(SERIAL_PORT, BAUD_RATE, timeout=1)
#         print(f"Connected to {SERIAL_PORT}")
#     except Exception as e:
#         print(f"Connection Error: {e}")
#         return

#     cap = cv2.VideoCapture(0)
#     time.sleep(2)

#     while True:
#         ret, frame = cap.read()
#         if not ret: break

#         # Pre-process
#         gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)
#         resized = cv2.resize(gray, (128, 128), interpolation=cv2.INTER_AREA)
#         resized[resized == SYNC_BYTE] = 0x54 # Sync protection

#         # Transmit Base Image
#         ser.write(bytearray([SYNC_BYTE]))
#         ser.write(resized.tobytes())

#         # Receive the 6 Pyramid Layers
#         pyramid_frames = []
#         timeout_flag = False
        
#         for dim in PYRAMID_DIMS:
#             dog = read_dog_frame(ser, dim)
#             if dog is None:
#                 print(f"Timeout/Drop at dimension {dim}. Resetting.")
#                 timeout_flag = True
#                 break
#             pyramid_frames.append(dog)

#         if not timeout_flag:
#             # Build the Display Grid
#             # Upscale the 64x64 Octave 2 images back to 128x128 for easy viewing
#             o1_s1, o1_s2, o1_s3 = pyramid_frames[0:3]
#             o2_s1 = cv2.resize(pyramid_frames[3], (128, 128), interpolation=cv2.INTER_NEAREST)
#             o2_s2 = cv2.resize(pyramid_frames[4], (128, 128), interpolation=cv2.INTER_NEAREST)
#             o2_s3 = cv2.resize(pyramid_frames[5], (128, 128), interpolation=cv2.INTER_NEAREST)

#             # Assemble Rows
#             top_row = np.hstack((resized, o1_s1, o1_s2, o1_s3))
#             bottom_row = np.hstack((np.zeros((128, 128), dtype=np.uint8), o2_s1, o2_s2, o2_s3))
#             grid = np.vstack((top_row, bottom_row))

#             cv2.imshow('FPGA 2-Octave, 3-Scale DoG Pyramid', grid)

#         if cv2.waitKey(1) & 0xFF == ord('q'):
#             break

#     cap.release()
#     ser.close()
#     cv2.destroyAllWindows()

# if __name__ == "__main__":
#     run_sift_bridge()

# ---------------------

# import cv2
# import serial
# import numpy as np
# import time

# # -------- CONFIG --------
# SERIAL_PORT = 'COM8'
# BAUD_RATE = 921600
# SYNC_BYTE = 0x55
# IMAGE_PATH = r'D:\SIFT-FPGA-Basys3\data\image.png'
# AMPLIFIER_GAIN = 8

# PYRAMID_DIMS = [
#     (128, 128), (128, 128), (128, 128),
#     (64, 64), (64, 64), (64, 64)
# ]
# # ------------------------

# def wait_for_sync(ser):
#     while True:
#         b = ser.read(1)
#         if len(b) and b[0] == SYNC_BYTE:
#             return True

# def read_frame(ser, size):
#     wait_for_sync(ser)
#     data = ser.read(size)
#     if len(data) != size:
#         return None
#     return data

# def main():
#     # Load fixed image
#     img = cv2.imread(IMAGE_PATH, cv2.IMREAD_GRAYSCALE)
#     if img is None:
#         print("Image load failed")
#         return

#     img = cv2.resize(img, (128, 128), interpolation=cv2.INTER_AREA)
#     img[img == SYNC_BYTE] = 0x54  # sync protection

#     try:
#         ser = serial.Serial(SERIAL_PORT, BAUD_RATE, timeout=2)
#         print("Connected")
#     except Exception as e:
#         print("Serial error:", e)
#         return

#     time.sleep(2)

#     while True:
#         # Clean buffer (VERY IMPORTANT)
#         ser.reset_input_buffer()

#         # Send base image
#         ser.write(bytearray([SYNC_BYTE]))
#         ser.write(img.tobytes())

#         pyramid = []
#         failed = False

#         for (w, h) in PYRAMID_DIMS:
#             raw = read_frame(ser, w * h)
#             if raw is None:
#                 print("Frame drop")
#                 failed = True
#                 break
#             frame = np.frombuffer(raw, dtype=np.uint8).reshape((h, w))
#             pyramid.append(frame)

#         if failed:
#             continue

#         # -------- TAKE ONLY FIRST DoG --------
#         dog = pyramid[0]

#         # -------- IDENTICAL PROCESSING --------
#         dog_signed = dog.astype(np.int16) - 128
#         dog_amp = dog_signed * AMPLIFIER_GAIN
#         dog_display = np.clip(dog_amp + 128, 0, 255).astype(np.uint8)
#         # -------------------------------------

#         combined = np.hstack((img, dog_display))
#         cv2.imshow("RTL2: Input | DoG1", combined)

#         if cv2.waitKey(0) & 0xFF == ord('q'):
#             break

#     ser.close()
#     cv2.destroyAllWindows()

# if __name__ == "__main__":
#     main()


###############


# import cv2
# import serial
# import numpy as np
# import time

# # -------- CONFIG --------
# SERIAL_PORT = 'COM8'
# BAUD_RATE = 921600
# SYNC_BYTE = 0x55
# IMAGE_PATH = r'multi_region_dataset/region_02/frame_023.png'
# TEMPLATE_PATH = r'multi_region_dataset\region_02\template.png'
# AMPLIFIER_GAIN = 8
# # ------------------------

# def wait_for_sync(ser):
#     while True:
#         b = ser.read(1)
#         if len(b) and b[0] == SYNC_BYTE:
#             return True

# def main():
#     # Load fixed image
#     img = cv2.imread(IMAGE_PATH, cv2.IMREAD_GRAYSCALE)
#     if img is None:
#         print("Image load failed")
#         return

#     img = cv2.resize(img, (128, 128), interpolation=cv2.INTER_AREA)
#     img[img == SYNC_BYTE] = 0x54  # sync protection

#     try:
#         ser = serial.Serial(SERIAL_PORT, BAUD_RATE, timeout=2)
#         print("Connected")
#     except Exception as e:
#         print("Serial error:", e)
#         return

#     time.sleep(2)

#     while True:
#         # Clean buffer
#         ser.reset_input_buffer()

#         # Send frame
#         ser.write(bytearray([SYNC_BYTE]) + img.tobytes())

#         # Wait for FPGA response
#         wait_for_sync(ser)

#         # Read DoG (single frame)
#         raw = ser.read(128 * 128)
#         if len(raw) != 128 * 128:
#             print("Frame error")
#             continue

#         dog = np.frombuffer(raw, dtype=np.uint8).reshape((128, 128))

#         # -------- IDENTICAL PROCESSING --------
#         dog_signed = dog.astype(np.int16) - 128
#         dog_amp = dog_signed * AMPLIFIER_GAIN
#         dog_display = np.clip(dog_amp + 128, 0, 255).astype(np.uint8)
#         # -------------------------------------

#         combined = np.hstack((img, dog_display))
#         cv2.imshow("RTL1: Input | DoG", combined)

#         if cv2.waitKey(0) & 0xFF == ord('q'):
#             break

#     ser.close()
#     cv2.destroyAllWindows()

# if __name__ == "__main__":
#     main()

# import cv2
# import serial
# import numpy as np
# import time
# import os

# # ==============================
# # CONFIG
# # ==============================

# SERIAL_PORT = 'COM8'
# BAUD_RATE = 921600
# SYNC_BYTE = 0x55

# REGION_DIR = r"D:\SIFT-FPGA-Basys3\multi_region_dataset\region_02"
# TEMPLATE_PATH = os.path.join(REGION_DIR, "template.png")

# FRAME_IDXS = list(range(0, 25, 3))
# AMPLIFIER_GAIN = 8

# OUT_DIR = os.path.join(REGION_DIR, "inference_results_final")
# os.makedirs(OUT_DIR, exist_ok=True)

# print("Saving results to:", OUT_DIR)

# # ==============================
# # SERIAL HELPERS
# # ==============================

# def wait_for_sync(ser):
#     while True:
#         b = ser.read(1)
#         if len(b) and b[0] == SYNC_BYTE:
#             return True

# def preprocess_for_send(img):
#     img = cv2.resize(img, (128, 128))
#     img = img.copy()
#     img[img == SYNC_BYTE] = 0x54
#     return img

# def send_and_receive(ser, img):
#     ser.reset_input_buffer()
#     ser.write(bytearray([SYNC_BYTE]) + img.tobytes())
#     wait_for_sync(ser)

#     raw = ser.read(128 * 128)
#     if len(raw) != 128 * 128:
#         return None

#     return np.frombuffer(raw, dtype=np.uint8).reshape((128, 128))

# # ==============================
# # MATCHING PIPELINE (FINAL)
# # ==============================

# def prepare_for_matching(dog):
#     # Option 2: absolute DoG
#     dog = np.abs(dog.astype(np.float32) - 128.0)

#     # smooth
#     dog = cv2.GaussianBlur(dog, (5,5), 0)

#     # normalize
#     dog = cv2.normalize(dog, None, 0, 1, cv2.NORM_MINMAX)

#     return dog

# def apply_window(img):
#     h, w = img.shape
#     win = cv2.createHanningWindow((w, h), cv2.CV_32F)
#     return img * win

# def log_polar(img):
#     h, w = img.shape
#     center = (w//2, h//2)
#     M = w / np.log(w/2)
#     return cv2.logPolar(img, center, M,
#                         cv2.INTER_LINEAR + cv2.WARP_FILL_OUTLIERS)

# # ==============================
# # DISPLAY HELPERS
# # ==============================

# def dog_display(dog):
#     dog_signed = dog.astype(np.int16) - 128
#     dog_amp = dog_signed * AMPLIFIER_GAIN
#     return np.clip(dog_amp + 128, 0, 255).astype(np.uint8)

# def add_label(img, text):
#     img_color = cv2.cvtColor(img, cv2.COLOR_GRAY2BGR)
#     cv2.rectangle(img_color, (0, 0), (128, 22), (0, 0, 0), -1)
#     cv2.putText(img_color, text, (5, 16),
#                 cv2.FONT_HERSHEY_SIMPLEX, 0.5,
#                 (255,255,255), 1, cv2.LINE_AA)
#     return img_color

# # ==============================
# # MAIN
# # ==============================

# def main():

#     template = cv2.imread(TEMPLATE_PATH, 0)
#     if template is None:
#         print("Template load failed")
#         return

#     template = preprocess_for_send(template)

#     try:
#         ser = serial.Serial(SERIAL_PORT, BAUD_RATE, timeout=2)
#         print("Connected to FPGA")
#     except Exception as e:
#         print("Serial error:", e)
#         return

#     time.sleep(2)

#     # -------- TEMPLATE --------
#     dog_t = send_and_receive(ser, template)
#     if dog_t is None:
#         print("Template DoG failed")
#         return

#     dog_t_sig = prepare_for_matching(dog_t)
#     dog_t_sig = apply_window(dog_t_sig)
#     lp_t = log_polar(dog_t_sig)

#     dog_t_disp = dog_display(dog_t)

#     # ==============================
#     # LOOP
#     # ==============================

#     for idx in FRAME_IDXS:

#         frame_path = os.path.join(REGION_DIR, f"frame_{idx:03d}.png")
#         img = cv2.imread(frame_path, 0)

#         if img is None:
#             print("Load failed:", frame_path)
#             continue

#         img_send = preprocess_for_send(img)

#         dog = send_and_receive(ser, img_send)
#         if dog is None:
#             print("Frame error")
#             continue

#         # -------- MATCHING --------
#         dog_f_sig = prepare_for_matching(dog)
#         dog_f_sig = apply_window(dog_f_sig)

#         lp_f = log_polar(dog_f_sig)

#         shift, response = cv2.phaseCorrelate(lp_f, lp_t)

#         print(f"Frame {idx}: response={response:.3f}, shift={shift}")

#         # -------- DISPLAY --------
#         dog_disp = dog_display(dog)

#         lp_f_disp = cv2.normalize(lp_f, None, 0, 255, cv2.NORM_MINMAX).astype(np.uint8)
#         lp_t_disp = cv2.normalize(lp_t, None, 0, 255, cv2.NORM_MINMAX).astype(np.uint8)

#         p1 = add_label(img_send, "Frame")
#         p2 = add_label(template, "Template")

#         p3 = add_label(dog_disp, "DoG Frame")
#         p4 = add_label(dog_t_disp, "DoG Template")

#         p5 = add_label(lp_f_disp, "Log-Polar Frame")
#         p6 = add_label(lp_t_disp, "Log-Polar Template")

#         row1 = np.hstack((p1, p2))
#         row2 = np.hstack((p3, p4))
#         row3 = np.hstack((p5, p6))

#         combined = np.vstack((row1, row2, row3))

#         # -------- TITLE + SCORE --------
#         canvas = np.zeros((combined.shape[0] + 40, combined.shape[1], 3), dtype=np.uint8)
#         canvas[40:] = combined

#         color = (0,255,0) if response > 0.3 else (0,0,255)

#         title = f"Frame {idx} | Score: {response:.3f}"
#         cv2.putText(canvas, title, (10, 28),
#                     cv2.FONT_HERSHEY_SIMPLEX, 0.7,
#                     color, 2, cv2.LINE_AA)

#         # -------- SHOW --------
#         cv2.imshow("TRN Matching (FINAL)", canvas)

#         # -------- SAVE --------
#         save_path = os.path.join(OUT_DIR, f"result_{idx:03d}.png")
#         cv2.imwrite(save_path, canvas)

#         print("Saved:", save_path)

#         if cv2.waitKey(300) & 0xFF == ord('q'):
#             break

#     ser.close()
#     cv2.destroyAllWindows()

#     print("\nDONE")

# # ==============================

# if __name__ == "__main__":
#     main()


# import cv2
# import serial
# import numpy as np
# import time
# import os
# import csv
# import matplotlib.pyplot as plt
# import sys
# import io

# # ==============================
# # CONFIG
# # ==============================

# SERIAL_PORT = 'COM8'
# BAUD_RATE = 2000000 # 921600
# SYNC_BYTE = 0x55

# DATASET_DIR = r"D:\SIFT-FPGA-Basys3\multi_region_dataset"
# OUT_DIR = r"D:\SIFT-FPGA-Basys3\fpga_evaluation"
# os.makedirs(OUT_DIR, exist_ok=True)

# NUM_REGIONS = 10
# FRAMES_PER_REGION = 25
# THRESHOLD = 0.5

# # ==============================
# # TERMINAL LOGGING
# # ==============================

# class Tee:
#     def __init__(self, *files):
#         self.files = files
#     def write(self, obj):
#         for f in self.files:
#             f.write(obj)
#             f.flush()
#     def flush(self):
#         for f in self.files:
#             f.flush()

# log_file = open(os.path.join(OUT_DIR, "terminal_log.txt"), "w", encoding="utf-8")
# sys.stdout = Tee(sys.stdout, log_file)

# # ==============================
# # SERIAL
# # ==============================

# def wait_for_sync(ser):
#     while True:
#         b = ser.read(1)
#         if len(b) and b[0] == SYNC_BYTE:
#             return True

# def preprocess_for_send(img):
#     img = cv2.resize(img, (128, 128))
#     img = img.copy()
#     img[img == SYNC_BYTE] = 0x54
#     return img

# def send_to_fpga(ser, img):
#     ser.reset_input_buffer()
#     ser.write(bytearray([SYNC_BYTE]) + img.tobytes())
#     wait_for_sync(ser)

#     raw = ser.read(128*128)
#     if len(raw) != 128*128:
#         return None

#     return np.frombuffer(raw, dtype=np.uint8).reshape((128,128))

# # ==============================
# # MATCHING SIGNAL (OPTION 2)
# # ==============================

# def prepare_for_matching(dog):
#     dog = np.abs(dog.astype(np.float32) - 128.0)
#     dog = cv2.GaussianBlur(dog, (5,5), 0)
#     dog = cv2.normalize(dog, None, 0, 1, cv2.NORM_MINMAX)
#     return dog

# # ==============================
# # AUGMENTATIONS
# # ==============================

# def add_noise(img):
#     noise = np.random.normal(0, 10, img.shape)
#     return np.clip(img + noise, 0, 255).astype(np.uint8)

# def rotate(img):
#     M = cv2.getRotationMatrix2D((64,64), 8, 1.0)
#     return cv2.warpAffine(img, M, (128,128),
#                           borderMode=cv2.BORDER_REFLECT)

# def change_brightness(img):
#     return np.clip(img * 1.2 + 10, 0, 255).astype(np.uint8)

# # ==============================
# # MAIN
# # ==============================

# def main():

#     # connect FPGA
#     try:
#         ser = serial.Serial(SERIAL_PORT, BAUD_RATE, timeout=2)
#         print("Connected to FPGA")
#     except Exception as e:
#         print("Serial error:", e)
#         return

#     time.sleep(2)

#     csv_path = os.path.join(OUT_DIR, "results.csv")

#     with open(csv_path, "w", newline="") as f:
#         writer = csv.writer(f)
#         writer.writerow(["region","frame","variant","score","decision"])

#         all_scores = []

#         # ==============================
#         # LOOP ALL REGIONS
#         # ==============================

#         for r in range(NUM_REGIONS):

#             print(f"\n--- REGION {r} ---")

#             region_path = os.path.join(DATASET_DIR, f"region_{r:02d}")

#             template = cv2.imread(os.path.join(region_path, "template.png"), 0)
#             template = preprocess_for_send(template)

#             # FPGA DoG for template
#             dog_t = send_to_fpga(ser, template)
#             if dog_t is None:
#                 print("Template FPGA error")
#                 continue

#             template_sig = prepare_for_matching(dog_t)

#             region_scores = []

#             # ==============================
#             # LOOP FRAMES
#             # ==============================

#             for i in range(FRAMES_PER_REGION):

#                 frame = cv2.imread(os.path.join(region_path, f"frame_{i:03d}.png"), 0)

#                 variants = {
#                     "original": frame,
#                     "noise": add_noise(frame),
#                     "rotated": rotate(frame),
#                     "brightness": change_brightness(frame)
#                 }

#                 for name, var_img in variants.items():

#                     img_send = preprocess_for_send(var_img)

#                     # FPGA DoG
#                     dog = send_to_fpga(ser, img_send)
#                     if dog is None:
#                         print("FPGA error")
#                         continue

#                     frame_sig = prepare_for_matching(dog)

#                     # NCC
#                     res = cv2.matchTemplate(frame_sig, template_sig,
#                                             cv2.TM_CCOEFF_NORMED)
#                     score = float(res.max())

#                     decision = 1 if score > THRESHOLD else 0

#                     writer.writerow([r, i, name, score, decision])

#                     region_scores.append(score)
#                     all_scores.append(score)

#                     print(f"R{r} F{i} {name}: {score:.3f} -> {'MATCH' if decision else 'NO'}")

#             # plot per region
#             plt.figure()
#             plt.plot(region_scores)
#             plt.title(f"Region {r} Scores")
#             plt.ylim(0,1)
#             plt.savefig(os.path.join(OUT_DIR, f"region_{r:02d}.png"))
#             plt.close()

#     # ==============================
#     # GLOBAL PLOTS
#     # ==============================

#     all_scores = np.array(all_scores)

#     plt.figure()
#     plt.hist(all_scores, bins=30)
#     plt.title("NCC Score Distribution")
#     plt.savefig(os.path.join(OUT_DIR, "histogram.png"))
#     plt.close()

#     print("\nDONE. Results saved in:", OUT_DIR)

#     ser.close()

# # ==============================

# if __name__ == "__main__":
#     main()

import cv2
import serial
import numpy as np
import time
import os
import csv
import matplotlib.pyplot as plt
import sys
import io

# ==============================
# CONFIG
# ==============================

SERIAL_PORT = 'COM8'
BAUD_RATE = 2000000 # 921600
SYNC_BYTE = 0x55

DATASET_DIR = r"D:\SIFT-FPGA-Basys3\multi_region_dataset"
OUT_DIR = r"D:\SIFT-FPGA-Basys3\fpga_evaluation"
os.makedirs(OUT_DIR, exist_ok=True)

NUM_REGIONS = 10
FRAMES_PER_REGION = 25
THRESHOLD = 0.5

# ==============================
# TERMINAL LOGGING
# ==============================

class Tee:
    def __init__(self, *files):
        self.files = files
    def write(self, obj):
        for f in self.files:
            f.write(obj)
            f.flush()
    def flush(self):
        for f in self.files:
            f.flush()

log_file = open(os.path.join(OUT_DIR, "terminal_log.txt"), "w", encoding="utf-8")
sys.stdout = Tee(sys.stdout, log_file)

# ==============================
# SERIAL
# ==============================

def wait_for_sync(ser):
    while True:
        b = ser.read(1)
        if len(b) and b[0] == SYNC_BYTE:
            return True

def preprocess_for_send(img):
    img = cv2.resize(img, (128, 128))
    img = img.copy()
    img[img == SYNC_BYTE] = 0x54
    return img

def send_to_fpga(ser, img):
    ser.reset_input_buffer()
    ser.write(bytearray([SYNC_BYTE]) + img.tobytes())
    wait_for_sync(ser)

    raw = ser.read(128*128)
    if len(raw) != 128*128:
        return None

    return np.frombuffer(raw, dtype=np.uint8).reshape((128,128))

# ==============================
# MATCHING SIGNAL (OPTION 2)
# ==============================

def prepare_for_matching(dog):
    dog = np.abs(dog.astype(np.float32) - 128.0)
    dog = cv2.GaussianBlur(dog, (5,5), 0)
    dog = cv2.normalize(dog, None, 0, 1, cv2.NORM_MINMAX)
    return dog

# ==============================
# AUGMENTATIONS
# ==============================

def add_noise(img):
    noise = np.random.normal(0, 10, img.shape)
    return np.clip(img + noise, 0, 255).astype(np.uint8)

def rotate(img):
    M = cv2.getRotationMatrix2D((64,64), 8, 1.0)
    return cv2.warpAffine(img, M, (128,128),
                          borderMode=cv2.BORDER_REFLECT)

def change_brightness(img):
    return np.clip(img * 1.2 + 10, 0, 255).astype(np.uint8)

# ==============================
# MAIN
# ==============================

def main():

    # connect FPGA
    try:
        ser = serial.Serial(SERIAL_PORT, BAUD_RATE, timeout=2)
        print("Connected to FPGA")
    except Exception as e:
        print("Serial error:", e)
        return

    time.sleep(2)

    csv_path = os.path.join(OUT_DIR, "results.csv")

    total_start_time = time.time()          # ← Overall timing start
    all_processing_times = []               # To calculate average

    with open(csv_path, "w", newline="") as f:
        writer = csv.writer(f)
        writer.writerow(["region","frame","variant","score","decision"])

        all_scores = []

        # ==============================
        # LOOP ALL REGIONS
        # ==============================

        for r in range(NUM_REGIONS):

            print(f"\n--- REGION {r} ---")
            region_start_time = time.time()     # ← Per region timing

            region_path = os.path.join(DATASET_DIR, f"region_{r:02d}")

            template = cv2.imread(os.path.join(region_path, "template.png"), 0)
            template = preprocess_for_send(template)

            # FPGA DoG for template
            dog_t = send_to_fpga(ser, template)
            if dog_t is None:
                print("Template FPGA error")
                continue

            template_sig = prepare_for_matching(dog_t)

            region_scores = []

            # ==============================
            # LOOP FRAMES
            # ==============================

            for i in range(FRAMES_PER_REGION):

                frame = cv2.imread(os.path.join(region_path, f"frame_{i:03d}.png"), 0)

                variants = {
                    "original": frame,
                    "noise": add_noise(frame),
                    "rotated": rotate(frame),
                    "brightness": change_brightness(frame)
                }

                for name, var_img in variants.items():

                    img_send = preprocess_for_send(var_img)

                    # FPGA DoG
                    dog = send_to_fpga(ser, img_send)
                    if dog is None:
                        print("FPGA error")
                        continue

                    frame_sig = prepare_for_matching(dog)

                    # NCC
                    res = cv2.matchTemplate(frame_sig, template_sig,
                                            cv2.TM_CCOEFF_NORMED)
                    score = float(res.max())

                    decision = 1 if score > THRESHOLD else 0

                    writer.writerow([r, i, name, score, decision])

                    region_scores.append(score)
                    all_scores.append(score)

                    print(f"R{r} F{i} {name}: {score:.3f} -> {'MATCH' if decision else 'NO'}")

            # Per-region time
            region_time = time.time() - region_start_time
            print(f"Region {r} completed in {region_time:.2f} seconds")

            # plot per region
            plt.figure()
            plt.plot(region_scores)
            plt.title(f"Region {r} Scores")
            plt.ylim(0,1)
            plt.savefig(os.path.join(OUT_DIR, f"region_{r:02d}.png"))
            plt.close()

    # ==============================
    # OVERALL TIMING & AVERAGE
    # ==============================

    total_time = time.time() - total_start_time
    avg_time_per_region = total_time / NUM_REGIONS if NUM_REGIONS > 0 else 0
    total_variants = NUM_REGIONS * FRAMES_PER_REGION * 4
    avg_time_per_variant = total_time / total_variants if total_variants > 0 else 0

    print("\n" + "="*50)
    print("TIMING SUMMARY")
    print("="*50)
    print(f"Total processing time          : {total_time:.2f} seconds")
    print(f"Average time per region        : {avg_time_per_region:.2f} seconds")
    print(f"Average time per variant       : {avg_time_per_variant:.3f} seconds")
    print(f"Total variants processed       : {total_variants}")
    print("="*50)

    # Global plots
    all_scores = np.array(all_scores)

    plt.figure()
    plt.hist(all_scores, bins=30)
    plt.title("NCC Score Distribution")
    plt.savefig(os.path.join(OUT_DIR, "histogram.png"))
    plt.close()

    print("\nDONE. Results saved in:", OUT_DIR)

    ser.close()

# ==============================

if __name__ == "__main__":
    main()