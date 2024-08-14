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