#!/bin/bash

set -o errexit
set -o errtrace
set -euo pipefail

SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
ROOTDIR=$(realpath $SCRIPTDIR/..)

echo "Sourcing values from $ROOTDIR/env/values ..."
source "$ROOTDIR"/env/values

CONTAINERS_TO_REMOVE=("lightspeed-core" "llama-stack")
VOLUMES_TO_REMOVE=("lightspeed-stack" "shared-storage" "llama-stack-secrets")
ORIGINAL_CR_FILE="$ROOTDIR/tmp/backstage.yaml"


setup_editing_env() {
    mkdir "$ROOTDIR"/tmp
    kubectl get -n "$DEPLOYMENT_NAMESPACE" Backstage "$BACKSTAGE_CR_NAME" -o yaml > "$ORIGINAL_CR_FILE"
}

remove_sidecar_resources() {
    UPDATED_CR_FILE="$ROOTDIR/tmp/backstage-updated.yaml"

    container_exists=false
    for container in "${CONTAINERS_TO_REMOVE[@]}"; do
        if yq e ".spec.deployment.patch.spec.template.spec.containers[] | select(.name == \"$container\")" "$ORIGINAL_CR_FILE" | grep -q .; then
            container_exists=true
            break
        fi
    done

    if [ "$container_exists" = false ]; then
        echo "No containers found, no changes needed ..."
        return
    fi

    echo "Containers found, proceeding with removal ..."

    container_conditions=$(printf ".name == \"%s\" or " "${CONTAINERS_TO_REMOVE[@]}")
    container_conditions=${container_conditions% or }

    volume_conditions=$(printf ".name == \"%s\" or " "${VOLUMES_TO_REMOVE[@]}")
    volume_conditions=${volume_conditions% or }

    yq e "del(.spec.deployment.patch.spec.template.spec.containers[] | select($container_conditions))" "$ORIGINAL_CR_FILE" | \
    yq e "del(.spec.deployment.patch.spec.template.spec.volumes[] | select($volume_conditions))" - > "$UPDATED_CR_FILE"
    
    echo "Applying updated Backstage CR ..."
    kubectl apply -f "$UPDATED_CR_FILE"
    echo "Successfully removed sidecar resources and updated Backstage CR ..."

    echo "Removing lightspeed-stack Config Map and llama-stack-secrets Secret ..."
    kubectl delete configmap lightspeed-stack -n "$DEPLOYMENT_NAMESPACE" --ignore-not-found=true
    kubectl delete secret llama-stack-secrets -n "$DEPLOYMENT_NAMESPACE" --ignore-not-found=true
    echo "Successfully removed lightspeed-stack Config Map and llama-stack-secrets Secret ..."
}

cleanup() {
    rm -rf "$ROOTDIR"/tmp
}

setup_editing_env
trap cleanup ERR
remove_sidecar_resources
cleanup