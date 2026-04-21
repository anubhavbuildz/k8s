#!/bin/bash

# Master node setup script
source "$(dirname "$0")/common.sh"

set -e

log_info "Initializing Kubernetes control plane..."
# Using hostname -I for the advertise address as in the original script
ADVERTISE_ADDR=$(hostname -I | awk '{print $1}')

kubeadm init \
    --pod-network-cidr=192.168.0.0/16 \
    --apiserver-advertise-address=$ADVERTISE_ADDR

log_info "Configuring kubectl for the current user..."
mkdir -p $HOME/.kube
cp /etc/kubernetes/admin.conf $HOME/.kube/config
chown $(id -u):$(id -g) $HOME/.kube/config

log_info "Installing Calico network plugin (${CALICO_VERSION})..."
kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/${CALICO_VERSION}/manifests/calico.yaml

log_info "Generating worker join command..."
kubeadm token create --print-join-command | tee $JOIN_CMD_FILE
chmod +x $JOIN_CMD_FILE

echo
echo "=================================="
echo "      MASTER SETUP COMPLETE       "
echo "=================================="
echo
echo "Run this on worker nodes:"
echo
cat $JOIN_CMD_FILE
echo
