# Road-Core/Service Sidecar Setup

## Requirements

- [yq](https://github.com/mikefarah/yq/) v4 and above.
- Access to a Kubernetes (or OCP) cluster with permissions to edit CRs and apply resources to namespaces.

## Reliability

This setup script was tested with [Red Hat Developer Hub (RHDH) v1.4](https://docs.redhat.com/en/documentation/red_hat_developer_hub/1.4/) and its [supported OCP versions](https://access.redhat.com/support/policy/updates/developerhub):

- v4.14
- v4.15
- v4.16
- v4.17

## Usage

### Step 1

Run the following command to get your own copy of the necessary resources to use with the setup script. These files will be git ignored.

```
bash ./scripts/generate-resources.sh
```

### Step 2

[Step 1](#step-1) generated various files located in `/resources`. Enter the appropriate data into these files for use with the script, you can view the examples located below for reference:

1. [Single LLM Provider in rcsconfig.yaml](./examples/single-provider/)
2. [Mulitple LLM Providers in rcsconfig.yaml](./examples/multi-provider/)
3. [Custom Prompt Enabled](./examples/custom-prompt-enabled/)
4. [RHDH Config Passed](./examples/rhdh-config-enabled/)
5. [Prompt & RHDH Config](./examples/everything-enabled/)

### Step 3

In [/env](./env/) there is a [default-values](./env/default-values) environment file. Make a copy of that file called `values` in [/env](./env/) and enter the appropriate environment variables.

### Step 4

To add the sidecar to your Red Hat Developer Hub (RHDH) Pod, first ensure you are logged into your cluster and then run:
```
bash ./setup-sidecar.sh
```
