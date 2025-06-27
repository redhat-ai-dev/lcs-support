#!/bin/bash

set -o errexit
set -o errtrace
set -euo pipefail

SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
ROOTDIR=$(realpath $SCRIPTDIR/..)

echo "Sourcing values from $ROOTDIR/env/values ..."
source "$ROOTDIR"/env/values

CONTAINER_NAME="road-core-sidecar"
VOLUMES_TO_REMOVE=("rcsconfig" "provider-keys" "shared-data")
ORIGINAL_CR_FILE="$ROOTDIR/tmp/backstage.yaml"


setup_editing_env() {
    mkdir "$ROOTDIR"/tmp
    kubectl get -n "$DEPLOYMENT_NAMESPACE" Backstage "$BACKSTAGE_CR_NAME" -o yaml > "$ORIGINAL_CR_FILE"
}

remove_sidecar_resources() {
    UPDATED_CR_FILE="$ROOTDIR/tmp/backstage-updated.yaml"

    if ! yq e ".spec.deployment.patch.spec.template.spec.containers[] | select(.name == \"$CONTAINER_NAME\")" "$ORIGINAL_CR_FILE" | grep -q .; then
        echo "Container '$CONTAINER_NAME' not found, no changes needed ..."
        return
    fi

    echo "Container '$CONTAINER_NAME' found, proceeding with removal ..."

    volume_conditions=$(printf ".name == \"%s\" or " "${VOLUMES_TO_REMOVE[@]}")
    volume_conditions=${volume_conditions% or }

    yq e "del(.spec.deployment.patch.spec.template.spec.containers[] | select(.name == \"$CONTAINER_NAME\"))" "$ORIGINAL_CR_FILE" | \
    yq e "del(.spec.deployment.patch.spec.template.spec.volumes[] | select($volume_conditions))" - > "$UPDATED_CR_FILE"

    
    echo "Applying updated Backstage CR ..."
    kubectl apply -f "$UPDATED_CR_FILE"
    echo "Successfully removed sidecar resources and updated Backstage CR ..."

    echo "Removing rcsconfig configmap and provider-keys secret ..."
    kubectl delete configmap rcsconfig -n "$DEPLOYMENT_NAMESPACE" --ignore-not-found=true
    kubectl delete secret provider-keys -n "$DEPLOYMENT_NAMESPACE" --ignore-not-found=true
    echo "Successfully removed rcsconfig configmap and provider-keys secret ..."
}

cleanup() {
    rm -rf "$ROOTDIR"/tmp
}

setup_editing_env
trap cleanup ERR
remove_sidecar_resources
cleanup