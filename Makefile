_ != mkdir -p .make bin

LOCAL_BIN := ${CURDIR}/bin
BUN       := ${LOCAL_BIN}/bun
DEVCTL    := ${LOCAL_BIN}/devctl
DOCKER    := docker

TS_SRC != $(DEVCTL) list --ts

test: .make/bun-test

dev:
	$(BUN) dev

start:
	$(BUN) run start

build: dist/index.html
docker: .make/docker-build

clean:
	rm -rf dist .make

dist/index.html: | bin/bun
	$(BUN) run build

bin/bun: .versions/bun | .make/install-bun.sh bin/devctl
	BUN_INSTALL=${CURDIR} ${CURDIR}/.make/install-bun.sh bun-$(shell $(DEVCTL) v bun --prefixed)
	@touch $@ && rm -f _bun

bin/devctl: .versions/devctl
	GOBIN=${LOCAL_BIN} go install github.com/unmango/devctl@v$(shell cat $<)

.envrc: hack/example.envrc
	cp $< $@

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
