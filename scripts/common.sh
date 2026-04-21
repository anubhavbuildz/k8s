#!/bin/bash

# Configuration
JOIN_CMD_FILE="/tmp/kubeadm_join_cmd.sh"
K8S_VERSION="1.29"
CALICO_VERSION="v3.27.3"

# Colors for logging
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# Utility functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

check_root() {
    if [[ $EUID -ne 0 ]]; then
        log_error "This script must be run as root"
        exit 1
    fi
}
