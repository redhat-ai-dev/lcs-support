# Feedback Harvester

To enable the collection of feedback data we must deploy both a harvester sidecar and a postgreSQL database.

You will need to ensure that the steps in [Road-Core-Service Backend Sidecar](../rcs-sidecar/RCS-SIDECAR.md) have been completed. The deployment and use of the Feedback Harvester builds on top of the RCS Sidecar. 

After those steps are complete you can:

1. Create your copy of the necessary values
   1. Create a copy of [default-harvester-values](../../env/default-harvester-values) in [/env](../../env/) named **harvester-values**.
   2. Fill out the environment variables as instructed in the file.
2. Run the following command to deploy postgres and add the required secret to your Red Hat Developer Hub (RHDH) namespace:
```
make deploy-postgres
```
1. After postgres is deployed you can run the following to add the feedback harvester sidecar to your Backstage CR:
```
make deploy-harvester
```

You can find information about the harvester itself in [src/harvester/README.md](../../src/harvester/README.md).