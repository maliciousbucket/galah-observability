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



.PHONY: kustomize
kustomize: $(KUSTOMIZE)
$(KUSTOMIZE): $(LOCALBIN)
	$(call go-install-tool,$(KUSTOMIZE),sigs.k8s.io/kustomize/kustomize/v5,$(KUSTOMIZE_VERSION))

##@Hello



.PHONY: k3d
k3d: $(K3D)
$(K3D): $(LOCALBIN)
	$(call go-install-tool,$(K3D),github.com/k3d-io/k3d/v5,$(K3D_VERSION))


.PHONY: fmt
fmt:
	@echo "Linting Alloy Files"
	@bash ./tools/lint-alloy.sh


.PHONY: cluster
cluster:
	@echo "Using K3D: $(K3D)"
	$(K3D) cluster create galah-monitoring --config kubernetes/k3d-config.yaml

clean:
	$(K3D) cluster delete galah-monitoring
	@rm -rf kubernetes/*/charts/
	@rm -rf config/*/charts/

.PHONY: manifests
manifests:

manifests-grafana: $(KUSTOMIZE)
	$(KUSTOMIZE) build --enable-helm kubernetes/grafana > kubernetes/grafana/manifests/config.yaml

manifests-mimir: $(KUSTOMIZE)
	$(KUSTOMIZE) build --enable-helm kubernetes/mimir > kubernetes/mimir/manifests/config.yaml

manifests-loki: $(KUSTOMIZE)
	$(KUSTOMIZE) build --enable-helm kubernetes/loki > kubernetes/loki/manifests/config.yaml

manifests-tempo: $(KUSTOMIZE)
	$(KUSTOMIZE) build --enable-helm kubernetes/tempo > kubernetes/tempo/manifests/config.yaml

manifests-alloy:
	$(KUSTOMIZE) build --enable-helm kubernetes/alloy > kubernetes/alloy/manifests/config.yaml

manifests-gateway:
	$(KUSTOMIZE) build --enable-helm kubernetes/gateway > kubernetes/gateway/mainfests/config.yaml

manifests-prom-operator: $(KUSTOMIZE)
	$(KUSTOMIZE) build --enable-helm kubernetes/prom-operator-crds > kubernetes/prom-operator-crs/manifests/config.yaml

manifests-cert-manager: $(KUSTOMIZE)
	$(KUSTOMIZE) build --enable-helm kubernetes/cert-manager > kubernetes/cert-manager/manifests/config.yaml

manifests-kube-state-metrics: $(KUSTOMIZE)
	$(KUSTOMIZE) build --enable-helm kubernetes/kube-state-metrics > kubernetes/kube-state-metrics/manifests/config.yaml


.PHONY: deploy-gateway
deploy-gateway:
	@kubectl apply -f kubernetes/gateway/manifests/config.yaml
	@kubectl rollout status -n gateway deployment/nginx --watch --timeout=300s

.PHONY: deploy-tempo
deploy-tempo:
	@kubectl apply -f kubernetes/tempo/manifests/config.yaml
	@kubectl rollout status -n galah-tracing statefulset/tempo --watch --timeout=300s

.PHONY: deploy-mimir
deploy-mimir:
	@kubectl apply -f kubernetes/mimir/manifests/config.yaml
	@kubectl rollout status -n galah-monitoring deployment/mimir --watch --timeout=300s

.PHONY: deploy-loki
deploy-loki:
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