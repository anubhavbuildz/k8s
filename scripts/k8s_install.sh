#!/bin/bash

# Kubernetes package installation script
source "$(dirname "$0")/common.sh"

set -e

log_info "Adding Kubernetes repository (v${K8S_VERSION})..."
tee /etc/yum.repos.d/kubernetes.repo <<EOF
[kubernetes]
name=Kubernetes
baseurl=https://pkgs.k8s.io/core:/stable:/v${K8S_VERSION}/rpm/
enabled=1
gpgcheck=1
gpgkey=https://pkgs.k8s.io/core:/stable:/v${K8S_VERSION}/rpm/repodata/repomd.xml.key
EOF

log_info "Installing kubelet, kubeadm, and kubectl..."
yum install -y kubelet kubeadm kubectl

log_info "Enabling and starting kubelet service..."
systemctl enable kubelet
systemctl start kubelet

log_info "Pre-pulling Kubernetes images..."
kubeadm config images pull
