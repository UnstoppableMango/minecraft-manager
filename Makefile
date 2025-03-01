_ != mkdir -p .make bin

PROJECT := minecraft-manager
IMG     ?= ${PROJECT}:0.0.1-alpha

LOCAL_BIN := ${CURDIR}/bin

DOCKER := docker
DRUN := $(DOCKER) run --rm -it --network host \
	--workdir=/data --volume ${CURDIR}:/data

DEVCTL  := ${LOCAL_BIN}/devctl
BUN     := ${LOCAL_BIN}/bun
CT      := $(DRUN) -e KUBECONFIG=.make/kind-cluster quay.io/helmpack/chart-testing:$(shell $(DEVCTL) v chart-testing --prefixed) ct
HELM    := ${LOCAL_BIN}/helm
KIND    := ${LOCAL_BIN}/kind
KUBECTL := ${LOCAL_BIN}/kubectl

export GOBIN      := ${LOCAL_BIN}
export KUBECONFIG := .make/kind-cluster

TS_SRC    != $(DEVCTL) list --ts
CHART_SRC := $(wildcard charts/${PROJECT}/*) $(wildcard charts/${PROJECT}/templates/*)

test: .make/bun-test

dev:
	$(BUN) dev

start:
	$(BUN) run start

build: dist/index.html
lint: .make/ct-lint
docker: .make/docker-build
dev-cluster: ${KUBECONFIG} .make/kind-load
dev-container: .make/dev-container
helm-template: .make/helm-template
helm-install: .make/helm-install
helm-uninstall: .make/helm-uninstall

down: .make/kind-delete
	rm -f .make/kind-config.yaml

clean: down
	rm -rf dist .make

dist/index.html: | bin/bun
	$(BUN) run build

bin/bun: .versions/bun | .make/install-bun.sh bin/devctl
	BUN_INSTALL=${CURDIR} ${CURDIR}/.make/install-bun.sh bun-$(shell $(DEVCTL) $<)
	@touch $@ && rm -f _bun

bin/devctl: .versions/devctl
	go install github.com/unmango/devctl@v$(shell cat $<)

bin/helm: .versions/helm | bin/devctl
	go install helm.sh/helm/v3/cmd/helm@$(shell $(DEVCTL) $<)

bin/kind: .versions/kind | bin/devctl
	go install sigs.k8s.io/kind@$(shell $(DEVCTL) $<)

bin/kubectl: .versions/kubernetes | bin/devctl
	curl -Lo $@ "https://dl.k8s.io/release/$(shell $(DEVCTL) $<)/bin/$(shell go env GOOS)/$(shell go env GOARCH)/kubectl"
	chmod +x $@

.ct/chart_schema.yaml: .versions/chart-testing | bin/devctl
	curl -Lo $@ https://raw.githubusercontent.com/helm/chart-testing/refs/tags/$(shell $(DEVCTL) $<)/etc/chart_schema.yaml

.ct/lintconf.yaml: .versions/chart-testing | bin/devctl
	curl -Lo $@ https://raw.githubusercontent.com/helm/chart-testing/refs/tags/$(shell $(DEVCTL) $<)/etc/lintconf.yaml

.envrc: hack/example.envrc
	cp $< $@ && chmod u=r,g=,o= $@

.make/docker-build: Dockerfile package.json bun.lock bunfig.toml ${TS_SRC}
	$(DOCKER) build . -t ${IMG}
	@touch $@

.make/dev-container: hack/dev-container.yml .make/kind-cluster | bin/kubectl
	$(KUBECTL) apply -f $<

.make/bun-test: bun.lock ${TS_SRC} | bin/bun
	$(BUN) test
	@touch $@

.make/bun-install: package.json | bin/bun
	$(BUN) install
	@touch $@

.make/install-bun.sh: .versions/bun
	curl -fsSL https://bun.sh/install -o $@
	chmod +x $@

.make/kind-config.yaml: hack/kind-config.yaml
	cat $< | WORKING_DIR=${CURDIR} envsubst > $@

.make/kind-cluster: .versions/kubernetes | bin/kind .make/kind-config.yaml
	$(KIND) get clusters | grep ${PROJECT} || \
	$(KIND) create cluster \
	--name ${PROJECT} \
	--image kindest/node:$(shell $(DEVCTL) $<) \
	--config .make/kind-config.yaml

.make/kind-delete: .make/helm-uninstall | bin/kind
	[ -f ${KUBECONFIG} ] && \
	$(KIND) delete cluster --name ${PROJECT} && \
	rm -f ${KUBECONFIG}

.make/kind-load: .make/kind-cluster .make/docker-build | bin/kind
	$(KIND) load docker-image --name ${PROJECT} ${IMG}
	@touch $@

.make/minecraft-manager-0.1.0.tgz: | bin/helm
	$(HELM) package charts/${PROJECT} --destination $(dir $@)

.make/helm-template: ${CHART_SRC} | bin/helm
	$(HELM) template ${CURDIR}/charts/${PROJECT} > $@

.make/helm-install: ${CHART_SRC} | bin/helm .make/kind-load
	$(HELM) install test ./charts/${PROJECT} -f ./charts/${PROJECT}/ci/kind-values.yaml
	@touch $@

.make/helm-uninstall: ${CHART_SRC} | bin/helm
	[ -f .make/helm-install ] && \
	$(HELM) uninstall test && \
	rm -f .make/helm-install || true

.make/ct-lint: .ct/chart_schema.yaml .ct/lintconf.yaml ${CHART_SRC} | bin/devctl
	$(CT) lint
	@touch $@

.make/ct-install: .ct/chart_schema.yaml .ct/lintconf.yaml ${CHART_SRC} | bin/devctl .make/kind-load
	$(CT) install --helm-extra-args '--timeout 30s'
