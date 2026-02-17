# SIFT Image Processing Pipeline (Basys 3 FPGA)

This repository contains a high-performance **Difference of Gaussian (DoG)** hardware pipeline implemented in Verilog for the Artix-7 FPGA (Digilent Basys 3). It features a separable 2D Gaussian filter architecture designed to efficiently process grayscale images.

## 👨‍🚀 Project Overview

The core of this project is the detection of image features by calculating the difference between two Gaussian-blurred versions of an input image. To optimize hardware resources, the system uses **separable convolution**, breaking a 2D filter into independent **horizontal (row)** and **vertical (column)** passes.

### Key Features

* **Streaming Row Convolution**
  Uses a 5-tap shift register to process pixels as they arrive from memory.

* **Buffered Column Convolution**
  Utilizes a Block RAM–based frame buffer to store intermediate results for vertical processing.

* **Boundary Handling**
  Implements edge mirroring/clamping to maintain image quality at the borders.

* **Parallel DoG Architecture**
  Runs two distinct Gaussian blur chains with different σ (sigma) values simultaneously to compute the Difference of Gaussian.

* **Fixed-Point Arithmetic**
  Optimized using bit-shifting for division to minimize DSP slice usage.

---

## 📂 Repository Structure

### `/rtl` (Design Files)

* **`dog_top.v`**
  Top-level module coordinating the parallel blur pipelines and signed subtraction.

* **`gaussian_blur_top.v`**
  Wrapper combining the row and column convolution stages.

* **`gaussian_row_conv.v`**
  Implements the horizontal 1D convolution.

* **`gaussian_col_conv.v`**
  Implements the vertical 1D convolution with explicit 15-bit address control to prevent truncation errors.

* **`img_rom.v`**
  Block RAM ROM that loads the initial `image.hex` via `$readmemh`.

### `/sim` (Verification)

* **`tb_dog_top.v`**
  Verifies the final Difference of Gaussian output and captures results as signed integers.

* **`tb_gaussian_blur_top.v`**
  Testbench for validating individual blur stages.

* **`tb_img_rom.v`**
  Basic unit test for memory read latency and data integrity.

### `/scripts` (Python Tools)

* **`image_to_hex.py`**
  Converts standard images (JPG/PNG) into the `.hex` format required by Verilog `$readmemh`.

* **`dog_output_to_image.py`**
  Processes the `dog_output.txt` simulation data, applying normalization and contrast stretching to visualize detected keypoints.

---

## 🛠 Hardware Specifications

* **Target Device:** Artix-7 (xc7a35tcpg236-1)
* **Image Resolution:** *128x128*
* **Input Data:** 8-bit grayscale
* **Output Data:** 9-bit signed (DoG result)
* **Memory Usage:** *Depends on image size; typically a few tens of KB of Block RAM for ROM and frame buffers*

---

## 📖 How to Use

1. **Prepare the Image**

   ```bash
   python scripts/image_to_hex.py input.jpg
   ```

2. **Run Simulation**
   Load the Verilog files into your simulator (Vivado, ModelSim, or Icarus Verilog) and run:

   ```
   tb_dog_top.v
   ```

3. **Export Results**
   The simulation generates a `dog_output.txt` file containing signed pixel differences in "project -> sim folder".

4. **Visualize Output** 
 (set path to dog_output.txt)

   ```bash
   python scripts/dog_output_to_image.py
   ```