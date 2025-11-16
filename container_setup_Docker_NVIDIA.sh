#!/bin/bash
#========================
# General setup for using
# Docker with NVIDIA GPUs
#========================

# Install NVIDIA container toolkit
sudo dnf config-manager --add-repo https://nvidia.github.io/libnvidia-container/stable/rpm/nvidia-container-toolkit.repo

sudo dnf install -y nvidia-container-toolkit

# Set up a docker configuration for using the container runtime
sudo nvidia-ctk runtime configure --runtime=docker

# (Re)start docker if it was running
sudo systemctl restart docker
