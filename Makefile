TAG ?= latest
IMAGE_NAME ?= quay.io/rh-ee-jdubrick/feedback-harvester
FULL_NAME = $(IMAGE_NAME):$(TAG)
PLATFORM ?= linux/amd64


.PHONY: deploy-postgres
deploy-postgres: 
	bash ./scripts/setup-postgres.sh

.PHONY: deploy-harvester
deploy-harvester:
	bash ./scripts/setup-harvester.sh

.PHONY: deploy-sidecar
deploy-sidecar: 
	bash ./scripts/setup-sidecar.sh

.PHONY: generate-resources
generate-resources: 
	bash ./scripts/generate-resources.sh

.PHONY: build-harvester
build-harvester: 
	podman build --platform=$(PLATFORM) -t $(FULL_NAME) -f src/harvester/Containerfile