# 3D Gaussian Splatting – TH OWL Campus Reconstruction

3D Gaussian Splatting reconstruction of the TH OWL campus (InnovationSPIN & Detmold buildings),
integrated into Unreal Engine 5 for real-time interactive visualization.
Developed as part of a university project at TH OWL, Germany.

## Overview

This project reconstructs real-world campus environments from image and video data using 
3D Gaussian Splatting and imports the resulting 3D models into Unreal Engine 5 for 
real-time navigation and interaction.

Two pipelines were implemented:

| | Pipeline 1 | Pipeline 2 |
|---|---|---|
| Dataset | InnovationSPIN (~60 GB) | Detmold campus (~6 GB) |
| Mode | GUI-based (local) | Headless / automated (DGX server) |
| Tools | RealityScan, LichtFeld Studio, SuperSplat | Graphdeco framework, COLMAP, Docker |
| Training Time | 14h 37min | ~45 min |
| Output | High-fidelity .ply | Scalable automated .ply |

## Pipeline

1. **Data Collection** – GoPro camera, ~80% image overlap, AprilTag markers
2. **COLMAP** – Structure-from-Motion for camera pose estimation
3. **Gaussian Splatting Training** – 30,000 iterations, final loss: 0.0438
4. **SuperSplat** – Noise removal and artifact cleanup
5. **Unreal Engine 5.1.1** – X3DGS plugin, first-person interactive environment

## Results

- Successfully reconstructed the InnovationSPIN building facade, entrance, and surroundings
- Integrated into UE5 as a navigable, gamified campus tour
- Interactive elements: first-person movement, shooting mechanics, target blocks

## Repository Structure
├── gaussian_splatting.sh       # Automated pipeline script (Docker + COLMAP + Training)
├── paper/                      # Full project paper (PDF)
├── presentation/               # Project presentation slides (PDF)
├── gaussian_splats/            # Output .ply files
├── videos/                     # Reconstruction and demo videos
└── unreal_engine/              # Screenshots from UE5 integration
## Requirements (Pipeline 2 – Server)

- NVIDIA DGX A100 (or any CUDA-capable GPU)
- Docker with `nvcr.io/nvidia/pytorch:24.01-py3`
- COLMAP, Python 3, PyTorch

## Usage

```bash
# Edit GPU_ID and WORKSPACE in the script first
bash gaussian_splatting.sh
```

## Google Drive (Large Files)

The generated .ply files are available here due to GitHub file size limits:  
[Google Drive – Gaussian Splat outputs](https://drive.google.com/drive/folders/1_tO3gzsEIkANluHxq5s5XHTrmE8MaNiY?usp=sharing)
