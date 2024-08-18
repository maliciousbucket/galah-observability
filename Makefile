# Get the currently used golang install path (in GOPATH/bin, unless GOBIN is set)
ifeq (,$(shell go env GOBIN))
GOBIN=$(shell go env GOPATH)/bin
else
GOBIN=$(shell go env GOBIN)
endif

SHELL = /usr/bin/env bash -o pipefail
.SHELLFLAGS = -ec



## Location to install dependencies to
LOCALBIN ?= $(shell pwd)/bin
$(LOCALBIN):
	mkdir -p $(LOCALBIN)

## Tool Binaries
KUBECTL ?= kubectl
K3D ?= $(LOCALBIN)/k3d
KUSTOMIZE ?= $(LOCALBIN)/kustomize

## Tool Versions
KUSTOMIZE_VERSION ?= v5.4.3
K3D_VERSION ?= v5.7.3

##@ Tools

.PHONY: kustomize
kustomize: $(KUSTOMIZE)
$(KUSTOMIZE): $(LOCALBIN)
	$(call go-install-tool,$(KUSTOMIZE),sigs.k8s.io/kustomize/kustomize/v5,$(KUSTOMIZE_VERSION))





.PHONY: k3d
k3d: $(K3D)
$(K3D): $(LOCALBIN)
	$(call go-install-tool,$(K3D),github.com/k3d-io/k3d/v5,$(K3D_VERSION))


.PHONY: fmt
fmt: ## Lint and format Alloy Files
	@echo "Linting Alloy Files"
	@bash ./tools/lint-alloy.sh

##@ Cluster

.PHONY: cluster
cluster: ## Create the default K3D cluster
	@echo "Using K3D: $(K3D)"
	$(K3D) cluster create galah-monitoring --config kubernetes/k3d-config.yaml

clean: ## Delete the galah-monitoring cluster and remove generated charts
	$(K3D) cluster delete galah-monitoring
	@rm -rf kubernetes/*/charts/
	@rm -rf config/*/charts/

##@ Manifests

.PHONY: manifests
manifests:
manifests: $(KUSTOMIZE) manifests-monitoring manifests-crds

#manifests-monitoring:
manifests-monitoring: $(KUSTOMIZE) manifests-grafana manifests-mimir manifests-loki manifests-tempo manifests-gateway ## Generate all monitoring manifests

manifests-crds: $(KUSTOMIZE) manifests-cert-manager manifests-prom-operator manifests-kube-state-metrics ## Generate Cert manager and CRD manifests

manifests-grafana: $(KUSTOMIZE) ## Generate Grafana manifests
	$(KUSTOMIZE) build --enable-helm kubernetes/grafana > kubernetes/grafana/manifests/config.yaml

manifests-mimir: $(KUSTOMIZE)
	$(KUSTOMIZE) build --enable-helm kubernetes/mimir > kubernetes/mimir/manifests/config.yaml

manifests-loki: $(KUSTOMIZE) ## Generate Loki manifests
	$(KUSTOMIZE) build --enable-helm kubernetes/loki > kubernetes/loki/manifests/config.yaml

manifests-tempo: $(KUSTOMIZE) ## Generate Tempo manifests
	$(KUSTOMIZE) build --enable-helm kubernetes/tempo > kubernetes/tempo/manifests/config.yaml

manifests-alloy: $(KUSTOMIZE) ## Generate Alloy and Alloy Operator manifests
	$(KUSTOMIZE) build --enable-helm kubernetes/alloy > kubernetes/alloy/manifests/config.yaml

manifests-gateway: $(KUSTOMIZE) ## Generate manifests for the NGINX gateway
	$(KUSTOMIZE) build --enable-helm kubernetes/gateway > kubernetes/gateway/manifests/config.yaml

manifests-minio: $(KUSTOMIZE) ## Generate Minio Tenant and Cluster manifests
	$(KUSTOMIZE) build --enable-helm kubernetes/minio-tenant > kubernetes/minio-tenant/manifests/config.yaml
	$(KUSTOMIZE) build --enable-helm kubernetes/minio-operator > kubernetes/minio-operator/manifests/config.yaml

manifests-prom-operator: $(KUSTOMIZE) ## Generate Prometheus Operator CRD manifests
	$(KUSTOMIZE) build --enable-helm kubernetes/prom-operator-crds > kubernetes/prom-operator-crds/manifests/config.yaml

manifests-cert-manager: $(KUSTOMIZE) ## Generate Cert Manager manifests
	$(KUSTOMIZE) build --enable-helm kubernetes/cert-manager > kubernetes/cert-manager/manifests/config.yaml

manifests-kube-state-metrics: $(KUSTOMIZE) ## Generate Kube State Metrics CRD manifests
	$(KUSTOMIZE) build --enable-helm kubernetes/kube-state-metrics > kubernetes/kube-state-metrics/manifests/config.yaml

##@ Deployment

.PHONY: deploy-gateway
deploy-gateway: ## Deploy Gateway
	@kubectl apply -f kubernetes/gateway/manifests/config.yaml
	@kubectl rollout status -n gateway deployment/nginx --watch --timeout=300s

.PHONY: deploy-minio
deploy-minio: ## Deploy Minio Operator and Tenant
	@kubectl apply -f kubernetes/minio-operator/manifests/config.yaml
	@kubectl rollout status -n minio-store deployment/minio-operator --watch --timeout=300s
	@kubectl apply -f kubernetes/minio-tenant/manifests/config.yaml
	@echo "Waiting for Minio to launch...."
	@sleep 20
	@kubectl rollout status -n minio-store statefulset/galah-pool-15gb --watch --timeout=300s || true
delete-minio: ## Delete Minio Tenant Pods
	@kubectl delete --ignore-not-found -f kubernetes/minio-tenant/manifests/config.yaml

.PHONY: deploy-grafana
deploy-grafana: ## Deploy Grafana
	@kubectl apply -f kubernetes/grafana/manifests/config.yaml
	@kubectl rollout status -n galah-monitoring deployment/grafana --watch --timeout=300s
delete-grafana:
	@kubectl delete --ignore-not-found -f kubernetes/grafana/manifests/config.yaml


.PHONY: deploy-alloy
deploy-alloy: ## Deploy Alloy and Alloy Operator
	@kubectl apply -f kubernetes/alloy/manifests/config.yaml
	@kubectl rollout status -n galah-monitoring statefulset/alloy --watch --timeout=300s

.PHONY: deploy-tempo
deploy-tempo: ## Deploy Tempo
	@kubectl apply -f kubernetes/tempo/manifests/config.yaml
	@kubectl rollout status -n galah-tracing statefulset/tempo --watch --timeout=300s

.PHONY: deploy-mimir
deploy-mimir: ## Deploy Mimir
	@kubectl apply -f kubernetes/mimir/manifests/config.yaml
	@kubectl rollout status -n galah-monitoring deployment/mimir --watch --timeout=300s

.PHONY: deploy-loki
deploy-loki: ## Deploy Loki
	@kubectl apply -f kubernetes/loki/manifests/config.yaml
	@kubectl rollout status -n galah-logging statefulset/loki --watch --timeout=300s


define go-install-tool
@[ -f "$(1)-$(3)" ] || { \
set -e; \
package=$(2)@$(3) ;\
echo "Downloading $${package}" ;\
rm -f $(1) || true ;\
GOBIN=$(LOCALBIN) go install $${package} ;\
mv $(1) $(1)-$(3) ;\
} ;\
ln -sf $(1)-$(3) $(1)
endef

.PHONY: help
help:
ifeq ($(OS),Windows_NT)
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make <target>\n"} /^[a-zA-Z_-]+:.*?##/ { printf "  %-40s %s\n", $$1, $$2 } /^##@/ { printf "\n%s\n", substr($$0, 5) } ' $(MAKEFILE_LIST)
else
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z_-]+:.*?##/ { printf "  \033[36m%-40s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)
endif