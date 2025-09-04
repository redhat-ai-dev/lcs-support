TAG ?= latest
IMAGE_NAME ?= quay.io/redhat-ai-dev/feedback-harvester
FULL_NAME = $(IMAGE_NAME):$(TAG)
PLATFORM ?= linux/amd64

# Generations
.PHONY: generate-resources
generate-resources: 
	bash ./scripts/generate-resources.sh

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

.PHONY: deploy-llama-stack
deploy-llama-stack:
	bash ./scripts/setup-llama-stack.sh

.PHONY: deploy-sidecars
deploy-sidecars: deploy-lcs deploy-llama-stack deploy-harveser

# Removals
.PHONY: remove-sidecars
remove-sidecars:
	bash ./scripts/remove-sidecars.sh

.PHONY: remove-lcs
remove-lcs:
	bash ./scripts/remove-lcs.sh

.PHONY: remove-llama-stack
remove-llama-stack:
	bash ./scripts/remove-llama-stack.sh

.PHONY: remove-harvester
remove-harvester:
	bash ./scripts/remove-harvester.sh

.PHONY: remove-postgres
remove-postgres:
	bash ./scripts/remove-postgres.sh

.PHONY: remove-all
remove-all: remove-sidecars remove-postgres