"""Build a test image, run the golden model, and diff it against the RTL dump."""
import os
import sys
import numpy as np

sys.path.insert(0, os.path.dirname(__file__))
from gen_luts import golden_transform, IMG_W, IMG_H

SYNC = 0x55


def make_test_image():
    """A pattern with strong radial + angular structure, so any pipeline
    misalignment shows up as a visible/checkable error rather than noise."""
    y, x = np.mgrid[0:IMG_H, 0:IMG_W]
    dx, dy = x - 64.0, y - 64.0
    r = np.sqrt(dx * dx + dy * dy)
    th = np.arctan2(dy, dx)
    img = (110 + 90 * np.sin(r / 3.0) * np.cos(4 * th))
    img += 40 * ((x // 16 + y // 16) % 2)          # coarse checker
    img = np.clip(img, 0, 255).astype(np.uint8)
    img[img == SYNC] = 0x54                        # host-side sync guard
    return img


def main():
    here = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
    os.chdir(here)

    src = make_test_image()
    with open("sim/src_img.hex", "w") as f:
        for v in src.flatten():
            f.write(f"{v:02x}\n")
    print("wrote sim/src_img.hex")

    if not os.path.exists("sim/hw_out.hex"):
        print("sim/hw_out.hex not present yet - run the simulation first")
        return 0

    hw = np.array(
        [int(l, 16) for l in open("sim/hw_out.hex") if l.strip()],
        dtype=np.uint8,
    )
    if hw.size != IMG_W * IMG_H:
        print(f"FAIL: RTL produced {hw.size} bytes, expected {IMG_W*IMG_H}")
        return 1
    hw = hw.reshape((IMG_H, IMG_W))

    gold = golden_transform(src)
    gold_wire = gold.copy()
    gold_wire[gold_wire == SYNC] = 0x54    # FPGA applies the same guard on TX

    diff = (hw.astype(int) != gold_wire.astype(int))
    nbad = int(diff.sum())

    print(f"\nRTL vs golden model: {nbad} mismatching pixels out of {hw.size}")
    if nbad == 0:
        print("PASS - hardware is bit-exact with the Python model")
        return 0

    ys, xs = np.nonzero(diff)
    print("first mismatches (row=theta, col=rho, got, want):")
    for k in range(min(10, nbad)):
        r, c = ys[k], xs[k]
        print(f"  ({r:3d},{c:3d})  got {hw[r,c]:3d}  want {gold_wire[r,c]:3d}")
    return 1


if __name__ == "__main__":
    sys.exit(main())
