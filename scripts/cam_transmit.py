import cv2
import serial
import numpy as np

SERIAL_PORT = 'COM8'
BAUD_RATE = 921600
SYNC_BYTE = 0x55

# Amplification factor for enhancing faint DoG contrast
AMPLIFIER_GAIN = 8

try:
    ser = serial.Serial(SERIAL_PORT, BAUD_RATE, timeout=2)  # 2 sec timeout for safety
    print(f"Connected to {SERIAL_PORT}")
except Exception as e:
    print(f"Error: {e}")
    exit()

cap = cv2.VideoCapture(0)

try:
    while True:
        ret, frame = cap.read()
        if not ret:
            break

        # --- 1. SEND ---
        gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)
        resized = cv2.resize(gray, (128, 128), interpolation=cv2.INTER_AREA)
        resized[resized == SYNC_BYTE] = 0x54  # Filter sync byte collisions

        # Flush input buffer before sending to avoid stale data
        ser.reset_input_buffer()
        ser.write(bytearray([SYNC_BYTE]) + resized.tobytes())

        # --- 2. RECEIVE ---
        # Wait for FPGA sync byte
        sync_found = False
        while not sync_found:
            byte_in = ser.read(1)
            if len(byte_in) == 0:
                print("Timeout waiting for FPGA...")
                break
            if byte_in[0] == SYNC_BYTE:
                sync_found = True

        if sync_found:
            # Read exactly one processed frame
            dog_bytes = ser.read(16384)

            if len(dog_bytes) == 16384:
                # Convert received bytes into image
                dog_img = np.frombuffer(dog_bytes, dtype=np.uint8).reshape((128, 128))

                # Optional debug: print center sample values
                print("Raw FPGA DoG Data (centered at 128):")
                print(dog_img[61:66, 61:66])
                print("-" * 20)

                # --- APPLY AMPLIFICATION ---
                # Convert centered uint8 data into signed range
                dog_signed = dog_img.astype(np.int16) - 128

                # Amplify subtle DoG differences
                dog_amplified = dog_signed * AMPLIFIER_GAIN

                # Shift back to displayable uint8 range
                dog_display = (dog_amplified + 128).clip(0, 255).astype(np.uint8)

                # --- 3. DISPLAY ---
                combined = np.hstack((resized, dog_display))
                cv2.imshow(
                    'Left: Raw | Right: FPGA DoG Processing (Amplified)',
                    combined
                )
            else:
                print(f"Frame dropped: Expected 16384, got {len(dog_bytes)}")

        if cv2.waitKey(1) & 0xFF == ord('q'):
            break

finally:
    cap.release()
    ser.close()
    cv2.destroyAllWindows()
