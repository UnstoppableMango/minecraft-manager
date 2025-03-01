_ != mkdir -p .make bin

LOCAL_BIN := ${CURDIR}/bin
DEVCTL    := ${LOCAL_BIN}/devctl
DOCKER    := docker

docker: .make/docker-build

bin/bun: .make/install-bun.sh | bin/devctl
	BUN_INSTALL=${CURDIR} ${CURDIR}/$< bun-$(shell $(DEVCTL) v bun --prefixed)
	@touch $@ && rm -f _bun

bin/devctl: .versions/devctl
	GOBIN=${LOCAL_BIN} go install github.com/unmango/devctl@v$(shell cat $<)

.envrc: hack/example.envrc
	cp $< $@

.make/docker-build:
	$(DOCKER) build . -t minecraft-manager:latest

.make/install-bun.sh: .versions/bun
	curl -fsSL https://bun.sh/install -o $@
	chmod +x $@
