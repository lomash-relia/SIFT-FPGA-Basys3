"""
Host driver for the Basys 3 log-polar accelerator.

    python scripts/logpolar/host.py --port COM3 --image cat.png     # single image
    python scripts/logpolar/host.py --port COM3 --webcam            # live from camera
    python scripts/logpolar/host.py --port COM3 --image cat.png --check   # diff vs model

Protocol, matching rtl/logpolar/top.v:
    PC  -> FPGA :  0x55 + 16384 payload bytes
    FPGA -> PC  :  0x55 + 16384 payload bytes

The board has no receive FIFO: while it is transforming or transmitting it
is not listening. This is therefore strictly request/response -- send one
frame, read the whole reply, then send the next. Do not pipeline.
"""
import argparse
import sys
import time

import numpy as np
import cv2
import serial

W = H = 128
NPIX = W * H
SYNC = 0x55


def preprocess(img):
    """Grayscale, resize to 128x128, and clear the sync byte from the payload."""
    if img.ndim == 3:
        img = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
    img = cv2.resize(img, (W, H), interpolation=cv2.INTER_AREA)
    img = img.copy()
    img[img == SYNC] = 0x54
    return img


def read_exact(ser, n):
    """pyserial's read() can return short. Loop until we have n bytes or time out."""
    buf = bytearray()
    while len(buf) < n:
        chunk = ser.read(n - len(buf))
        if not chunk:
            return None                     # timeout
        buf.extend(chunk)
    return bytes(buf)


def wait_for_sync(ser, timeout_s=3.0):
    """Scan the stream for the reply header, discarding anything before it."""
    deadline = time.time() + timeout_s
    while time.time() < deadline:
        b = ser.read(1)
        if b and b[0] == SYNC:
            return True
    return False


def transform_frame(ser, img):
    """Send one frame, return the transformed frame, or None on timeout."""
    ser.reset_input_buffer()
    ser.write(bytes([SYNC]) + img.tobytes())
    ser.flush()

    if not wait_for_sync(ser):
        return None
    raw = read_exact(ser, NPIX)
    if raw is None:
        return None
    return np.frombuffer(raw, dtype=np.uint8).reshape((H, W))


def annotate(img, text):
    out = cv2.cvtColor(cv2.resize(img, (384, 384),
                                  interpolation=cv2.INTER_NEAREST),
                       cv2.COLOR_GRAY2BGR)
    cv2.rectangle(out, (0, 0), (384, 26), (0, 0, 0), -1)
    cv2.putText(out, text, (6, 19), cv2.FONT_HERSHEY_SIMPLEX,
                0.55, (255, 255, 255), 1, cv2.LINE_AA)
    return out


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--port", default="COM3")
    ap.add_argument("--baud", type=int, default=921600)
    ap.add_argument("--image")
    ap.add_argument("--webcam", action="store_true")
    ap.add_argument("--check", action="store_true",
                    help="compare the board's output against the Python model")
    ap.add_argument("--save", help="write the result to this path")
    args = ap.parse_args()

    if not args.image and not args.webcam:
        ap.error("give --image PATH or --webcam")

    try:
        ser = serial.Serial(args.port, args.baud, timeout=2)
    except Exception as e:
        print(f"could not open {args.port}: {e}")
        return 1
    print(f"connected to {args.port} at {args.baud} baud")
    time.sleep(0.2)
    ser.reset_input_buffer()

    try:
        if args.webcam:
            cap = cv2.VideoCapture(0)
            if not cap.isOpened():
                print("could not open the webcam")
                return 1
            print("streaming, press q to quit")
            frames, t0 = 0, time.time()
            while True:
                ok, frame = cap.read()
                if not ok:
                    break
                src = preprocess(frame)
                dst = transform_frame(ser, src)
                if dst is None:
                    print("frame dropped (timeout); is the board in S_WAIT_SYNC?")
                    continue
                frames += 1
                fps = frames / (time.time() - t0)
                cv2.imshow("source | log-polar (FPGA)",
                           np.hstack((annotate(src, "source 128x128"),
                                      annotate(dst, f"log-polar  {fps:.1f} fps"))))
                if cv2.waitKey(1) & 0xFF == ord("q"):
                    break
            cap.release()
        else:
            img = cv2.imread(args.image, cv2.IMREAD_GRAYSCALE)
            if img is None:
                print(f"could not read {args.image}")
                return 1
            src = preprocess(img)

            t0 = time.time()
            dst = transform_frame(ser, src)
            dt = time.time() - t0
            if dst is None:
                print("timed out waiting for the board")
                return 1
            print(f"round trip {dt*1000:.1f} ms "
                  f"({2*NPIX*10/args.baud*1000:.1f} ms of that is UART)")

            if args.check:
                sys.path.insert(0, __file__.rsplit("/", 1)[0])
                from gen_luts import golden_transform
                gold = golden_transform(src)
                gold[gold == SYNC] = 0x54
                bad = int((gold != dst).sum())
                print(f"model check: {bad} / {NPIX} pixels differ "
                      f"{'-- PASS' if bad == 0 else '-- FAIL'}")

            if args.save:
                cv2.imwrite(args.save, dst)
                print(f"saved {args.save}")

            cv2.imshow("source | log-polar (FPGA)",
                       np.hstack((annotate(src, "source 128x128"),
                                  annotate(dst, "log-polar (FPGA)"))))
            cv2.waitKey(0)

        cv2.destroyAllWindows()
    finally:
        ser.close()
    return 0


if __name__ == "__main__":
    sys.exit(main())
