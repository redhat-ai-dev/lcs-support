# Road-Core-Service (RCS) Support

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