#!/bin/bash

set -o errexit
set -o errtrace
set -euo pipefail

SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )" 
ROOTDIR=$(realpath $SCRIPTDIR/..)

echo "Sourcing values from $ROOTDIR/env/harvester-values ..."
source "$ROOTDIR"/env/harvester-values.sh

echo "Sourcing values from $ROOTDIR/env/values ..."
source "$ROOTDIR"/env/values

CONTAINER_NAME="feedback-harvester"


setup_editing_env() {
    mkdir "$ROOTDIR"/tmp
    kubectl get -n "$DEPLOYMENT_NAMESPACE" Backstage "$BACKSTAGE_CR_NAME" -o yaml > "$ROOTDIR"/tmp/backstage.yaml
}

remove_container() {
if yq e ".spec.deployment.patch.spec.template.spec.containers[].name == \"$CONTAINER_NAME\"" "$ROOTDIR"/tmp/backstage.yaml | grep -q true; then
    echo "Container '$CONTAINER_NAME' found. Removing..."

    yq e "del(.spec.deployment.patch.spec.template.spec.containers[] | select(.name == \"$CONTAINER_NAME\"))" "$ROOTDIR"/tmp/backstage.yaml > "$ROOTDIR"/tmp/backstage-updated.yaml

    # Apply the updated CR
    kubectl apply -f "$ROOTDIR"/tmp/backstage-updated.yaml

    echo "Container '$CONTAINER_NAME' removed and resource updated."
else
    echo "Container '$CONTAINER_NAME' not found. No changes made."
fi
}

cleanup() {
    rm -rf "$ROOTDIR"/tmp
}

setup_editing_env
trap cleanup ERR
remove_container
cleanup