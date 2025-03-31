# Single LLM Provider With RHDH Config & Custom Prompt

This example represents a single LLM Provider defined in the Road-Core Service and has a single provider key. Additionally, the modifiers for passing the Red Hat Developer Hub (RHDH) Config Map and loading a custom prompt are both enabled. The RHDH Config Map does not contain any environment variables via Kubernetes Secrets within it so the `RHDH_SECRETS_NAME` value was left blank in the environment file below.

You can view the placeholder examples for each resource below:

- [rcsconfig.yaml](./rcsconfig.yaml)
- [rcssecret.yaml](./rcssecret.yaml)
- [rcsprompt.yaml](./rcsprompt.yaml)
- [Example env file](./placeholder-values)