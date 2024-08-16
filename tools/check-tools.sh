#!/bin/bash

CURR_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
[ -d "$CURR_DIR" ] || { echo "FATAL: Couldn't locate current directory"; exit 1; }

BIN_DIR=../bin
[ -d "$BIN_DIR" ] || { echo "FATAL: Couldn't locate bin directory"; exit 1; }

KUSTOMIZE="$BIN_DIR/kustomize"
K3D="$BIN_DIR/k3d"

source "$CURR_DIR/util/common.sh"

section "Checking Tools"

step "Locating Kustomize"

if [ ! -f "$KUSTOMIZE" ]; then
  warn "Kustomize not found!"; exit 1;
else
  success "Kustomize located"
fi


step "Locating K3D"

if [ ! -f "$K3D" ]; then
  warn "K3D not found!"; exit 1;
else
  success "K3D located"
fi