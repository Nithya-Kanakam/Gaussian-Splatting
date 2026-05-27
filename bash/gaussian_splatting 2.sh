#!/bin/bash
set -euo pipefail

# Stop the script immediately if:
# - any command fails
# - an undefined variable is used
# - any command in a pipeline fails

# Run `nvidia-smi` first to check which GPU is free.
# Replace GPU_ID with the free GPU number on the DGX server.
# Example: GPU_ID=3 means Docker will use GPU 3.
GPU_ID=0

# Host directory mounted into the Docker container.
WORKSPACE="/data/pool/(your_username)"

# Main project directory inside the Docker container.
PIPELINE_DIR="/workspace/gs_pipeline"

# Scene directory containing the input images.
# Images must be placed inside: /workspace/gs_pipeline/my_scene/images
SCENE_DIR="${PIPELINE_DIR}/my_scene"

# Directory where GraphDeco training results will be saved.
OUTPUT_DIR="${PIPELINE_DIR}/outputs/my_scene_r4_new"

# Final copied PLY file location for easier access.
FINAL_PLY="${PIPELINE_DIR}/outputs/my_scene_final.ply"

# Docker container name, including the selected GPU ID.
CONTAINER_NAME="gs_train_gpu${GPU_ID}"

# NVIDIA PyTorch Docker image used for CUDA, PyTorch, and GPU support.
DOCKER_IMAGE="nvcr.io/nvidia/pytorch:24.01-py3"

# Remove any existing container with the same name to avoid conflicts.
docker rm -f "${CONTAINER_NAME}" >/dev/null 2>&1 || true

# Start the Docker container with the selected GPU and mount the workspace.
docker run --rm -it \
  --gpus "device=${GPU_ID}" \
  --name "${CONTAINER_NAME}" \
  -v "${WORKSPACE}:/workspace" \
  "${DOCKER_IMAGE}" \
  bash -lc 

# Stop execution inside the container if any command fails.
set -euo pipefail

# Move to the mounted workspace directory.
cd /workspace

# Create the main project folder and output directory if they do not exist.
mkdir -p gs_pipeline/outputs
cd gs_pipeline

# Clone the official GraphDeco Gaussian Splatting repository if it is not present.
# If it already exists, update the repository and its submodules.
if [ ! -d gaussian-splatting ]; then
  git clone https://github.com/graphdeco-inria/gaussian-splatting --recursive
else
  cd gaussian-splatting
  git pull
  git submodule update --init --recursive
  cd ..
fi

# Enter the GraphDeco Gaussian Splatting repository.
cd gaussian-splatting

# Update package lists and install required system packages.
# COLMAP is required for camera pose estimation and scene preprocessing.
apt update
DEBIAN_FRONTEND=noninteractive apt install -y colmap git wget bzip2

# Verify the PyTorch version, CUDA version, and GPU availability.
python -c \"import torch; print(torch.__version__); print(torch.version.cuda); print(torch.cuda.is_available())\"

# Upgrade Python packaging tools and install required build utility.
python -m pip install --upgrade pip setuptools wheel ninja

# Install Python dependencies required by the Gaussian Splatting pipeline.
python -m pip install plyfile tqdm

# Install GraphDeco CUDA submodules.
# simple-knn is used for nearest-neighbor operations.
python -m pip install --no-build-isolation submodules/simple-knn

# diff-gaussian-rasterization is used for differentiable Gaussian rendering.
python -m pip install --no-build-isolation submodules/diff-gaussian-rasterization

# Check whether the input image folder exists before starting reconstruction.
if [ ! -d '${SCENE_DIR}/images' ]; then
  echo 'ERROR: Put your 1300 images inside ${SCENE_DIR}/images before running this script.'
  exit 1
fi

# Run COLMAP in offscreen mode to avoid GUI/display errors on the server.
export QT_QPA_PLATFORM=offscreen

# Convert the input image dataset into the COLMAP format required by GraphDeco.
# --no_gpu disables GPU usage for COLMAP conversion to avoid possible server compatibility issues.
python convert.py \
  -s '${SCENE_DIR}' \
  --no_gpu

# Train the Gaussian Splatting model using the selected GPU.
# Inside the Docker container, the selected host GPU is exposed as CUDA device 0.
# If training outside Docker, run nvidia-smi and replace CUDA_VISIBLE_DEVICES with the free GPU number.
CUDA_VISIBLE_DEVICES=0 python train.py \
  -s '${SCENE_DIR}' \
  -m '${OUTPUT_DIR}' \
  --resolution 4

# Search for the latest generated point_cloud.ply file inside the training output folder.
LATEST_PLY=\$(find '${OUTPUT_DIR}/point_cloud' -name 'point_cloud.ply' | sort -V | tail -n 1)

# Stop the script if no PLY file was generated.
if [ -z \"\$LATEST_PLY\" ]; then
  echo 'ERROR: No point_cloud.ply was generated.'
  exit 1
fi

# Copy the latest generated PLY file to a fixed final location.
# This makes it easier to find and upload the output to visualization tools or Unreal Engine.
cp \"\$LATEST_PLY\" '${FINAL_PLY}'

# Print completion message and final output path.
echo 'Done.'
echo \"Final PLY saved at: ${FINAL_PLY}\"
"
