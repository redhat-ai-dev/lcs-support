# Lightspeed Core Sidecar

## Environment Setup

You can generate your own local copy of:
1. [lightspeed-stack.yaml](../../templates/skeleton/lightspeed-stack.yaml)
2. [lightspeed-secret.yaml](../../templates/skeleton/lightspeed-secret.yaml)
3. [values](../../env/default-values)

By running:
```
make generate-all
```

These files are used by the script for properly setting up Lightspeed Core. `lightspeed-stack.yaml` is the configuration file for LCS and with a local copy you are able to make changes as you see fit. 'lightspeed-secret.yaml' is where you will enter your environment variables for Llama Stack, and the `values` file is used for injecting variables in the setup script.

## Configuration

Lightspeed Core is always evolving, currently you can alter the following in your version of `lightspeed-stack.yaml` to change the functionality:

### Feedback Enablement

Can be `true` or `false`:

```
user_data_collection:
  feedback_enabled: <true/false>
  feedback_storage: "/tmp/data/feedback"
```

## Deployment

To deploy the Lightspeed Core & Llama Stack sidecar containers:

```
make deploy-lcs
```

## Teardown

To remove the Lightspeed Core & Llama Stack sidecar containers:

```
make remove-lcs
```