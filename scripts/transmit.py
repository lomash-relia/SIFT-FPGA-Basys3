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

import cv2
import serial
import numpy as np
import time

SERIAL_PORT = 'COM8' 
BAUD_RATE = 921600
SYNC_BYTE = 0x55
AMPLIFIER_GAIN = 10 

# The exact sequence of sizes the FPGA will transmit
# Octave 1 (3 scales of 128x128), Octave 2 (3 scales of 64x64)
PYRAMID_DIMS = [(128, 128), (128, 128), (128, 128), (64, 64), (64, 64), (64, 64)]

def wait_for_sync(ser):
    start_time = time.time()
    while time.time() - start_time < 1.0:
        if ser.in_waiting > 0:
            header = ser.read(1)
            if header[0] == SYNC_BYTE:
                return True
    return False

def read_dog_frame(ser, dim_tuple):
    w, h = dim_tuple
    expected_bytes = w * h
    
    if not wait_for_sync(ser):
        return None

    raw_data = ser.read(expected_bytes)
    if len(raw_data) != expected_bytes:
        return None

    # Convert, center, and amplify
    dog_img = np.frombuffer(raw_data, dtype=np.uint8).reshape((h, w))
    dog_signed = dog_img.astype(np.int16) - 128
    dog_amplified = (dog_signed * AMPLIFIER_GAIN) + 128
    dog_final = np.clip(dog_amplified, 0, 255).astype(np.uint8)
    return dog_final

def run_sift_bridge():
    try:
        ser = serial.Serial(SERIAL_PORT, BAUD_RATE, timeout=1)
        print(f"Connected to {SERIAL_PORT}")
    except Exception as e:
        print(f"Connection Error: {e}")
        return

    cap = cv2.VideoCapture(0)
    time.sleep(2)

    while True:
        ret, frame = cap.read()
        if not ret: break

        # Pre-process
        gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)
        resized = cv2.resize(gray, (128, 128), interpolation=cv2.INTER_AREA)
        resized[resized == SYNC_BYTE] = 0x54 # Sync protection

        # Transmit Base Image
        ser.write(bytearray([SYNC_BYTE]))
        ser.write(resized.tobytes())

        # Receive the 6 Pyramid Layers
        pyramid_frames = []
        timeout_flag = False
        
        for dim in PYRAMID_DIMS:
            dog = read_dog_frame(ser, dim)
            if dog is None:
                print(f"Timeout/Drop at dimension {dim}. Resetting.")
                timeout_flag = True
                break
            pyramid_frames.append(dog)

        if not timeout_flag:
            # Build the Display Grid
            # Upscale the 64x64 Octave 2 images back to 128x128 for easy viewing
            o1_s1, o1_s2, o1_s3 = pyramid_frames[0:3]
            o2_s1 = cv2.resize(pyramid_frames[3], (128, 128), interpolation=cv2.INTER_NEAREST)
            o2_s2 = cv2.resize(pyramid_frames[4], (128, 128), interpolation=cv2.INTER_NEAREST)
            o2_s3 = cv2.resize(pyramid_frames[5], (128, 128), interpolation=cv2.INTER_NEAREST)

            # Assemble Rows
            top_row = np.hstack((resized, o1_s1, o1_s2, o1_s3))
            bottom_row = np.hstack((np.zeros((128, 128), dtype=np.uint8), o2_s1, o2_s2, o2_s3))
            grid = np.vstack((top_row, bottom_row))

            cv2.imshow('FPGA 2-Octave, 3-Scale DoG Pyramid', grid)

        if cv2.waitKey(1) & 0xFF == ord('q'):
            break

    cap.release()
    ser.close()
    cv2.destroyAllWindows()

if __name__ == "__main__":
    run_sift_bridge()