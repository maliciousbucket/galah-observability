#!/usr/bin/env bash

CURR_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
[ -d "$CURR_DIR" ] || { echo "FATAL: Couldn't locate current directory"; exit 1; }

source "$CURR_DIR/util/common.sh"

section "Reloading Alloy"

exe "make manifests-alloy"
exe "make deploy-alloy"

step "Waiting for alloy to come online..."

sleep 30

exe "kubectl apply -f  kubernetes/ingress.yaml"