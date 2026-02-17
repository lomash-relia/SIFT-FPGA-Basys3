from PIL import Image

WIDTH  = 128
HEIGHT = 128

def image_to_hex(
    image_path,
    output_hex="image.hex",
    width=WIDTH,
    height=HEIGHT
):
    # 1) Load image
    img = Image.open(image_path)

    # 2) Convert to grayscale (8-bit)
    img = img.convert("L")

    # 3) Resize to target resolution
    img = img.resize((width, height), Image.BILINEAR)

    # 4) Extract pixels (row-major: y0x0 → y0x127 → y1x0 ...)
    pixels = list(img.getdata())

    # Safety check
    assert len(pixels) == width * height

    # 5) Write HEX file (1 pixel per line)
    with open(output_hex, "w") as f:
        for p in pixels:
            f.write(f"{p:02x}\n")

    print(f"HEX image written: {output_hex}")
    print(f"Resolution: {width}x{height}, Pixels: {len(pixels)}")


if __name__ == "__main__":
    # path = input("Enter image path: ").strip()
    path = r"D:\sift_aes\ch3_nav_ncr_20230830T0501145903_d_img_nno_026.png"
    image_to_hex(path)
