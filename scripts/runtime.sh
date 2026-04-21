#!/bin/bash

# Runtime installation script for K8s nodes
source "$(dirname "$0")/common.sh"

set -e

# 1. Common Repository Setup (Required for both containerd.io and docker-ce)
log_info "Configuring Docker repository (provides containerd.io)..."
yum install -y dnf-plugins-core
dnf config-manager --add-repo https://download.docker.com/linux/rhel/docker-ce.repo

install_containerd() {
    log_info "Installing containerd.io..."
    yum install -y containerd.io

    mkdir -p /etc/containerd
    containerd config default | tee /etc/containerd/config.toml

    log_info "Configuring registry mirror for containerd..."
    sed -i '/registry.mirrors/,$d' /etc/containerd/config.toml
    tee -a /etc/containerd/config.toml <<EOF

[plugins."io.containerd.grpc.v1.cri".registry.mirrors."registry.k8s.io"]
  endpoint = ["https://registry.aliyuncs.com/google_containers"]

EOF

    systemctl restart containerd
    systemctl enable containerd
}

install_docker() {
    log_info "Installing Docker Engine and cri-dockerd shim..."
    yum install -y docker-ce docker-ce-cli containerd.io

    systemctl start docker
    systemctl enable docker

    # Install cri-dockerd (Required for K8s 1.24+ to use Docker)
    # Finding the correct RPM for the architecture and OS version
    case $(grep -oP '(?<=^ID=).+' /etc/os-release | tr -d '"') in
        "amzn") OS_SUFFIX="amzn2" ;; # Amazon Linux
        "ol") OS_SUFFIX="el8" ;;    # Oracle Linux
        "centos"|"rhel"|"rocky"|"almalinux")
            OS_VERSION=$(grep -oP '(?<=^VERSION_ID=).+' /etc/os-release | tr -d '"' | cut -d. -f1)
            OS_SUFFIX="el${OS_VERSION}"
            ;;
        *) OS_SUFFIX="el8" ;;
    esac

    ARCH=$(uname -m)
    CRI_DOCKER_VERSION="0.3.15"
    RPM_NAME="cri-dockerd-${CRI_DOCKER_VERSION}-3.${OS_SUFFIX}.${ARCH}.rpm"
    DOWNLOAD_URL="https://github.com/Mirantis/cri-dockerd/releases/download/v${CRI_DOCKER_VERSION}/${RPM_NAME}"

    log_info "Downloading cri-dockerd from $DOWNLOAD_URL..."
    curl -LO $DOWNLOAD_URL
    yum install -y ./$RPM_NAME
    rm -f $RPM_NAME

    systemctl daemon-reload
    systemctl enable --now cri-docker.socket
    systemctl enable --now cri-docker
}

# 2. Execute selected runtime installation
case $RUNTIME in
    "docker")
        install_docker
        ;;
    "containerd"|*)
        install_containerd
        ;;
esac

log_info "Runtime setup for '$RUNTIME' completed."
