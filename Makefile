NAME=marathonctl
ARCH=$(shell uname-m)
VERSION=0.1.1
GH_USER=pinterb
MKFILE_PATH := $(abspath $(lastword $(MAKEFILE_LIST)))
CURRENT_DIR := $(shell dirname $(MKFILE_PATH))
DOCKER_BIN := $(shell which docker)
GHRELEASE_BIN := $(shell which gh-release)

all: build

.PHONY: check.env
check.env:
ifndef DOCKER_BIN
   $(error The docker command is not found. Verify that Docker is installed and accessible)
endif
ifndef GHRELEASE_BIN
   $(error The gh-release command is not found. Verify that github.com/progrium/gh-release is installed and accessible)
endif

.PHONY: test
test:
	$(DOCKER_BIN) run --rm \
	-v "$(CURRENT_DIR):/src" \
	centurylink/golang-tester

.PHONY: build
build: test
	$(DOCKER_BIN) run --rm \
	-v "$(CURRENT_DIR):/src" \
	centurylink/golang-builder
	rm -rf build && mkdir -p build/linux && mv $(NAME) build/linux/ && sudo chown -R $(USER):$(USER) build

.PHONY: container
container: test
	$(DOCKER_BIN) run --rm \
	-v "$(CURRENT_DIR):/src" \
	-v /var/run/docker.sock:/var/run/docker.sock \
	centurylink/golang-builder \
	$(GH_USER)/$(NAME):$(VERSION)

.PHONY: push 
push: container 
	$(DOCKER_BIN) push \
	$(GH_USER)/$(NAME):$(VERSION)

.PHONY: release
release: build
	rm -rf release && mkdir -p release
	tar -zcf release/$(NAME)_$(VERSION)_linux_$(ARCH).tgz -C build/linux/ $(NAME)
	$(GHRELEASE_BIN) create $(GH_USER)/$(NAME) $(VERSION)

.PHONY: refresh
refresh: container

.PHONY: clean
clean: docker.gc
	rm -rf $(NAME)
	rm -rf build 
	rm -rf release

.PHONY: docker.gc
docker.gc:
	for i in `docker ps --no-trunc -a -q`;do docker rm $$i;done
	docker images --no-trunc | grep none | awk '{print $$3}' | xargs -r docker rmi

