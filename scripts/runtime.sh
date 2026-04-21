#!/bin/bash

# Runtime installation script for K8s nodes
source "$(dirname "$0")/common.sh"

set -e

log_info "Installing containerd..."
yum install -y containerd

mkdir -p /etc/containerd
containerd config default | tee /etc/containerd/config.toml

log_info "Configuring registry mirror to bypass rate limits..."
# Remove existing mirror config if any
sed -i '/registry.mirrors/,$d' /etc/containerd/config.toml

# Append optimized mirror configuration
tee -a /etc/containerd/config.toml <<EOF

[plugins."io.containerd.grpc.v1.cri".registry.mirrors."registry.k8s.io"]
  endpoint = ["https://registry.aliyuncs.com/google_containers"]

EOF

log_info "Starting and enabling containerd service..."
systemctl restart containerd
systemctl enable containerd
