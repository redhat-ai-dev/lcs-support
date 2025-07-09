# Feedback Harvester

To enable the collection of feedback data we must deploy both a harvester sidecar and a PostgreSQL database.

You will need to ensure that the steps in [Road-Core-Service Backend Sidecar](../rcs-sidecar/RCS-SIDECAR.md) have been completed. The deployment and use of the Feedback Harvester builds on top of the Road Core Service (RCS) Sidecar. 

After those steps are complete you can:

1. Create a local copy of necessary environment variables:
   1. Create a copy of [default-harvester-values](../../env/default-harvester-values) in [/env](../../env/) named `harvester-values`.
   2. Populate the values following the instructions within the file.
2. Run the following command to deploy PostgreSQL and add the required Secret to your Red Hat Developer Hub (RHDH) namespace:
```
make deploy-postgres
```
1. After PostgreSQL is deployed you can run the following to add the feedback harvester sidecar to your Backstage Custom Resource (CR):
```
make deploy-harvester
```

You can find information about the harvester itself, including how to build it, in [src/harvester/README.md](../../src/harvester/README.md).