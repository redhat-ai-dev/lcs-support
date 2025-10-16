#!/bin/bash

set -o errexit
set -o errtrace

SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )" 
ROOTDIR=$(realpath $SCRIPTDIR/..)

echo "Sourcing values from $ROOTDIR/env/values ..."
source "$ROOTDIR"/env/values

DEFAULT_HARVESTER_IMAGE="quay.io/redhat-ai-dev/feedback-harvester:latest"

env_var_checks() {
    if [ -z "$FETCH_FREQUENCY" ]; then
        echo "FETCH_FREQUENCY unset in environment variables file. Harvester will use its default value ..."
    fi
    if [ -z "$HARVESTER_IMAGE" ]; then
        echo "HARVESTER_IMAGE unset in environment variables file ..."
        echo "Defaulting to $DEFAULT_HARVESTER_IMAGE ..."
        HARVESTER_IMAGE=$DEFAULT_HARVESTER_IMAGE
    fi
    if [ -z "$DEPLOYMENT_NAMESPACE" ]; then
        echo "DEPLOYMENT_NAMESPACE unset in environment variables file. Aborting ..."
        exit 1
    fi
    if [ -z "$BACKSTAGE_CR_NAME" ]; then
        echo "BACKSTAGE_CR_NAME unset in environment variables file. Aborting ..."
        exit 1
    fi
    echo "Successfully sourced values ..."
}

setup_editing_env() {
    mkdir "$ROOTDIR"/tmp-harvester
    cp "$ROOTDIR"/templates/backstage/harvester-setup.yaml "$ROOTDIR"/tmp-harvester/
    kubectl get -n "$DEPLOYMENT_NAMESPACE" Backstage "$BACKSTAGE_CR_NAME" -o yaml > "$ROOTDIR"/tmp-harvester/backstage.yaml
}

configure_harvester_linux() {
    if [ -n "$FETCH_FREQUENCY" ]; then
        sed -i "s!sed.edit.FETCH_FREQUENCY!$FETCH_FREQUENCY!g" "$ROOTDIR"/tmp-harvester/harvester-setup.yaml
    fi
    sed -i "s!sed.edit.HARVESTER_IMAGE!$HARVESTER_IMAGE!g" "$ROOTDIR"/tmp-harvester/harvester-setup.yaml
}

configure_harvester_darwin() {
    # Mac users with gnu-sed will trigger --version, Darwin sed does not support
    if sed --version >/dev/null 2>&1; then
        configure_harvester_linux
    else
        if [ -n "$FETCH_FREQUENCY" ]; then
            sed -i '' "s!sed.edit.FETCH_FREQUENCY!$FETCH_FREQUENCY!g" "$ROOTDIR"/tmp-harvester/harvester-setup.yaml
        fi
        sed -i '' "s!sed.edit.HARVESTER_IMAGE!$HARVESTER_IMAGE!g" "$ROOTDIR"/tmp-harvester/harvester-setup.yaml
    fi
}

configure_and_apply_resources() {
    if yq -e '(.spec.deployment.patch.spec.template.spec.containers[] | select(.name == "feedback-harvester"))' "$ROOTDIR"/tmp-harvester/backstage.yaml >/dev/null 2>&1; then
        echo "Harvester container 'feedback-harvester' already present in Backstage CR, skipping patch ..."
        echo "[NOTICE] If you have updated the image, you will need to restart the Backstage Pod to trigger a pull of the new image."
        return
    fi

    op_sys=$(uname -s)

    if [ -z "$FETCH_FREQUENCY" ]; then
        yq -i '(.containers[].env) |= map(select(.name != "FETCH_FREQUENCY"))' "$ROOTDIR"/tmp-harvester/harvester-setup.yaml
    fi
    
    if [ "$op_sys" == "Darwin" ]; then
        configure_harvester_darwin
    else
        configure_harvester_linux
    fi

    yq eval -i '
    .spec.deployment.patch.spec.template.spec.containers += load("'"${ROOTDIR}/tmp-harvester/harvester-setup.yaml"'").containers
    ' "$ROOTDIR"/tmp-harvester/backstage.yaml

    echo "Patching Backstage CR ..."
    kubectl apply -n "$DEPLOYMENT_NAMESPACE" -f "$ROOTDIR"/tmp-harvester/backstage.yaml
    echo "Successfully patched Backstage CR ..."
}

cleanup() {
    rm -rf "$ROOTDIR"/tmp-harvester
}

env_var_checks
trap cleanup ERR
setup_editing_env
configure_and_apply_resources
cleanup