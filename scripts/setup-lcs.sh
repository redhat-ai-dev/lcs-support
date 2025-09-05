#!/bin/bash

set -o errexit
set -o errtrace

SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )" 
ROOTDIR=$(realpath $SCRIPTDIR/..)

echo "Sourcing values from $ROOTDIR/env/values ..."
source "$ROOTDIR"/env/values

env_var_checks() {
    if [ -z "$DEPLOYMENT_NAMESPACE" ]; then
        echo "DEPLOYMENT_NAMESPACE unset in environment variables file. Aborting ..."
        exit 1
    fi
    if [ -z "$LCS_IMAGE" ]; then
        echo "LCS_IMAGE unset in environment variables file. Aborting ..."
        exit 1
    fi
    if [ -z "$BACKSTAGE_CR_NAME" ]; then
        echo "BACKSTAGE_CR_NAME unset in environment variables file. Aborting ..."
        exit 1
    fi
    if [ -z "$VLLM_URL" ]; then
        echo "VLLM_URL unset in environment variables file. Aborting ..."
        exit 1
    fi
    if [ -z "$VLLM_API_KEY" ]; then
        echo "VLLM_API_KEY unset in environment variables file. Aborting ..."
        exit 1
    fi
}

setup_editing_env() {
    mkdir "$ROOTDIR"/tmp
    cp "$ROOTDIR"/templates/backstage/sidecar-setup.yaml "$ROOTDIR"/tmp/
    kubectl get -n "$DEPLOYMENT_NAMESPACE" Backstage "$BACKSTAGE_CR_NAME" -o yaml > "$ROOTDIR"/tmp/backstage.yaml
}

apply_resources() {
    echo "Applying resources to $DEPLOYMENT_NAMESPACE namespace ..."
    cp "$ROOTDIR"/resources/lightspeed-stack.yaml "$ROOTDIR"/tmp/
    if kubectl get secret llama-stack-secrets -n "$DEPLOYMENT_NAMESPACE" >/dev/null 2>&1; then
        echo "Secret 'llama-stack-secrets' already exists, skipping creation ..."
    else
        kubectl create secret generic llama-stack-secrets -n $DEPLOYMENT_NAMESPACE \
            --from-literal=VLLM_URL="$VLLM_URL" \
            --from-literal=VLLM_API_KEY="$VLLM_API_KEY"
    fi

    if kubectl get configmap lightspeed-stack -n "$DEPLOYMENT_NAMESPACE" >/dev/null 2>&1; then
        echo "ConfigMap 'lightspeed-stack' already exists, skipping creation ..."
    else
        kubectl create configmap lightspeed-stack --from-file="$ROOTDIR"/tmp/lightspeed-stack.yaml -n "$DEPLOYMENT_NAMESPACE"
    fi
}

configure_sidecar_darwin() {
    # Mac users with gnu-sed will trigger --version, Darwin sed does not support
    if sed --version >/dev/null 2>&1; then
        configure_sidecar_linux
    else
        sed -i '' "s!sed.edit.LCS_IMAGE!$LCS_IMAGE!g" "$ROOTDIR"/tmp/sidecar-setup.yaml
    fi
}

configure_sidecar_linux() {
    sed -i "s!sed.edit.LCS_IMAGE!$LCS_IMAGE!g" "$ROOTDIR"/tmp/sidecar-setup.yaml
}

configure_and_apply_resources() {
    if yq -e '(.spec.deployment.patch.spec.template.spec.containers[] | select(.name == "lightspeed-core"))' "$ROOTDIR"/tmp/backstage.yaml >/dev/null 2>&1; then
        echo "Sidecar container 'lightspeed-core' already present in Backstage CR, skipping patch ..."
        echo "[NOTICE] If you have updated the image, you will need to restart the Backstage Pod to trigger a pull of the new image."
        return
    fi

    if yq -e '(.spec.deployment.patch.spec.template.spec.containers[] | select(.name == "llama-stack"))' "$ROOTDIR"/tmp/backstage.yaml >/dev/null 2>&1; then
        echo "Sidecar container 'llama-stack' already present in Backstage CR, skipping patch ..."
        echo "[NOTICE] If you have updated the image, you will need to restart the Backstage Pod to trigger a pull of the new image."
        return
    fi

    op_sys=$(uname -s)
    if [ "$op_sys" == "Darwin" ]; then
        configure_sidecar_darwin
    else
        configure_sidecar_linux
    fi

    yq eval -i '
    .spec.deployment.patch.spec.template.spec.containers += load("'"${ROOTDIR}/tmp/sidecar-setup.yaml"'").containers |
    .spec.deployment.patch.spec.template.spec.volumes += load("'"${ROOTDIR}/tmp/sidecar-setup.yaml"'").volumes
    ' "$ROOTDIR"/tmp/backstage.yaml
    
    echo "Patching Backstage CR ..."
    kubectl apply -n "$DEPLOYMENT_NAMESPACE" -f "$ROOTDIR"/tmp/backstage.yaml
    echo "Successfully patched Backstage CR ..."
}

cleanup() {
    rm -rf "$ROOTDIR"/tmp
}

env_var_checks
trap cleanup ERR
setup_editing_env
apply_resources
configure_and_apply_resources
cleanup
