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

These files are used by the script for properly setting up Lightspeed Core. `lightspeed-stack.yaml` is the configuration file for LCS and with a local copy you are able to make changes as you see fit. `lightspeed-secret.yaml` is where you will enter your environment variables for Llama Stack, and the `values` file is used for injecting variables in the setup script.

> [!IMPORTANT]
> You must ensure you have `VALIDATION_PROVIDER` and `VALIDATION_MODEL_NAME` set in the Secret, as well as one of `VLLM_URL + VLLM_API_KEY`, `OLLAMA_URL` or `OPENAI_API_KEY`, depending on the provider you have enabled in your Llama Stack `run.yaml`. By default (if you are not overriding it), you will need to set `VLLM_URL` and `VLLM_API_KEY`.
>
> `VALIDATION_PROVIDER` can currently be one of `vllm, ollama, or openai`, depending on what provider you are using in your `run.yaml`.

## Configuration

Lightspeed Core is always evolving, currently you can alter the following in your version of `lightspeed-stack.yaml` to change the functionality:

### Feedback Enablement

Can be `true` or `false`:

```
user_data_collection:
  feedback_enabled: <true/false>
  feedback_storage: "/tmp/data/feedback"
```

### Conversation History

By default, the conversation history is being stored in SQLite through Lightspeed Core. You can use PostgreSQL instead by replacing the `conversation_cache` entry in your copy of `lightspeed-stack.yaml` in `/resources` with the following:

```
conversation_cache: 
  type: "postgres"
  postgres:
    host: <your-hostname>
    port: <port>
    db: <your-db>
    user: <your-username>
    password: <your-password>
```

### Setting Up PostgreSQL For Conversation History

> [!IMPORTANT]
>
> You can leverage the PostgreSQL database setup that is part of this repository to easily spin up a PostgreSQL instance.

1. Ensure the Postgres values are set in your `env/values` file.
2. Run `make deploy-postgres`.
3. Make sure your `conversation_cache` section in your `lightspeed-stack.yaml` file is updated:
```
conversation_cache: 
  type: "postgres"
  postgres:
    host: postgres-svc.dev-postgres.svc.cluster.local
    port: 5432
    db: <your PGDATABASE value>
    user: <your PGUSER value>
    password: <your PGPASSWORD value>
```

**Note:** It is important to ensure you place the values for `PGDATABASE`, `PGUSER`, and `PGPASSWORD` in the `lightspeed-stack.yaml` file. The environment variables are not expanded in Lightspeed Core and as such we cannot pass them as such at this time.



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