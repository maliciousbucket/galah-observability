#!/usr/bin/env bash

CURR_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
[ -d "$CURR_DIR" ] || { echo "FATAL: Couldn't locate current directory"; exit 1; }

source "$CURR_DIR/util/common.sh"

section "Adding Kubernetes dashboard to the cluster"

step "Install Kubernetes Dashboard using the Helm Chart"

exe "helm repo add kubernetes-dashboard https://kubernetes.github.io/dashboard/"
exe "helm upgrade --install kubernetes-dashboard kubernetes-dashboard/kubernetes-dashboard --create-namespace --namespace kubernetes-dashboard"

step "Adding Admin account to the cluster"

exe "kubectl apply -f kubernetes/user/account.yaml"
exe "kubectl apply -f kubernetes/user/rbac.yaml"
exe "kubectl apply -f kubernetes/user/token.yaml"

if proceed_or_not "Print token to terminal?"; then
  exe "kubectl get secret admin-user -n kubernetes-dashboard -o jsonpath={'.data.token'} | base64 -d"
fi

eval "kubectl get secret admin-user -n kubernetes-dashboard -o jsonpath={'.data.token'} | base64 -d > secure.txt"
echo ""
echo "Token is available in secure.txt (I am passionate about security)"

step "Opening port for dashboard access"
#Watch rollout instead?
sleep 20

success "Login to the dashboard at (https://localhost:8443)"

exe "kubectl -n kubernetes-dashboard port-forward svc/kubernetes-dashboard-kong-proxy 8443:443"
