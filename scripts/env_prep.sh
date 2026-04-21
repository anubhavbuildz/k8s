#!/bin/bash

# Preparation script for K8s nodes
source "$(dirname "$0")/common.sh"

set -e

log_info "Updating system packages..."
yum update -y

log_info "Disabling swap..."
swapoff -a
sed -i '/swap/d' /etc/fstab

log_info "Loading kernel modules (overlay, br_netfilter)..."
modprobe overlay
modprobe br_netfilter

tee /etc/modules-load.d/k8s.conf <<EOF
overlay
br_netfilter
EOF

log_info "Configuring sysctl parameters for networking..."
tee /etc/sysctl.d/k8s.conf <<EOF
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF

sysctl --system
