import re
from pathlib import Path
from PIL import Image
import numpy as np

# ===== HARDCODED PATH =====
HEX_FILE_PATH = "blurred_image.hex"
WIDTH = 128
HEIGHT = 128
AUTO_FIX = True
# ==========================

HEX_BYTE_RE = re.compile(r'0x[0-9A-Fa-f]{1,2}|[0-9A-Fa-f]{2}')


def read_hex_tokens(hex_path):
    text = Path(hex_path).read_text()

    raw_tokens = HEX_BYTE_RE.findall(text)

    tokens = []
    for t in raw_tokens:
        if t.lower().startswith("0x"):
            t = t[2:]
        if len(t) == 1:
            t = "0" + t
        tokens.append(t.lower())

    return tokens


def tokens_to_image(tokens, width, height, out_path, auto_fix=False):
    expected = width * height

    if len(tokens) != expected:
        msg = f"Found {len(tokens)} bytes, expected {expected}."
        if not auto_fix:
            raise ValueError(msg)

        # truncate or pad
        if len(tokens) > expected:
            tokens = tokens[:expected]
        else:
            tokens += ["00"] * (expected - len(tokens))

    vals = [int(t, 16) for t in tokens]
    arr = np.array(vals, dtype=np.uint8).reshape((height, width))

    img = Image.fromarray(arr, mode="L")
    img.save(out_path)

    return out_path


def main():
    hex_path = Path(HEX_FILE_PATH)

    # Output PNG in same folder with same name
    out_path = hex_path.with_suffix(".png")

    tokens = read_hex_tokens(hex_path)

    try:
        saved = tokens_to_image(tokens, WIDTH, HEIGHT, out_path, AUTO_FIX)
        print(f"Saved image: {saved}")
    except Exception as e:
        print("Error:", e)
        print("Tokens found:", len(tokens))


if __name__ == "__main__":
    main()
