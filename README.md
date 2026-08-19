# FPGA Image Processing on Basys 3

Two related, currently-**separate** hardware efforts targeting the Digilent Basys 3 (Xilinx Artix-7 `xc7a35tcpg236-1`):

1. **DoG band-pass filtering pipeline** (`rtl/hardcoded image to dog on screen/`, `rtl/headless dog/`) — a Difference-of-Gaussian front end for matching lunar terrain patches (Chandrayaan-2 TMC imagery) against known templates. This is the design covered by `docs/paper.txt` / the accompanying PDF, and the one with real on-board evaluation results in `fpga_evaluation/`.
2. **Log-polar transform accelerator** (`rtl/logpolar/`) — a standalone, rotation-invariant image transform core. It shares the DoG pipeline's UART frame protocol by design ("so the same host habits apply") but is **not wired into the DoG pipeline** — no integration exists yet.

## Repository layout

```
rtl/
  hardcoded image to dog on screen/   DoG pipeline, VGA-display variant (does not currently synthesize — see Known issues #1)
  headless dog/                       DoG pipeline, UART-streaming variant (the one actually run on hardware)
  logpolar/                           Log-polar transform accelerator (standalone)
sim/
  tb_dog_top.v, tb_gaussian_blur_top.v, tb_img_rom.v   DoG-pipeline testbenches (dump output to a file, no self-checking)
  tb_vga_sync.v                       VGA timing testbench (self-checking, but stale — see Known issues #2)
  logpolar/                           Log-polar testbenches (tb_top.v, tb_two_frames.v)
constraints/
  dog_via_vga_constraints.xdc         Pin constraints, VGA variant
  headless_dog_constraints.xdc        Pin constraints, UART variant
  logpolar/logpolar_constraints.xdc   Pin constraints, log-polar accelerator
scripts/
  transmit.py, cam_transmit.py, image_to_hex.py, hex_to_image.py,
  compare_images.py, satellite_image_processing.py   DoG-pipeline host tooling (see below)
  logpolar/                           Log-polar host tooling (gen_luts.py, host.py, verify.py, rotate_demo.py)
data/                                 128x128 test image + hex/reference dumps for the DoG pipeline
fpga_evaluation/                      Output of a real on-board evaluation run (results.csv, plots, log)
multi_region_dataset/                 Synthetic per-region frame dataset used for that run (gitignored, generated locally)
ch2_tmc_ncn_20240426T0455517041_d_img_d18/   Source Chandrayaan-2 TMC dataset the above was derived from
reports/                              Raw Vivado synth/impl run output for the headless UART design (see Known issues #8)
docs/                                 paper.txt / *.pdf (LaTeX source / typeset PDF of the paper this DoG pipeline implements), demo.mp4 (undocumented — see Known issues #7)
```

## 1. DoG band-pass filtering pipeline

Both variants process a fixed **128x128** grayscale frame and share the same core DoG math:

- Two 5-tap separable Gaussian blurs run in parallel on the same input: kernel `1,4,6,4,1` (shift 4, a true binomial blur) and kernel `1,2,2,2,1` (shift 3, a narrower/cheaper blur).
- `dog_pixel = blur1 - blur2`, a signed 9-bit value.
- Same kernel weights, shifts, and bit widths in both variants — only the buffering/streaming architecture around them differs (see below).

### VGA-display variant — `rtl/hardcoded image to dog on screen/`

Loads a fixed 128x128 test image from `img_rom.v` (via `$readmemh("image.hex", mem)` — note the bare filename; it depends on the simulator/Vivado working directory rather than pointing at `data/` explicitly), computes DoG once, and displays the result as a 128x128 box on a standard **640x480 @ ~59.52 Hz** VGA output (`H_TOTAL=800, V_TOTAL=525` timings at a 25 MHz pixel-clock-enable derived from the 100 MHz system clock — not a true divided/PLL clock). Column convolution (`gaussian_col_conv.v`) buffers the **entire 16,384-pixel frame** on-chip before running.

**This variant cannot currently be synthesized** — see Known issues #1.

### UART-streaming variant — `rtl/headless dog/` (the one used for the real evaluation)

Receives a 128x128 frame over UART, computes DoG, and streams the result back. Frame protocol (`top.v`'s FSM):

- Sync byte `0x55`, then 16,384 payload bytes, in both directions (16,385 bytes per direction total).
- UART divisor `CLKS_PER_BIT = 108` at a 100 MHz clock → **≈925,926 baud** (a divisor chosen to approximate the standard 921,600 baud rate — not 2,000,000; see Known issues #3).
- Output mapping: `mapped_pixel = 128 + (dog_pixel >>> 1)` — the signed DoG value is halved and re-centered into unsigned 8-bit before transmission.

Column convolution here (`gaussian_col_conv.v`) uses only **4 line buffers** of 128 entries each — a genuine streaming design, not a full-frame buffer like the VGA variant. Image geometry (`img_width`/`img_height`) is passed as a runtime port rather than a compile-time parameter, though `top.v` always drives it with the constant 128x128.

### Testbenches (`sim/`)

None of the DoG testbenches perform an in-simulation pass/fail comparison against a golden reference — they dump their output to a file for external inspection, except `tb_vga_sync.v` which is self-checking but stale:

- `tb_dog_top.v` — dumps every DoG sample to `dog_output.txt` (signed decimal).
- `tb_gaussian_blur_top.v` — dumps the blurred frame to `blurred_image.hex`; has a hard timeout guard.
- `tb_img_rom.v` — prints the first 32 ROM values, no assertions.
- `tb_vga_sync.v` — checks hsync/vsync pulse widths and `video_on` cycle count against expected values, but is stale against the current `vga_sync.v` interface (see Known issues #2).

### Host scripts (`scripts/`, flat — DoG pipeline only)

None of these take CLI arguments; every path/port/baud value is a hardcoded constant at the top of the file and must be hand-edited before running.

- `image_to_hex.py` — image -> `$readmemh`-style hex (one 2-digit byte per line) for ROM loading.
- `hex_to_image.py` — hex -> PNG; silently truncates/zero-pads on a length mismatch.
- `compare_images.py` — despite the name, the *active* code just visualizes `dog_output.txt` as a normalized PNG (`dog_result.png`); an actual two-image diff exists only as dead, commented-out code above it.
- `cam_transmit.py` — live webcam viewer: grabs a frame, sends it, shows raw + DoG side by side (COM8 @ 921,600).
- `transmit.py` — batch evaluation harness: streams `multi_region_dataset/` through the board (COM4 @ 2,000,000 configured — see Known issues #5 on the port/baud inconsistency across scripts), scores each response by NCC against a template, and writes `fpga_evaluation/`. Most of the file (~1,000 of ~1,225 lines) is superseded, commented-out earlier drafts; only the last ~235 lines run.
- `satellite_image_processing.py` — builds `multi_region_dataset/` from the CH2 TMC browse image + geometry CSV: scores 128x128 patches on an 80px grid by variance + gradient magnitude, picks the top 10 non-clustering regions, and generates 25 synthetically transformed (rotate/scale/translate, occasional blur/noise) frames per region plus one template.

### Real-board evaluation (`fpga_evaluation/`)

Produced by `transmit.py` driving the actual board (`terminal_log.txt` starts with `Connected to FPGA`, ends with a timing summary: 186.48s total / 1,000 variants). `results.csv` has one row per (region 0-9, frame 0-24, variant in `original|noise|rotated|brightness`) = 1,000 rows, columns `region,frame,variant,score,decision` (NCC score via `cv2.matchTemplate(TM_CCOEFF_NORMED)`, thresholded at 0.5). `region_00.png`..`region_09.png` and `histogram.png` are matplotlib score plots, not image crops.

### Synthesis results (`reports/`)

Confirmed (via `runme.log`'s module list: `uart_rx`, `uart_tx`, `input_buffer`, `output_buffer`, `dog_top`, `gaussian_blur_top`) to be the **headless UART design** — the VGA variant cannot elaborate at all. Fully placed & routed on `xc7a35tcpg236-1`: 650/20,800 Slice LUTs (3.13%), 540/41,600 Slice Registers (1.30%) — matching the utilization figure quoted in `docs/paper.txt`'s abstract. `top_timing_summary_routed.rpt` flags 19 `TIMING-18` ("missing input or output delay") methodology warnings, worth checking before treating timing closure as fully verified. The routed bitstream (`top.bit`) is present.

## 2. Log-polar transform accelerator — `rtl/logpolar/` (standalone)

A separate UART peripheral, not integrated with the DoG pipeline. `top.v` instantiates `uart_rx`, `uart_tx`, two `frame_buffer` instances (input + output), and `logpolar_core`, using the **same frame protocol shape** as the DoG headless design (sync `0x55` + 16,384-byte 128x128 payload each way) but as its own independent design.

- `logpolar_core.v` performs an inverse-mapped log-polar warp via nearest-neighbour resampling, fully pipelined at 1 pixel/clock. Its fixed-point contract (Q2.14 trig, Q8.8 radius) is defined to match `scripts/logpolar/gen_luts.py`'s `golden_transform()` bit-for-bit.
- `logpolar_luts.v` (auto-generated by `gen_luts.py`, not hand-edited) holds the `cos`/`sin`/`rho` ROMs.
- `scripts/logpolar/host.py` streams a single image or live webcam frame to the board; `verify.py` diffs an RTL simulation dump against the Python golden model; `rotate_demo.py` demonstrates that rotating the input becomes a pure vertical shift in the log-polar output, measuring it back out via phase correlation.

## Data (`data/`)

`image.png` (128x128, 8-bit grayscale) and its ROM form `image.hex` (16,384 lines, one hex byte per line) are the DoG pipeline's test image. `blurred_image.hex` is a matching Gaussian-blur reference dump. `dog_output.txt` is a 16,384-line signed-decimal DoG dump. `context.txt` documents the lunar highland coordinates (26-28°E) behind the 10 regions used in `multi_region_dataset/`.

## Known issues / caveats

Found while reading the code for this review — flagged here rather than silently carried forward or fixed:

1. `rtl/hardcoded image to dog on screen/vga_display.v` instantiates a module `dog_to_u8` that has no definition anywhere in this repo. The VGA variant cannot elaborate/synthesize as checked in.
2. `sim/tb_vga_sync.v` connects to a `vga_sync` port named `clk_25`, which doesn't exist on the current `vga_sync.v` (it takes `clk` + `ce`), and never drives `ce`. It would not compile against the current RTL.
3. The previous README stated the headless UART link runs at 2,000,000 baud. The code (`CLKS_PER_BIT=108` at 100 MHz, in `rtl/headless dog/top.v`, `uart_rx.v`, `uart_tx.v`) actually yields ≈925,926 baud, approximating the standard 921,600 rate — corrected above.
4. `scripts/transmit.py` and `scripts/compare_images.py` are mostly graveyards of superseded, commented-out earlier versions; only a short tail of each file is live. `cam_transmit.py` is effectively an extracted copy of one of `transmit.py`'s dead blocks, kept as a standalone live/interactive script.
5. Baud rate and COM port are hardcoded per-script and inconsistent (`transmit.py`: COM4 @ 2,000,000; `cam_transmit.py`: COM8 @ 921,600) — edit the constants at the top of whichever script you run to match your board and the bitstream's actual `CLKS_PER_BIT`.
6. `.gitignore` excludes `data/ch2_tmc_ncn_20240426T0455517041_d_img_d18/`, but that dataset actually lives at the repo root (`ch2_tmc_ncn_20240426T0455517041_d_img_d18/`), not under `data/` — the rule doesn't match its real path.
7. `docs/demo.mp4` (~2 MB) isn't referenced by any script or document in the repo; its contents weren't verified as part of this review.
8. `reports/synth_1/` and `reports/impl_1/` are raw Vivado run directories — checkpoints (`.dcp`/`.pb`), journals/backups (`.jou`, `.vdi`), and the built `.bit` — rather than curated report output. Worth `.gitignore`-ing the working files and keeping only the `.rpt` summaries if repo size matters.

## Setup

### VGA mode (currently does not synthesize — see Known issue #1)
1. Create a Vivado project targeting `xc7a35tcpg236-1` (Basys 3).
2. Add RTL from `rtl/hardcoded image to dog on screen/`.
3. Add constraints from `constraints/dog_via_vga_constraints.xdc`.
4. Set `vga_top.v` as the top module.
5. You will need to add a `dog_to_u8` module (or otherwise rework the color mapping in `vga_display.v`) before this will elaborate.

### UART mode (verified working — the design behind `reports/` and `fpga_evaluation/`)
1. Create a Vivado project targeting `xc7a35tcpg236-1` (Basys 3).
2. Add RTL from `rtl/headless dog/`.
3. Add constraints from `constraints/headless_dog_constraints.xdc`.
4. Set `top.v` as the top module.
5. Generate the bitstream and program the board.
6. Run `python scripts/cam_transmit.py` (live webcam) or `python scripts/transmit.py` (batch evaluation against `multi_region_dataset/`) — edit the `SERIAL_PORT`/`BAUD_RATE` constants at the top of the script first.

### Log-polar accelerator
1. Create a Vivado project targeting `xc7a35tcpg236-1` (Basys 3).
2. Add RTL from `rtl/logpolar/` (regenerate `logpolar_luts.v` with `python scripts/logpolar/gen_luts.py rtl/logpolar/logpolar_luts.v` if you change the geometry parameters in `gen_luts.py`).
3. Add constraints from `constraints/logpolar/logpolar_constraints.xdc`.
4. Set `top.v` as the top module.
5. Generate the bitstream and program the board.
6. Run `python scripts/logpolar/host.py --port COMx --image path/to/image.png`.

## Target

Xilinx Artix-7 `xc7a35tcpg236-1` (Basys 3), 100 MHz system clock, 128x128 image frames throughout.

*Developed for research in Autonomous Systems and Machine Intelligence.*
