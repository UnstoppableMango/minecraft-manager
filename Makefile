_ != mkdir -p .make bin

PROJECT := minecraft-manager
VERSION ?= 0.0.1-alpha
WEB_IMG ?= ${PROJECT}-web:${VERSION}
API_IMG ?= ${PROJECT}-api:${VERSION}

AGONES_RELEASE  ?= agones
AGONES_NS       ?= agones-system
SHULKER_RELEASE ?= shulker
SHULKER_NS      ?= shulker-system

LOCAL_BIN := ${CURDIR}/bin

DOCKER := docker
DRUN := $(DOCKER) run --rm -it --network host \
	--workdir=/data --volume ${CURDIR}:/data

DEVCTL  := go tool devctl
BUF     := go tool buf
BUN     := ${LOCAL_BIN}/bun
CT      := $(DRUN) -e KUBECONFIG=.make/kind-cluster quay.io/helmpack/chart-testing:$(shell $(DEVCTL) v chart-testing --prefixed) ct
HELM    := go tool helm
KIND    := go tool kind
KUBECTL := ${LOCAL_BIN}/kubectl

export GOBIN      := ${LOCAL_BIN}
export KUBECONFIG := .make/kind-cluster

GO_SRC    != $(DEVCTL) list --go
TS_SRC    != $(DEVCTL) list --ts
PROTO_SRC != $(DEVCTL) list --proto
CHART_SRC := $(wildcard charts/${PROJECT}/*) $(wildcard charts/${PROJECT}/templates/*)

test: .make/bun-test

dev:
	$(BUN) dev

start:
	$(BUN) run start

build: dist/index.html bin/api
api: bin/api
gen: .make/buf-generate
lint: .make/ct-lint
docker: .make/docker-build-web .make/docker-build-api
dev-cluster: ${KUBECONFIG} .make/kind-load-web .make/kind-load-api .make/shulker-install
dev-container: .make/dev-container
helm-template: .make/helm-template
helm-install: .make/helm-install
helm-uninstall: .make/helm-uninstall
shulker-install: .make/shulker-install

down: .make/kind-delete
	rm -f .make/kind-config.yaml .make/${SHULKER_NS}

clean: down
	rm -rf dist .make

tidy: go.mod $(GO_SRC)
	go mod tidy

dist/index.html: | bin/bun
	$(BUN) run build

bin/api: go.mod go.sum ${GO_SRC}
	go build -o $@ ./

bin/bun: .versions/bun | .make/install-bun.sh
	BUN_INSTALL=${CURDIR} ${CURDIR}/.make/install-bun.sh bun-$(shell $(DEVCTL) $<)
	@touch $@ && rm -f _bun

bin/kubectl: .versions/kubernetes
	curl -Lo $@ "https://dl.k8s.io/release/$(shell $(DEVCTL) $<)/bin/$(shell go env GOOS)/$(shell go env GOARCH)/kubectl"
	chmod +x $@

.ct/chart_schema.yaml: .versions/chart-testing
	curl -Lo $@ https://raw.githubusercontent.com/helm/chart-testing/refs/tags/$(shell $(DEVCTL) $<)/etc/chart_schema.yaml

.ct/lintconf.yaml: .versions/chart-testing
	curl -Lo $@ https://raw.githubusercontent.com/helm/chart-testing/refs/tags/$(shell $(DEVCTL) $<)/etc/lintconf.yaml

.envrc: hack/example.envrc
	rm -f $@ && cp $< $@ && chmod u=r,g=,o= $@

.make/docker-build-web: web.Dockerfile package.json bun.lock bunfig.toml ${TS_SRC}
	$(DOCKER) build . -t ${WEB_IMG} -f $<
	@touch $@

.make/docker-build-api: api.Dockerfile go.mod go.sum ${GO_SRC}
	$(DOCKER) build . -t ${API_IMG} -f $<
	@touch $@

.make/dev-container: hack/dev-container.yml .make/kind-cluster .make/shulker-install | bin/kubectl
	$(KUBECTL) apply -f $<

.make/buf-generate: buf.yaml buf.gen.yaml $(PROTO_SRC)
	$(BUF) generate
	@touch $@

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

.make/kind-cluster: .versions/kubernetes | .make/kind-config.yaml
	$(KIND) get clusters | grep ${PROJECT} || \
	$(KIND) create cluster \
	--name ${PROJECT} \
	--image kindest/node:$(shell $(DEVCTL) $<) \
	--config .make/kind-config.yaml

.make/kind-delete: .make/helm-uninstall .make/shulker-uninstall .make/agones-uninstall
	[ -f ${KUBECONFIG} ] && \
	$(KIND) delete cluster --name ${PROJECT} && \
	rm -f ${KUBECONFIG}

.make/kind-load-web: .make/kind-cluster .make/docker-build-web
	$(KIND) load docker-image --name ${PROJECT} ${WEB_IMG}
	@touch $@

.make/kind-load-api: .make/kind-cluster .make/docker-build-api
	$(KIND) load docker-image --name ${PROJECT} ${API_IMG}
	@touch $@

.make/minecraft-manager-0.1.0.tgz:
	$(HELM) package charts/${PROJECT} --destination $(dir $@)

.make/helm-template: ${CHART_SRC}
	$(HELM) template ${CURDIR}/charts/${PROJECT} > $@

.make/helm-install: ${CHART_SRC} | .make/kind-load-web .make/kind-load-api
	$(HELM) install test ./charts/${PROJECT} -f ./charts/${PROJECT}/ci/kind-values.yaml
	@touch $@

.make/helm-uninstall: ${CHART_SRC}
	[ -f .make/helm-install ] && \
	$(HELM) uninstall test && \
	rm -f .make/helm-install || true

.make/ct-lint: .ct/chart_schema.yaml .ct/lintconf.yaml ${CHART_SRC}
	$(CT) lint
	@touch $@

.make/ct-install: .ct/chart_schema.yaml .ct/lintconf.yaml ${CHART_SRC} | .make/kind-load-web .make/kind-load-api
	$(CT) install --helm-extra-args '--timeout 30s'

.make/${SHULKER_NS}:
	$(KUBECTL) create namespace ${SHULKER_NS}
	@touch $@

.make/shulker-install: hack/shulker-values.yml .make/agones-install | bin/kubectl .make/kind-cluster .make/${SHULKER_NS}
	[ ! -f $@ ] && $(HELM) install ${SHULKER_RELEASE} \
	--repo https://jeremylvln.github.io/Shulker/helm-charts \
	--namespace ${SHULKER_NS} \
	--values hack/shulker-values.yml \
	--hide-notes shulker-operator || true
	@touch $@

.make/agones-install: hack/agones-values.yml | bin/kubectl .make/kind-cluster .make/${SHULKER_NS}
	[ ! -f $@ ] && $(HELM) install ${AGONES_RELEASE} \
	--repo https://agones.dev/chart/stable \
	--namespace ${AGONES_NS} --create-namespace \
	--values hack/agones-values.yml \
	--hide-notes agones || true
	@touch $@

.make/agones-uninstall: .make/shulker-uninstall
	$(HELM) uninstall --namespace ${AGONES_NS} --ignore-not-found ${AGONES_RELEASE}
	rm -f .make/agones-install

.make/shulker-uninstall:
	$(HELM) uninstall --namespace ${SHULKER_NS} --ignore-not-found ${SHULKER_RELEASE}
	rm -f .make/shulker-install
