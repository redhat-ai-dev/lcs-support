#!/bin/bash

set -o errexit
set -o errtrace

SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )" 
ROOTDIR=$(realpath $SCRIPTDIR/..)

echo "Sourcing values from $ROOTDIR/env/harvester-values ..."
source "$ROOTDIR"/env/harvester-values.sh

echo "Sourcing values from $ROOTDIR/env/values ..."
source "$ROOTDIR"/env/values

env_var_checks() {
    if [ -z "$FETCH_FREQUENCY" ]; then
        echo "FETCH_FREQUENCY unset in environment variables file. Harvester will use its default value ..."
    fi
    if [ -z "$HARVESTER_IMAGE" ]; then
        echo "HARVESTER_IMAGE unset in environment variables file. Aborting ..."
        exit 1
    fi
    if [ -z "$RHDH_NAMESPACE" ]; then
        echo "RHDH_NAMESPACE unset in environment variables file. Aborting ..."
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
    kubectl get -n "$RHDH_NAMESPACE" Backstage "$BACKSTAGE_CR_NAME" -o yaml > "$ROOTDIR"/tmp-harvester/backstage.yaml
}

configure_resources() {
    if [ -z "$FETCH_FREQUENCY" ]; then
        yq -i '(.containers[].env) |= map(select(.name != "FETCH_FREQUENCY"))' "$ROOTDIR"/tmp-harvester/harvester-setup.yaml
    else
        sed -i "s!sed.edit.FETCH_FREQUENCY!$FETCH_FREQUENCY!g" "$ROOTDIR"/tmp-harvester/harvester-setup.yaml
    fi
    
    sed -i "s!sed.edit.HARVESTER_IMAGE!$HARVESTER_IMAGE!g" "$ROOTDIR"/tmp-harvester/harvester-setup.yaml

    # add containers and volumes values to backstage CR
    yq eval -i '
    .spec.deployment.patch.spec.template.spec.containers += load("'"${ROOTDIR}/tmp-harvester/harvester-setup.yaml"'").containers
    ' "$ROOTDIR"/tmp-harvester/backstage.yaml
}

apply_resources() {
    echo "Patching Backstage CR ..."
    kubectl apply -n "$RHDH_NAMESPACE" -f "$ROOTDIR"/tmp-harvester/backstage.yaml
    echo "DONE."
}

cleanup() {
    rm -rf "$ROOTDIR"/tmp-harvester
}

env_var_checks
trap cleanup ERR
setup_editing_env
configure_resources
apply_resources
cleanup