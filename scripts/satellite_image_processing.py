import os
import cv2
import numpy as np
import pandas as pd
import math

# ==============================
# PATHS
# ==============================

BROWSE = r"D:\SIFT-FPGA-Basys3\data\ch2_tmc_ncn_20240426T0455517041_d_img_d18\browse\calibrated\20240426\ch2_tmc_ncn_20240426T0455517041_b_brw_d18.png"
CSV    = r"D:\SIFT-FPGA-Basys3\data\ch2_tmc_ncn_20240426T0455517041_d_img_d18\geometry\calibrated\20240426\ch2_tmc_ncn_20240426T0455517041_g_grd_d18.csv"

OUT = r"D:\SIFT-FPGA-Basys3\multi_region_dataset"
os.makedirs(OUT, exist_ok=True)

PATCH = 128
NUM_REGIONS = 10
FRAMES_PER_REGION = 25
BROWSE_SCALE = 10

# ==============================
# LOAD
# ==============================

img = cv2.imread(BROWSE, 0)
df = pd.read_csv(CSV)

# ==============================
# HELPERS
# ==============================

def preprocess(im):
    im = cv2.GaussianBlur(im, (3,3), 0)
    return cv2.normalize(im, None, 0, 255, cv2.NORM_MINMAX).astype(np.uint8)

def extract_patch(im, cx, cy):
    h, w = im.shape
    if cx < 64 or cy < 64 or cx+64 >= w or cy+64 >= h:
        return None
    return im[cy-64:cy+64, cx-64:cx+64]

def score_patch(p):
    return p.var() + np.mean(np.abs(cv2.Sobel(p, cv2.CV_32F,1,0))) * 5

# ==============================
# SELECT MULTIPLE GOOD REGIONS
# ==============================

candidates = []

step = 80  # spacing across image

for y in range(100, img.shape[0]-100, step):
    for x in range(100, img.shape[1]-100, step):
        p = extract_patch(img, x, y)
        if p is None:
            continue
        s = score_patch(p)
        candidates.append((s, x, y))

# sort by best texture
candidates.sort(reverse=True)

# pick top regions (avoid clustering)
selected = []
min_dist = 150

for score, x, y in candidates:
    ok = True
    for _, sx, sy in selected:
        if abs(x - sx) < min_dist and abs(y - sy) < min_dist:
            ok = False
            break
    if ok:
        selected.append((score, x, y))
    if len(selected) >= NUM_REGIONS:
        break

print(f"Selected {len(selected)} regions")

def pixel_to_geo(df, px, py):
    # find nearest row
    dist = (df['Pixel'] - px*10)**2 + (df['Scan'] - py*10)**2
    idx = dist.idxmin()
    return df.loc[idx, 'Latitude'], df.loc[idx, 'Longitude']

for i, (_, cx, cy) in enumerate(selected):
    lat, lon = pixel_to_geo(df, cx, cy)
    print(f"Region {i}: lat={lat:.3f}, lon={lon:.3f}")

# ==============================
# TRANSFORM FUNCTION
# ==============================

def generate_frame(base, t):
    angle = 10 * math.sin(2*np.pi*t)
    scale = 1.0 + 0.05 * math.cos(2*np.pi*t)
    tx = 5 * math.sin(2*np.pi*t*0.7)
    ty = 5 * math.cos(2*np.pi*t*0.5)

    M = cv2.getRotationMatrix2D((64,64), angle, scale)
    M[:,2] += [tx, ty]

    out = cv2.warpAffine(base, M, (128,128),
                         flags=cv2.INTER_LINEAR,
                         borderMode=cv2.BORDER_REFLECT)

    # mild realism
    if np.random.rand() < 0.3:
        out = cv2.GaussianBlur(out, (3,3), 0)

    if np.random.rand() < 0.3:
        noise = np.random.normal(0, 3, out.shape)
        out = np.clip(out + noise, 0, 255)

    return preprocess(out.astype(np.uint8))

# ==============================
# GENERATE DATASET
# ==============================

for i, (_, cx, cy) in enumerate(selected):

    region_dir = os.path.join(OUT, f"region_{i:02d}")
    os.makedirs(region_dir, exist_ok=True)

    base = extract_patch(img, cx, cy)
    base = preprocess(base)

    cv2.imwrite(os.path.join(region_dir, "template.png"), base)

    for f in range(FRAMES_PER_REGION):
        t = f / FRAMES_PER_REGION
        frame = generate_frame(base, t)
        cv2.imwrite(os.path.join(region_dir, f"frame_{f:03d}.png"), frame)

    print(f"Region {i} done")

print("\n✅ MULTI-REGION DATASET READY")