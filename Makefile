TAG ?= latest
IMAGE_NAME ?= quay.io/redhat-ai-dev/feedback-harvester
FULL_NAME = $(IMAGE_NAME):$(TAG)
PLATFORM ?= linux/amd64

# Generations
.PHONY: generate-resources
generate-resources: 
	bash ./scripts/generate-resources.sh

.PHONY: generate-env
generate-env:
	bash ./scripts/generate-env.sh

.PHONY: generate-all
generate-all: generate-resources generate-env

# Builds
.PHONY: build-harvester
build-harvester: 
	podman build --platform=$(PLATFORM) -t $(FULL_NAME) -f src/harvester/Containerfile

# Deployments
.PHONY: deploy-postgres
deploy-postgres: 
	bash ./scripts/setup-postgres.sh

.PHONY: deploy-harvester
deploy-harvester:
	bash ./scripts/setup-harvester.sh

.PHONY: deploy-lcs
deploy-lcs:
	bash ./scripts/setup-lcs.sh

# Removals
.PHONY: remove-lcs
remove-lcs:
	bash ./scripts/remove-lcs.sh

.PHONY: remove-harvester
remove-harvester:
	bash ./scripts/remove-harvester.sh

.PHONY: remove-postgres
remove-postgres:
	bash ./scripts/remove-postgres.sh

.PHONY: remove-all
remove-all: remove-lcs remove-harvester remove-postgres