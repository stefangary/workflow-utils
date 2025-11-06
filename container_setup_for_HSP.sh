#!/bin/bash
#===============================
# Steps for configuring Singularity
# and Docker for rootless access on
# HSP
#
# HSP images have many partitions
# and those partitions are limited
# so you can often run into either
# not enough space or no write access
# in /var and /tmp which are often
# used as default work/archive 
# directories for Docker and Singularity. 
#
# This script sets up the environment
# so that Docker and Singularity work
# in a given HSP_CONTAINER_ROOT,
#
# container_setup_for_HSP.sh <HSP_CONTAINER_ROOT>
#
#===============================

export HSP_CONTAINER_ROOT=$1
echo Set HSP_CONTAINER_ROOT to: $HSP_CONTAINER_ROOT
mkdir -p -v $HSP_CONTAINER_ROOT

#===============================
# Singularity
#===============================

# Here, using $HOME, but you could use other writable paths.
# The default is /tmp but that is not always writeable.
export SINGULARITY_TMPDIR=${HSP_CONTAINER_ROOT}/.singularity_tmp
export SINGULARITY_CACHEDIR=${HSP_CONTAINER_ROOT}/.singularity_cache

# singularity pull will fail if these directories do not already exist
# Singularity does automatically make the necessary subdirs.
mkdir -p $SINGULARITY_TMPDIR
mkdir -p $SINGULARITY_CACHEDIR

# TODO - Optionally add this config to .bashrc with --modify_bashrc flag
# for repeating steps on all shells started on a cluster.
echo "export SINGULARITY_TMPDIR=${SINGULARITY_TMPDIR}" >> ~/.bashrc
echo "export SINGULARITY_CACHEDIR=${SINGULARITY_CACHEDIR}" >> ~/.bashrc

#================================
# Docker
#================================

# Docker writes container images to /var by default.
# Write a rootless Docker config to select another
# location
export DOCKER_IMAGE_DIR=${HSP_CONTAINER_ROOT}/.docker_imagesa
mkdir -p ${DOCKER_IMAGE_DIR}
mkdir -p ~/.docker

echo "{" >> ~/.docker/deamon.json
echo "    \"data-root\": \"${DOCKER_IMAGE_DIR}\"" >> ~/.docker/deamon.json
echo "}" >> ~/.docker/deamon.json

dockerd-rootless-setuptool.sh install
PATH=/usr/bin:/sbin:/usr/sbin:$PATH dockerd-rootless.sh --exec-opt native.cgroupdriver=cgroupfs &
