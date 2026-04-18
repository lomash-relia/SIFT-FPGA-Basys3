# SIFT-FPGA-Basys3: DoG Hardware Pipeline

Hardware implementation of Difference of Gaussian (DoG) computation on Digilent Basys 3 FPGA.

## Two Implementations

### 1. VGA Display Mode
**Path:** `rtl/hardcoded image to dog on screen/`

- Loads 128×128 test image from ROM
- Outputs to VGA display (640×480 @ 60Hz)
- Files: `vga_top.v`, `vga_sync.v`, `vga_display.v`, `dog_top.v`, `gaussian_blur_top.v`, `gaussian_row_conv.v`, `gaussian_col_conv.v`, `dog_frame_buffer.v`, `img_rom.v`

### 2. UART Streaming Mode
**Path:** `rtl/headless dog/`

- Receives 128×128 pixel frames via UART from laptop
- Returns processed DoG results
- UART: 921,600 baud
- Sync byte: `0x55`
- Frame size: 1 + 16,384 bytes
- Files: `top.v`, `uart_rx.v`, `uart_tx.v`, `input_buffer.v`, `output_buffer.v`, `dog_top.v`, `gaussian_blur_top.v`, `gaussian_row_conv.v`, `gaussian_col_conv.v`

## Constraints

- `dog_via_vga_constraints.xdc` — VGA mode pin assignments
- `headless_dog_constraints.xdc` — UART mode pin assignments

## Scripts

- `transmit.py` — Stream webcam video to FPGA over UART (921,600 baud), receive DoG results
- `image_to_hex.py` — Convert image to hex format for ROM
- `hex_to_image.py` — Convert hex to image
- `compare_images.py` — Compare images

## Simulation

- `tb_dog_top.v` — Full pipeline testbench
- `tb_gaussian_blur_top.v` — Gaussian blur test
- `tb_img_rom.v` — ROM test
- `tb_vga_sync.v` — VGA timing test

## Data

- `image.png` — Test image (128×128)
- `image.hex` — ROM-loadable image
- `blurred_image.hex` — Gaussian blur reference
- `dog_output.txt` — DoG output reference

## Target

- Xilinx Artix-7 (Basys 3)
- Image resolution: 128×128
- System clock: 100 MHz

## Setup

### VGA Mode
1. Create Vivado project for Basys 3
2. Add RTL files from `rtl/hardcoded image to dog on screen/`
3. Add constraints from `constraints/dog_via_vga_constraints.xdc`
4. Set `vga_top.v` as top module
5. Generate bitstream and program board
6. Connect VGA monitor

### UART Mode
1. Create Vivado project for Basys 3
2. Add RTL files from `rtl/headless dog/`
3. Add constraints from `constraints/headless_dog_constraints.xdc`
4. Set `top.v` as top module
5. Generate bitstream and program board
6. Run: `python scripts/transmit.py` (adjust serial port in script)

*Developed for research in Autonomous Systems and Machine Intelligence.*