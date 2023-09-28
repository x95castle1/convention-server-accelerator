# Get the currently used golang install path (in GOPATH/bin, unless GOBIN is set)
ifeq (,$(shell go env GOBIN))
GOBIN=$(shell go env GOPATH)/bin
else
GOBIN=$(shell go env GOBIN)
endif

GOIMPORTS ?= go run -modfile hack/go.mod golang.org/x/tools/cmd/goimports
CONVENTION_IMAGE_LOCATION ?= CONVENTION_IMAGE_REGISTRY_PLACEHOLDER_URL
STAGING_IMAGE_LOCATION ?= STAGING_PACKAGE_IMAGE_REGISTRY_PLACEHOLDER_URL
RELEASE_IMAGE_LOCATION ?= RELEASE_PACKAGE_IMAGE_REGISTRY_PLACEHOLDER_URL
INSTALL_NAMESPACE ?= ARTIFACT_ID_PLACEHOLDER
CONVENTION_NAME ?= ARTIFACT_ID_PLACEHOLDER

# TAG LOGIC
LATEST_TAG := $(shell git tag | sort -r --version-sort | head -n1)
MAJOR_VERSION=$(shell echo $(LATEST_TAG) | cut -d. -f1)
MINOR_VERSION=$(shell echo $(LATEST_TAG) | cut -d. -f2)
PATCH_VERSION=$(shell echo $(LATEST_TAG) | cut -d. -f3)
NEW_MINOR_VERSION:= $(shell echo $$(($(MINOR_VERSION)+1)))
NEXT_TAG=$(MAJOR_VERSION).$(NEW_MINOR_VERSION).$(PATCH_VERSION)
GIT_URL := $(shell git config --get remote.origin.url)

.PHONY: all
all: test

.PHONY: build
build: test ## Build the project
	go build ./...

.PHONY: test
test: fmt vet ## Run tests
	$(eval export  ANNOTATION_PREFIX=CONVENTION_PREFIX_PLACEHOLDER)
	go test ./... -coverprofile cover.out

.PHONY: fmt
fmt: ## Run go fmt against code
	$(GOIMPORTS) --local ARTIFACT_ID_PLACEHOLDER -w .

.PHONY: vet
vet: ## Run go vet against code
	go vet ./...

.PHONY: image
image:
	pack build --publish $(CONVENTION_IMAGE_LOCATION):$(LATEST_TAG)

.PHONY: install
install: test ## Install conventions server
	kubectl apply -f install-server/server-it.yaml

.PHONY: uninstall
uninstall: ## Uninstall conventions server
	kubectl delete -f install-server/server-it.yaml

.PHONY: restart
restart: ## Kill the convention pods and allow them to be restarted
	kubectl get pods -n $(INSTALL_NAMESPACE) | grep webhook | awk '{print $$1}' | xargs kubectl delete pods -n $(INSTALL_NAMESPACE)

.PHONY: applyw
applyw: ## apply example workloads
	kubectl apply -f ./examples/workload/.

.PHONY: unapplyw
unapplyw: ## delete example workloads
	kubectl delete -f ./examples/workload/.

.PHONY: applyp
applyp: ## apply package repository and then install the package
	tanzu package repository add PACKAGE_SHORT_NAME_PLACEHOLDER-repository \
	--url RELEASE_PACKAGE_IMAGE_REGISTRY_PLACEHOLDER_URL:$(LATEST_TAG) \
	--namespace tap-install \
	--yes
	tanzu package install PACKAGE_SHORT_NAME_PLACEHOLDER \
  	--package PACKAGE_NAME_PLACEHOLDER \
  	--values-file ./examples/package/values.yaml \
  	--version $(LATEST_TAG) \
  	--namespace tap-install \
		--yes

.PHONY: unapplyp
unapplyp: ## delete package and package repository
	tanzu package installed delete PACKAGE_SHORT_NAME_PLACEHOLDER -n tap-install --yes
	tanzu package repository delete PACKAGE_SHORT_NAME_PLACEHOLDER-repository -n tap-install --yes

.PHONY: package
package:
	kctrl package release --chdir ./carvel -v $(LATEST_TAG) --tag $(LATEST_TAG) --repo-output ./packagerepository -y
	kctrl package repo release --chdir carvel/packagerepository -v $(LATEST_TAG) -y

.PHONY: promote
promote:
	imgpkg --tty copy -b $(STAGING_IMAGE_LOCATION):$(LATEST_TAG) --to-repo $(RELEASE_IMAGE_LOCATION) --registry-response-header-timeout 1m --registry-retry-count 2

.PHONY: tag
tag:
	git tag $(NEXT_TAG)
	git push origin $(NEXT_TAG)

.PHONY: updateLatestTagVariable
updateLatestTagVariable:
	$(eval LATEST_TAG=$(NEXT_TAG))

.PHONY: commitReleasedFiles
commitReleasedFiles:
	git add .
	git commit -m "release artifacts for version: $(LATEST_TAG)"
	git push

.PHONY: stash
stash:
	git stash -u

.PHONY: stashPop
stashPop:
	git stash pop || true 

.PHONY: getLatestDigest
getLatestDigest:
	$(eval IMAGE_URL="CONVENTION_IMAGE_REGISTRY_PLACEHOLDER_URL:$(LATEST_TAG)")
	echo $(IMAGE_URL)
	docker pull $(IMAGE_URL) || true
	echo "obtaining digest"
	mkdir -p tmp
	docker inspect $(IMAGE_URL) > tmp/image_inspect.json
	jq -r '.[0].RepoDigests[0]' tmp/image_inspect.json > tmp/latest_digest.json

.PHONY: updateTemplateImage
updateTemplateImage:
	$(eval LATEST_DIGEST=$(shell cat tmp/latest_digest.json))
	echo $(LATEST_DIGEST)
	gsed -i "s|.*ARTIFACT_ID_PLACEHOLDER@sha.*|          image: ${LATEST_DIGEST}|" ./carvel/config/deployment.yaml
	gsed -i "s|.*ARTIFACT_ID_PLACEHOLDER@sha.*|        image: ${LATEST_DIGEST}|" ./install-server/server-it.yaml

.PHONY: updateGoDeps
updateGoDeps:
	go get -u
	go mod tidy

.PHONY: commitGoDeps
commitGoDeps:
	git add .
	git commit -m "bump go deps: $(NEXT_TAG)" || true
	git push

.PHONY: sleep
sleep:
	sleep 3

.PHONY: 
applyacc: ## install accelerator
	tanzu acc create convention-server-template --git-repository $(GIT_URL) --interval 60s

.PHONY: verifyDockerIsRunning
verifyDockerIsRunning:
	@if ! docker stats --no-stream &> /dev/null; then \
		echo "Docker is not running. Please start docker before releasing."; \
        exit 1; \
    fi

# this prunes the old packages from your Package repository. Keeps the last 5.
.PHONY: pruneYourPackages
pruneYourPackages: ## prune package repository
	./scripts/pruneYourPackages.sh

.PHONY: setupDevEnv
setupDevEnv: ## install required tools for dev
	./scripts/local-dev-setup.sh

# future, clone main and perform release on that vs stash/unstash
.PHONY: release
release: verifyDockerIsRunning stash updateGoDeps commitGoDeps build tag updateLatestTagVariable image sleep getLatestDigest updateTemplateImage pruneYourPackages package commitReleasedFiles promote stashPop ## perform a release

# Absolutely awesome: http://marmelab.com/blog/2016/02/29/auto-documented-makefile.html
help: ## Print help for each make target
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

