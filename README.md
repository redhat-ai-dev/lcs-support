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

1. [Road-Core-Service Backend Sidecar](#road-core-service-backend-sidecar)
2. [Feedback Harvester](#feedback-harvester)

## Road-Core-Service Backend Sidecar

For information about the Road-Core-Service (RCS) Sidecar, including configuration and deployment, see [RCS-SIDECAR.md](./docs/rcs-sidecar/RCS-SIDECAR.md).

## Feedback Harvester

For information about the Feedback Harvester, see [FEEDBACK-HARVESTER.md](./docs/feedback-harvester/FEEDBACK-HARVESTER.md).

## Removing Resources

You can remove any deployed resources by running their remove Make command:

```
make remove-sidecar
```

```
make remove-harvester
```

```
make remove-postgres
```

If you have the RCS sidecar, feedback harvester, and Postgres DB deployed you can remove them all with:

```
make remove-all
```