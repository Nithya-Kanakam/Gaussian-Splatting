# 3D Gaussian Splatting – TH OWL Campus Reconstruction

> Reconstructing TH OWL campus buildings from real-world image data using 3D Gaussian Splatting,
> refined with SuperSplat, and integrated into Unreal Engine 5 as an interactive first-person environment.
> Developed as a university project at TH OWL, Detmold, Germany.

---

## Overview

This project converts campus image data into real-time interactive 3D environments using
3D Gaussian Splatting. Two independent pipelines were designed and evaluated — one GUI-based
for high visual fidelity, and one fully automated for scalability on a DGX server.

---

## Pipeline 1 — Manual (RealityScan + LichtFeld Studio)

**Dataset:** InnovationSPIN building, ~60 GB  
**Mode:** GUI-based, local machine

### Steps
1. **Data Collection** — GoPro camera with ~80% image overlap; AprilTag markers placed on campus
2. **RealityScan** — Automated COLMAP-based photogrammetry; generates `cameras.txt`, `images.txt`,
   `points3D.txt` and undistorted images; export capped at 2,000,000 pixels to prevent VRAM crashes
3. **LichtFeld Studio** — Gaussian Splatting training using the COLMAP outputs

### Training Parameters
| Parameter | Value |
|---|---|
| Iterations | 30,000 |
| Maximum Gaussians | 2,000,000 |
| SH Degree | 3 |
| Tile Mode | 1 |

✅ High visual fidelity — building facade, windows, entrance, vegetation all clearly reconstructed  
✅ Strong GUI control with real-time feedback  
⚠️ Limited scalability due to GPU memory constraints

## Result from pipeline 1

<img width="2880" height="1800" alt="Screenshot 2026-05-27 at 3 21 42 PM" src="https://github.com/user-attachments/assets/bf82eb3e-c437-4c00-ab3b-39b725a0fc2f" />


---

## Pipeline 2 — Automated (Graphdeco + DGX Server)

**Dataset:** Detmold campus building, ~6 GB  
**Mode:** Headless, SSH, Docker, fully scripted

### Steps
1. **Docker Setup** — NVIDIA PyTorch container (`nvcr.io/nvidia/pytorch:24.01-py3`) on DGX A100
2. **Dependency Install** — COLMAP, PyTorch, simple-knn, diff-gaussian-rasterization
3. **COLMAP `convert.py`** — Structure-from-Motion for camera pose estimation (offscreen mode)
4. **Gaussian Splatting `train.py`** — Training at resolution ÷4 to fit within available GPU memory
5. **PLY Export** — Final `point_cloud.ply` copied to output directory

### Why Resolution ÷4?
Full-resolution training on the 6 GB dataset required ~80 GB GPU memory. The DGX server had
~30–50 GB available. Reducing input resolution by factor 4 made training feasible.

✅ Scalable and reproducible automated workflow  
✅ ~45 min training time  
⚠️ No GUI — monitoring only via command-line logs

```bash
# Edit GPU_ID and WORKSPACE in the script first
bash gaussian_splatting.sh
```

---
## Result from pipeline 2

<img width="751" height="513" alt="image" src="https://github.com/user-attachments/assets/1928933c-95fb-4455-a424-9983105195d0" />


## SuperSplat — Refinement

After training, the `.ply` output was imported into **SuperSplat** for post-processing:
- Visualised the reconstructed Gaussian Splat model
- Manually removed floating artifacts, noise, and redundant splats
- Focused the model on the main building structure
- Re-exported as a cleaned `.ply` ready for Unreal Engine

---

## Unreal Engine 5 — Export & Integration

The refined `.ply` was imported into **Unreal Engine 5.1.1** using the **X3DGS plugin**:

- Installed via Epic Games Launcher; project configured with X3DGS for `.ply` Gaussian Splat support
- Reconstructed campus rendered as a fully navigable first-person environment
- Built on UE5's first-person template
- Interactive game elements added: **targetable blocks + rifle asset** (shooting interaction)
- Result: a small gamified campus tour running in real time on reconstructed real-world geometry

> ⚠️ Note: Constrained to UE5.1.1 — newer UE versions do not have stable `.ply` Gaussian Splat import support via available plugins

---

## Results Summary

| | Pipeline 1 | Pipeline 2 |
|---|---|---|
| Dataset | InnovationSPIN (~60 GB) | Detmold campus (~6 GB) |
| Mode | GUI-based (local) | Headless / automated (DGX server) |
| Tools | RealityScan, LichtFeld Studio, SuperSplat | Graphdeco, COLMAP, Docker |
| Training Time | 14h 37min | ~45 min |
| Output Quality | High fidelity | Validated automated workflow |

---

## Future Scope — Gamified Campus Digital Twin

> **Campus Intelligence** — *Explore. Learn. Optimize. Shape a better tomorrow.*

The vision is to transform the static Gaussian Splat campus model into a full **Campus Intelligence platform**
with four interactive game modes:

| Module | Concept |
|---|---|
| 🌱 Sustainability | Plant trees, place solar panels, optimise walking routes — earn a Sustainability Score |
| ⚡ Efficiency | Control lighting and heating in campus buildings, turn them from red to green — earn an Efficiency Score |
| 📚 Knowledge | Explore hotspots, discover labs and SmartFactoryOWL projects, answer quizzes — earn a Knowledge Score |
| 🗺️ Exploration | Free navigation, guided tours, hidden locations — digital campus tour for students and visitors |

The long-term goal is a **Campus Intelligence** system where users explore, learn, and make decisions
inside a photorealistic digital twin of TH OWL — built on top of the Gaussian Splat reconstruction.

<img width="1402" height="1044" alt="image" src="https://github.com/user-attachments/assets/0461c30e-2132-4fb6-a1d4-c4485f94f3bf" />
---

## Conclusion

This project demonstrates that 3D Gaussian Splatting can effectively bridge real-world image capture
and interactive digital environments. Two complementary pipelines were built and validated —
one focused on visual quality, one on automation and scalability. The reconstructed InnovationSPIN
campus was successfully integrated into Unreal Engine 5 as a navigable, gamified environment.
Despite hardware and data acquisition constraints, a complete end-to-end workflow was achieved,
proving Gaussian Splatting as a practical foundation for future campus-scale interactive applications.

---

## Repository Structure
├── bash/                       # Automated pipeline script (Docker + COLMAP + Training)
├── paper/                      # Full project paper (PDF)
├── presentation/               # Project presentation slides (PDF)
├── gaussian_splats/            # Output .ply files (see Google Drive for large files)
├── videos/                     # Reconstruction and Unreal Engine demo videos
└── unreal_engine/              # Screenshots from UE5 integration
## Large Files (Google Drive)

Generated `.ply` files exceed GitHub's size limit and are available here:  
🔗 [Google Drive – Gaussian Splat .ply files](https://drive.google.com/drive/folders/1_tO3gzsEIkANluHxq5s5XHTrmE8MaNiY?usp=sharing)

🔗 [Google Drive – Gaussian Splat video](https://drive.google.com/file/d/1U1XIdo7oPOlCeSiUpbphKQ0Sf2UHlZKV/view?usp=sharing)

---

## Tech Stack

`3D Gaussian Splatting` `COLMAP` `RealityScan` `LichtFeld Studio` `SuperSplat`  
`Unreal Engine 5.1.1` `X3DGS Plugin` `NVIDIA DGX A100` `Docker` `PyTorch` `Python` `Bash`




