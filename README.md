# SIFT-lite: High-Performance DoG Hardware Pipeline

### Optimized for Digilent Basys 3 (Artix-7 FPGA)

[](https://www.google.com/search?q=%23)
[](https://www.google.com/search?q=%23)
[](https://www.google.com/search?q=%23)

## 📌 Overview

This repository implements a hardware-accelerated **Difference of Gaussian (DoG)** pipeline, a critical component of the Scale-Invariant Feature Transform (SIFT) algorithm. Designed for real-time computer vision applications—such as autonomous navigation and space robotics—this implementation leverages the Artix-7 architecture to perform high-speed feature detection with minimal resource overhead.

The core innovation lies in the use of a **Separable 2D Gaussian Filter**, which decomposes a standard 2D convolution into two 1D passes (Horizontal and Vertical), reducing the computational complexity from $O(N^2)$ to $O(N)$.

-----

## ⚙️ Mathematical Foundation

The Difference of Gaussian is an approximation of the Laplacian of Gaussian (LoG). It is computed by subtracting two versions of the same image blurred with different standard deviations ($\sigma$):

$$DoG(x, y, \sigma) = L(x, y, k\sigma) - L(x, y, \sigma)$$

Where:

  * **$L(x, y, \sigma)$** is the convolution of the input image with a Gaussian kernel $G(x, y, \sigma)$.
  * **$k$** is a constant multiplicative factor between scales.

In this hardware implementation, we utilize **fixed-point arithmetic** and **bit-shifting** to handle the Gaussian coefficients, ensuring the pipeline remains DSP-efficient on the Basys 3 fabric.

-----

## 🏗 System Architecture

The pipeline is designed as a streaming architecture to ensure low latency and high throughput.

### 1\. Row Convolution Stage

  * **Mechanism:** Uses a 5-tap shift register.
  * **Function:** As pixels stream from memory, they are multiplied by Gaussian weights in a single clock cycle.
  * **Optimization:** Boundary mirroring is implemented to prevent artifacts at the image edges.

### 2\. Vertical Buffer (BRAM)

  * **Mechanism:** Implements a Block RAM-based frame buffer.
  * **Function:** Stores the intermediate results of the Row Convolution to allow the Column Filter to access vertically adjacent pixels.

### 3\. Difference Calculation

  * **Mechanism:** Parallel Blur Chains.
  * **Function:** The system runs two Gaussian Blur modules simultaneously. Their outputs are fed into a signed subtractor to produce the final 9-bit DoG result.

### 4\. Real-Time VGA Visualization

  * **Mechanism:** 640x480 @ 60Hz VGA Controller.
  * **Function:** Maps the processed DoG results from the internal buffers directly to the Basys 3's VGA output.
  * **Display Logic:** Since DoG results are signed (representing both increases and decreases in intensity), the output is normalized for the 4-bit-per-channel VGA interface to visually highlight feature keypoints in real-time.

-----

## 📂 Repository Breakdown

### 🛰 RTL Design (`/rtl`)

| File | Description |
| :--- | :--- |
| `dog_top.v` | **The Brain.** Orchestrates the parallel pipelines and final subtraction logic. |
| `gaussian_blur_top.v` | High-level wrapper for a single blur scale. |
| `gaussian_row_conv.v` | Horizontal 1D convolution with streaming tap registers. |
| `gaussian_col_conv.v` | Vertical 1D convolution with optimized BRAM addressing. |
| `vga_controller.v` | Generates HSync, VSync, and RGB signals for real-time monitoring. |
| `img_rom.v` | BRAM-based ROM for storing the input image (initialization via `.hex`). |

### 🧪 Verification (`/sim`)

  * `tb_dog_top.v`: Comprehensive testbench that simulates the entire pipeline and writes results to `dog_output.txt`.
  * `tb_gaussian_blur_top.v`: Targeted unit test for verifying kernel symmetry and blur intensity.

### 🐍 Software Utilities (`/scripts`)

  * `image_to_hex.py`: Converts raw imagery into Verilog-compatible hex strings.
  * `dog_output_to_image.py`: Reconstructs the FPGA's output into a viewable image, applying normalization to highlight detected features.

-----

## 🛠 Hardware Specifications

  * **Target Device:** Xilinx Artix-7 (Basys 3 Trainer Board)
  * **Resolution Support:** 128x128 (Default), scalable via Verilog parameters.
  * **Output Interface:** VGA (640x480 @ 60Hz timing).
  * **Color Depth:** 8-bit Grayscale Input $\rightarrow$ 9-bit Signed DoG Output.
  * **Clock Domain:** 100MHz (System Clock) / 25.175MHz (VGA Pixel Clock).

-----

## 🚀 Execution Guide

### 1\. Image Pre-Processing

Prepare your input image for the FPGA:

```bash
python scripts/image_to_hex.py input.jpg
```

### 2\. Vivado Integration

1.  Create a new project in **Xilinx Vivado** targeting the **Basys 3**.
2.  Add all files from the `/rtl` directory.
3.  Add the generated `image.hex` to the project as a simulation/synthesis resource.
4.  Run **Behavioral Simulation** to verify the DoG output.

### 3\. Hardware Deployment & Post-Processing

  * **Real-Time Viewing:** Generate the Bitstream, program the board, and connect a VGA monitor to view the Difference of Gaussian output live.
  * **Simulation Viewing:** Convert the text output back to an image to verify feature detection mathematically:

<!-- end list -->

```bash
python scripts/dog_output_to_image.py
```

-----

## 📝 Future Roadmap (To-Do)

### 🔹 Phase 1: Intelligent Comparison

  - [ ] **Similarity Engine:** Develop a hardware module to compare real-time DoG results against pre-stored templates (Template Matching). This will involve a Sum of Squared Differences (SSD) or Cross-Correlation unit.

### 🔹 Phase 2: Dynamic I/O Expansion

  - [ ] **Real-Time Camera Input:** Move away from static ROMs by integrating a PMOD-based camera (e.g., OV7670) to feed live pixel data.
  - [ ] **External Bridge:** Implement a UART or SPI interface to allow dynamic image streaming from a Raspberry Pi or Laptop, enabling "Hardware-in-the-loop" testing.

### 🔹 Phase 3: SIFT Completion

  - [ ] **Keypoint Localization:** Implement 3D Space extrema detection to find local maxima/minima across scales.

-----

## 🎓 Contributors

  * **Lomash Relia** - *Lead Developer / Research* - [GitHub](https://www.google.com/search?q=https://github.com/lomash-relia) - [LinkedIn](https://www.linkedin.com/in/lomash-relia)

-----

*Developed for research in Autonomous Systems and Machine Intelligence.*