#!/bin/bash

set -o errexit
set -o errtrace
set -euo pipefail

SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )" 
ROOTDIR=$(realpath $SCRIPTDIR/..)

echo "Sourcing values from $ROOTDIR/env/harvester-values ..."
source "$ROOTDIR"/env/harvester-values

echo "Sourcing values from $ROOTDIR/env/values ..."
source "$ROOTDIR"/env/values

# Configuration
NAMESPACE_TO_DELETE="dev-postgres"
SECRET_TO_DELETE="postgres-secret"

if kubectl get namespace "$NAMESPACE_TO_DELETE" > /dev/null 2>&1; then
    echo "Namespace '$NAMESPACE_TO_DELETE' exists. Deleting ..."
    kubectl delete namespace "$NAMESPACE_TO_DELETE" --wait=true
    echo "Namespace '$NAMESPACE_TO_DELETE' deleted ..."
else
    echo "Namespace '$NAMESPACE_TO_DELETE' does not exist. Skipping delete ..."
fi

if kubectl get secret "$SECRET_TO_DELETE" -n "$DEPLOYMENT_NAMESPACE" > /dev/null 2>&1; then
    echo "Deleting secret '$SECRET_TO_DELETE' from namespace '$DEPLOYMENT_NAMESPACE' ..."
    kubectl delete secret "$SECRET_TO_DELETE" -n "$DEPLOYMENT_NAMESPACE"
else
    echo "Secret '$SECRET_TO_DELETE' not found in namespace '$DEPLOYMENT_NAMESPACE'. Skipping delete ..."
fi