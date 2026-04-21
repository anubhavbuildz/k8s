#!/bin/bash

# Main entry point for the simplified Kubernetes installer
# This script orchestrates the modular components for cluster setup.

set -e

# Resolve the absolute path to the scripts directory
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")/scripts"

# Source common utilities and variables
if [[ -f "$SCRIPT_DIR/common.sh" ]]; then
    source "$SCRIPT_DIR/common.sh"
else
    echo "[ERROR] Could not find scripts/common.sh. Please ensure you are running this from the project root."
    exit 1
fi

ROLE=$1
MASTER_IP=$2

# Check if running as root
check_root

echo "=============================="
echo " Kubernetes Cluster Bootstrap "
echo "=============================="

if [[ "$ROLE" != "master" && "$ROLE" != "worker" ]]; then
    log_error "Invalid or missing role."
    echo "Usage:"
    echo "  Master: sudo $0 master"
    echo "  Worker: sudo $0 worker <MASTER-IP>"
    exit 1
fi

# Sequence of modular installation steps
bash "$SCRIPT_DIR/env_prep.sh"
bash "$SCRIPT_DIR/runtime.sh"
bash "$SCRIPT_DIR/k8s_install.sh"

# Role-specific setup
if [[ "$ROLE" == "master" ]]; then
    bash "$SCRIPT_DIR/master_setup.sh"
else
    bash "$SCRIPT_DIR/worker_setup.sh" "$MASTER_IP"
fi

echo
log_info "Cluster bootstrap sequence completed."
echo "Status check: kubectl get nodes"
echo