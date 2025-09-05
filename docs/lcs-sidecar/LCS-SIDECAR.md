# Lightspeed Core Sidecar

## Environment Setup

You can generate your own local copy of:
1. [lightspeed-stack.yaml](../../templates/skeleton/lightspeed-stack.yaml)
2. [values](../../env/default-values)

By running:
```
make generate-all
```

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

To deploy the Lightspeed Core sidecar:

```
make deploy-lcs
```

## Teardown

To remove the Lightspeed Core sidecar:

```
make remove-lcs
```