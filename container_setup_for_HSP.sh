#!/bin/bash
#===============================
# Steps for configuring Singularity
# and Docker for rootless access on
# HSP
#
# Usage:
#
# 
#
#===============================

#===============================
# Singularity
#===============================

# Here, using $HOME, but you could use other writable paths.
# The default is /tmp but that is not always writeable.
export SINGULARITY_TMPDIR=${HOME}/.singularity_tmp
export SINGULARITY_CACHEDIR=${HOME}/.singularity_cache

# singularity pull will fail if these directories do not already exist
# Singularity does automatically make the necessary subdirs.
mkdir -p $SINGULARITY_TMPDIR
mkdir -p $SINGULARITY_CACHEDIR

# TODO - Optionally add this config to .bashrc with --modify_bashrc flag
# for repeating steps on all shells started on a cluster.
echo "export SINGULARITY_TMPDIR=${HOME}/.singularity_tmp" >> ~/.bashrc
echo "export SINGULARITY_CACHEDIR=${HOME}/.singularity_cache" >> ~/.bashrc

#================================
# Docker
#================================

dockerd-rootless-setuptool.sh install
PATH=/usr/bin:/sbin:/usr/sbin:$PATH dockerd-rootless.sh --exec-opt native.cgroupdriver=cgroupfs &

# TODO - Are there any configs to add to .bashrc?

