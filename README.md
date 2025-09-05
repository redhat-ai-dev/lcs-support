# Lightspeed-Core-Service (LCS) Support

> [!IMPORTANT]
> This repository is currently in development migrating from [Road Core](https://github.com/road-core/service) to [Lightspeed Core](https://github.com/lightspeed-core/lightspeed-stack). The Road Core specific source code can be found in the [road-core branch](https://github.com/redhat-ai-dev/rcs-support/tree/road-core), and [v0.1.0](https://github.com/redhat-ai-dev/rcs-support/releases/tag/v0.1.0) is the final stable release for Road Core related support.

## Requirements

- [yq](https://github.com/mikefarah/yq/) v4 and above.
- Access to a Kubernetes (or OCP) cluster with permissions to edit CRs and apply resources to namespaces.

## Reliability

This setup script was tested with [Red Hat Developer Hub (RHDH) v1.4](https://docs.redhat.com/en/documentation/red_hat_developer_hub/1.4/) and its [supported OCP versions](https://access.redhat.com/support/policy/updates/developerhub):

- v4.14
- v4.15
- v4.16
- v4.17

## Scripts

This repository holds multiple setup scripts you can use to deploy resources.

1. [Lightspeed Core Service Sidecar](#lightspeed-core-service-and-llama-stack-service-sidecars)
2. [Feedback Harvester](#feedback-harvester)

## Lightspeed Core Service and Llama Stack Service Sidecars

When using the setup capabilities of this repository, Lightspeed Core and Llama Stack will be deployed together, each as a separate service. 

The Llama Stack image is built from [https://github.com/redhat-ai-dev/llama-stack](https://github.com/redhat-ai-dev/llama-stack) and contains the latest needs of our team.

For information about the Lightspeed Core Service (LCS) sidecar, including configuration and deployment, see [LCS-SIDECAR.md](./docs/lcs-sidecar/LCS-SIDECAR.md).

## Feedback Harvester

For information about the Feedback Harvester, see [FEEDBACK-HARVESTER.md](./docs/feedback-harvester/FEEDBACK-HARVESTER.md).

## Make Commands

| Command | Description |
|--------- | ---------- |
| **generate-resources** | Creates copies of all required `.yaml` resource files for editing. |
| **generate-env** | Create copies of all required `.env` files for local editing. |
| **generate-all** | Run both `generate-rsources` and `generate-env`. |
| **build-harvester** | Builds the Feedback Harvester image. |
| **deploy-lcs** | Deploys the Lightspeed Core and Llama Stack sidecars. |
| **deploy-harvester**| Deploys the Feedback Harvester sidecar. |
| **deploy-postgres** | Deploys the PostgreSQL database. |
| **remove-lcs** | Removes the Lightspeed Core and Llama Stack sidecars. |
| **remove-harvester** | Removes the Feedback Harvester sidecar. |
| **remove-postgres** | Removes the PostgreSQL database. |
| **remove-all** | Removes all resources from all deploy commands (full wipe). |
