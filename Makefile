_ != mkdir -p .make bin

PROJECT := minecraft-manager

LOCAL_BIN := ${CURDIR}/bin
BUN       := ${LOCAL_BIN}/bun
DEVCTL    := ${LOCAL_BIN}/devctl
DOCKER    := docker
KIND      := ${LOCAL_BIN}/kind
KUBECTL   := ${LOCAL_BIN}/kubectl

export GOBIN := ${LOCAL_BIN}

TS_SRC != $(DEVCTL) list --ts

test: .make/bun-test

dev:
	$(BUN) dev

start:
	$(BUN) run start

build: dist/index.html
docker: .make/docker-build
dev-cluster: .make/kind-cluster

down: | bin/kind
	[ -f .make/kind-cluster ] && $(KIND) delete cluster --name ${PROJECT}

clean: down
	rm -rf dist .make

dist/index.html: | bin/bun
	$(BUN) run build

bin/bun: .versions/bun | .make/install-bun.sh bin/devctl
	BUN_INSTALL=${CURDIR} ${CURDIR}/.make/install-bun.sh bun-$(shell $(DEVCTL) v bun --prefixed)
	@touch $@ && rm -f _bun

bin/devctl: .versions/devctl
	go install github.com/unmango/devctl@v$(shell cat $<)

bin/kind: .versions/kind | bin/devctl
	go install sigs.k8s.io/kind@$(shell $(DEVCTL) $<)

bin/kubectl: .versions/kubernetes | bin/devctl
	curl -L "https://dl.k8s.io/release/$(shell $(DEVCTL) $<)/bin/$(shell go env GOOS)/$(shell go env GOARCH)/kubectl" -o $@
	chmod +x $@

.envrc: hack/example.envrc
	cp $< $@ && chmod u=r,g=,o= $@

.make/docker-build: Dockerfile package.json bun.lock bunfig.toml ${TS_SRC}
	$(DOCKER) build . -t minecraft-manager:latest
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

.make/kind-cluster: .versions/kubernetes | bin/kind
	$(KIND) get clusters | grep ${PROJECT} || \
	$(KIND) create cluster \
	--name ${PROJECT} \
	--image kindest/node:$(shell $(DEVCTL) $<) \
	--kubeconfig $@
