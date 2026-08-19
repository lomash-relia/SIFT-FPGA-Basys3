"""
Rotation demo for the Basys 3 log-polar accelerator.

Rotates one image through a series of angles, sends each to the board, and
shows that a rotation of the input becomes a pure VERTICAL SHIFT of the
log-polar output -- then measures that shift back out with phase
correlation and compares it to the true angle.

    python scripts/logpolar/rotate_demo.py --port COM4 --image data/image.png
    python scripts/logpolar/rotate_demo.py --port COM4 --image data/image.png --sweep 24
    python scripts/logpolar/rotate_demo.py --image data/image.png --offline

--offline runs the Python model instead of the board, so you can check the
geometry without the FPGA plugged in.

--------------------------------------------------------------------------
ON THE CORNER PROBLEM
--------------------------------------------------------------------------
Rotating a square loses the corners and gains undefined area. That cannot
affect this transform, and the reason is worth knowing rather than
patching around:

The core only ever samples a DISC. rho[127] is 60.99 px, so with the centre
at (64,64) the sampled region reaches at most 124.99 -- about 2 px short of
the frame edge. Rotation about the centre preserves radius, so a rotated
sample at radius <= 61 comes from a source point at radius <= 61, which is
still comfortably inside the frame. The undefined corner region is at
radius 64..90 and is never read.

So the fill colour is irrelevant to the output. This script still does two
things about it, both for honesty rather than correctness:

  * borderMode=BORDER_REFLECT_101 rather than a constant, so nothing bright
    and artificial exists in the buffer at all -- no white wedges;
  * an optional disc mask (--mask, on by default) that blacks out the
    corners in the PREVIEW, so what you see on screen is exactly what the
    hardware sampled.

Turn the mask off with --no-mask and the log-polar panel will not change by
a single pixel. That is the proof.
"""
import argparse
import os
import sys
import time

import numpy as np
import cv2

# pyserial is imported lazily inside main(), so that --offline runs on a
# machine with no serial support installed at all.

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from gen_luts import golden_transform, build_luts, PROD_FRAC

W = H = 128
NPIX = W * H
SYNC = 0x55
CX = CY = 64.0

# Phase correlation is unreliable on the innermost rho columns: at radius
# 1-2 px all 128 angular steps fight over a handful of pixels, so those
# columns are quantisation noise rather than signal. Measured over a 52
# angle sweep, including them gave 8 gross failures; dropping 24 gave 1,
# with mean confidence rising from 0.73 to 0.99.
RHO_SKIP = 24


# ---------------------------------------------------------------- serial
def read_exact(ser, n):
    buf = bytearray()
    while len(buf) < n:
        chunk = ser.read(n - len(buf))
        if not chunk:
            return None
        buf.extend(chunk)
    return bytes(buf)


def wait_for_sync(ser, timeout_s=3.0):
    deadline = time.time() + timeout_s
    while time.time() < deadline:
        b = ser.read(1)
        if b and b[0] == SYNC:
            return True
    return False


def transform_on_board(ser, img):
    ser.reset_input_buffer()
    ser.write(bytes([SYNC]) + img.tobytes())
    ser.flush()
    if not wait_for_sync(ser):
        return None
    raw = read_exact(ser, NPIX)
    if raw is None:
        return None
    return np.frombuffer(raw, dtype=np.uint8).reshape((H, W))


# ------------------------------------------------------------- geometry
def sampled_radius():
    """Largest radius the hardware actually reads.

    This is NOT simply rho[127]. The core rounds each computed coordinate
    to an integer pixel, and that rounding can push a sample slightly
    outside the ideal radius -- 60.99 becomes 61.29 in practice. Masking at
    the ideal radius clips real sample points and corrupts the outermost
    column, so replay the exact integer arithmetic and take the true max.
    """
    cos_lut, sin_lut, rho_lut, _ = build_luts()

    def rnd(p):
        return (p + (1 << (PROD_FRAC - 1))) >> PROD_FRAC

    worst = 0.0
    for t in range(H):
        for j in range(W):
            dx = rnd(rho_lut[j] * cos_lut[t])
            dy = rnd(rho_lut[j] * sin_lut[t])
            worst = max(worst, float(dx * dx + dy * dy))
    return worst ** 0.5


def disc_mask(radius):
    y, x = np.mgrid[0:H, 0:W]
    return ((x - CX) ** 2 + (y - CY) ** 2) <= radius ** 2


def rotate(img, angle_deg, mask=None):
    """Rotate about the sampling centre. BORDER_REFLECT_101 means no
    invented constant ever exists in the buffer; the disc never reads it
    either way."""
    M = cv2.getRotationMatrix2D((CX, CY), angle_deg, 1.0)
    out = cv2.warpAffine(img, M, (W, H),
                         flags=cv2.INTER_LINEAR,
                         borderMode=cv2.BORDER_REFLECT_101)
    if mask is not None:
        out = np.where(mask, out, 0).astype(np.uint8)
    out = out.copy()
    out[out == SYNC] = 0x54          # payload must never contain the header
    return out


# ---------------------------------------------------- shift measurement
def prep_for_corr(lp):
    """Window along rho only. The theta axis is CIRCULAR -- tapering it
    would destroy the wraparound that makes the shift measurable."""
    f = lp.astype(np.float32)[:, RHO_SKIP:]
    f = f - f.mean()
    w = np.hanning(f.shape[1]).astype(np.float32)[None, :]
    return np.ascontiguousarray(f * w)


def measure_rotation(ref_lp, cur_lp):
    """Return (estimated angle in degrees, confidence 0..1)."""
    (_, dy), conf = cv2.phaseCorrelate(prep_for_corr(ref_lp),
                                       prep_for_corr(cur_lp))
    # rows shift NEGATIVE for a counter-clockwise rotation, because image y
    # grows downward while the core uses y = CY + rho*sin(theta)
    return (-dy * 360.0 / H) % 360.0, conf


# ----------------------------------------------------------- rendering
def panel(img, title, sub=""):
    out = cv2.cvtColor(cv2.resize(img, (320, 320),
                                  interpolation=cv2.INTER_NEAREST),
                       cv2.COLOR_GRAY2BGR)
    cv2.rectangle(out, (0, 0), (320, 44), (0, 0, 0), -1)
    cv2.putText(out, title, (6, 18), cv2.FONT_HERSHEY_SIMPLEX,
                0.5, (255, 255, 255), 1, cv2.LINE_AA)
    if sub:
        cv2.putText(out, sub, (6, 36), cv2.FONT_HERSHEY_SIMPLEX,
                    0.42, (120, 230, 120), 1, cv2.LINE_AA)
    return out


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--port", default="COM4")
    ap.add_argument("--baud", type=int, default=921600)
    ap.add_argument("--image", required=True)
    ap.add_argument("--sweep", type=int, default=12,
                    help="number of angles evenly spaced over 360 deg")
    ap.add_argument("--angles", type=float, nargs="+",
                    help="explicit angle list, overrides --sweep")
    ap.add_argument("--offline", action="store_true",
                    help="use the Python model instead of the board")
    ap.add_argument("--no-mask", dest="mask", action="store_false",
                    help="do not black out the corners in the preview")
    ap.add_argument("--delay", type=int, default=400,
                    help="ms per frame; 0 waits for a keypress")
    ap.add_argument("--save", help="directory to write frames into")
    ap.add_argument("--video", help="record the demo to this .mp4/.mkv path")
    ap.add_argument("--fps", type=float, default=20.0,
                    help="frame rate of the recorded video")
    ap.add_argument("--codec", default=None,
                    choices=["mp4v", "FFV1", "VP90", "MJPG", "XVID"],
                    help="default: mp4v for .mp4, FFV1 for .mkv/other")
    ap.add_argument("--hold", type=float, default=1.0,
                    help="seconds to hold the first and last frame")
    args = ap.parse_args()

    src = cv2.imread(args.image, cv2.IMREAD_GRAYSCALE)
    if src is None:
        print(f"could not read {args.image}")
        return 1
    src = cv2.resize(src, (W, H), interpolation=cv2.INTER_AREA)

    rmax = sampled_radius()
    mask = disc_mask(rmax) if args.mask else None
    print(f"hardware samples a disc of radius {rmax:.2f} px "
          f"(reaches {CX + rmax:.2f}, frame edge is 127)")
    print(f"margin to the edge: {127 - (CX + rmax):.2f} px "
          f"-> rotation fill can never be sampled")

    angles = args.angles if args.angles else \
        list(np.arange(0.0, 360.0, 360.0 / max(1, args.sweep)))

    ser = None
    if not args.offline:
        try:
            import serial
            ser = serial.Serial(args.port, args.baud, timeout=2)
        except Exception as e:
            print(f"could not open {args.port}: {e}")
            return 1
        print(f"connected to {args.port} at {args.baud} baud")
        time.sleep(0.2)
        ser.reset_input_buffer()

    def do_transform(im):
        if args.offline:
            return golden_transform(im)
        return transform_on_board(ser, im)

    if args.save:
        os.makedirs(args.save, exist_ok=True)

    writer = None          # opened lazily: we need a real frame for the size

    def open_writer(frame):
        """VideoWriter silently produces an unplayable file if the frame size
        does not match exactly, so derive it from a real composed frame.

        Codec choice matters more than usual: this build of OpenCV/FFmpeg
        only writes a valid .mp4 with mp4v -- avc1/H264/X264 all fail
        isOpened() silently and fall back to nothing, so mp4 must not
        default to a codec that doesn't actually work in an .mp4 container.
        """
        h, w = frame.shape[:2]
        d = os.path.dirname(os.path.abspath(args.video))
        if d:
            os.makedirs(d, exist_ok=True)

        codec = args.codec
        if codec is None:
            ext = os.path.splitext(args.video)[1].lower()
            codec = "mp4v" if ext == ".mp4" else "FFV1"

        vw = cv2.VideoWriter(args.video,
                             cv2.VideoWriter.fourcc(*codec),
                             args.fps, (w, h))
        if not vw.isOpened():
            print(f"could not open a {codec} writer for {args.video}")
            return None
        print(f"recording {w}x{h} at {args.fps} fps, codec {codec}")
        return vw

    try:
        ref_rot = rotate(src, 0.0, mask)
        ref_lp = do_transform(ref_rot)
        if ref_lp is None:
            print("timed out on the reference frame")
            return 1

        print(f"\n{'true':>8} {'measured':>10} {'error':>8} {'conf':>6}")
        errs = []
        for a in angles:
            rot = rotate(src, a, mask)
            lp = do_transform(rot)
            if lp is None:
                print(f"{a:8.1f}   frame dropped (timeout)")
                continue

            est, conf = measure_rotation(ref_lp, lp)
            err = min(abs(est - a), 360 - abs(est - a))
            errs.append(err)
            flag = "" if conf > 0.4 else "  <- low confidence"
            print(f"{a:8.1f} {est:10.2f} {err:8.2f} {conf:6.2f}{flag}")

            view = np.hstack((
                panel(rot, f"source, rotated {a:.1f} deg",
                      "corners masked" if args.mask else "corners unmasked"),
                panel(lp, "log-polar   rows=angle, cols=log radius",
                      f"measured {est:.1f} deg  (err {err:.2f})"),
            ))

            if args.video:
                if writer is None:
                    writer = open_writer(view)
                    if writer is None:
                        args.video = None
                    else:
                        for _ in range(int(args.hold * args.fps)):
                            writer.write(view)
                if writer is not None:
                    writer.write(view)

            cv2.imshow("rotation -> vertical shift in log-polar", view)
            if args.save:
                cv2.imwrite(os.path.join(args.save, f"rot_{a:06.1f}.png"), view)
            if cv2.waitKey(args.delay) & 0xFF == ord("q"):
                break

        if errs:
            errs = np.array(errs)
            print(f"\nmedian error {np.median(errs):.2f} deg, "
                  f"max {errs.max():.2f} deg over {len(errs)} angles")

        if writer is not None and args.video is not None:
            for _ in range(int(args.hold * args.fps)):
                writer.write(view)
            writer.release()
            writer = None
            sz = os.path.getsize(args.video) / 1e6
            print(f"wrote {args.video}  ({sz:.1f} MB)")

        cv2.waitKey(0)
        cv2.destroyAllWindows()
    finally:
        if writer is not None:
            writer.release()
        if ser is not None:
            ser.close()
    return 0


if __name__ == "__main__":
    sys.exit(main())