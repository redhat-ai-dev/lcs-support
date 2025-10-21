#!/bin/bash

set -o errexit
set -o errtrace

SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )" 
ROOTDIR=$(realpath $SCRIPTDIR/..)

echo "Sourcing values from $ROOTDIR/env/values ..."
source "$ROOTDIR"/env/values

DEFAULT_LCS_IMAGE="quay.io/lightspeed-core/lightspeed-stack:dev-latest"
DEFAULT_LLS_IMAGE="quay.io/redhat-ai-dev/llama-stack:latest"
DEFAULT_RAG_IMAGE="quay.io/redhat-ai-dev/rag-content:release-1.7-lcs"

op_sys=$(uname -s)

env_var_checks() {
    if [ -z "$DEPLOYMENT_NAMESPACE" ]; then
        echo "DEPLOYMENT_NAMESPACE unset in environment variables file. Aborting ..."
        exit 1
    fi
    if [ -z "$BACKSTAGE_CR_NAME" ]; then
        echo "BACKSTAGE_CR_NAME unset in environment variables file. Aborting ..."
        exit 1
    fi
    if [ -z "$LCS_IMAGE" ]; then
        echo "LCS_IMAGE unset in environment variables file ..."
        echo "Defaulting to $DEFAULT_LCS_IMAGE ..."
        LCS_IMAGE=$DEFAULT_LCS_IMAGE
    fi
    if [ -z "$LLS_IMAGE" ]; then
        echo "LLS_IMAGE unset in environment variables file ..."
        echo "Defaulting to $DEFAULT_LLS_IMAGE ..."
        LLS_IMAGE=$DEFAULT_LLS_IMAGE
    fi
    if [ -z "$RAG_IMAGE" ]; then
        echo "RAG_IMAGE unset in environment variables file ..."
        echo "Defaulting to $DEFAULT_RAG_IMAGE ..."
        RAG_IMAGE=$DEFAULT_RAG_IMAGE
    fi
}

setup_editing_env() {
    mkdir "$ROOTDIR"/tmp
    cp "$ROOTDIR"/templates/backstage/sidecar-setup.yaml "$ROOTDIR"/tmp/
    kubectl get -n "$DEPLOYMENT_NAMESPACE" Backstage "$BACKSTAGE_CR_NAME" -o yaml > "$ROOTDIR"/tmp/backstage.yaml
}

configure_lcs_stack_darwin() {
    # Mac users with gnu-sed will trigger --version, Darwin sed does not support
    if sed --version >/dev/null 2>&1; then
        configure_lcs_stack_linux
    else
        if [[ -z "$MCP_SERVER_NAME" || -z "$MCP_SERVER_URL" ]]; then
            sed -i '' '/# MCP_OVERRIDE_MOUNT_START/,/# MCP_OVERRIDE_MOUNT_END/d' "$ROOTDIR"/tmp/lightspeed-stack.yaml
        else
            sed -i '' "s!sed.edit.MCP_SERVER_NAME!$MCP_SERVER_NAME!g" "$ROOTDIR"/tmp/lightspeed-stack.yaml
            sed -i '' "s!sed.edit.MCP_SERVER_URL!$MCP_SERVER_URL!g" "$ROOTDIR"/tmp/lightspeed-stack.yaml
        fi
    fi
}

configure_lcs_stack_linux() {
    if [[ -z "$MCP_SERVER_NAME" || -z "$MCP_SERVER_URL" ]]; then
        sed -i '/# MCP_OVERRIDE_MOUNT_START/,/# MCP_OVERRIDE_MOUNT_END/d' "$ROOTDIR"/tmp/lightspeed-stack.yaml
    else
        sed -i "s!sed.edit.MCP_SERVER_NAME!$MCP_SERVER_NAME!g" "$ROOTDIR"/tmp/lightspeed-stack.yaml
        sed -i "s!sed.edit.MCP_SERVER_URL!$MCP_SERVER_URL!g" "$ROOTDIR"/tmp/lightspeed-stack.yaml  
    fi
}

apply_resources() {
    echo "Applying resources to $DEPLOYMENT_NAMESPACE namespace ..."
    cp "$ROOTDIR"/resources/* "$ROOTDIR"/tmp/
    if kubectl get secret llama-stack-secrets -n "$DEPLOYMENT_NAMESPACE" >/dev/null 2>&1; then
        echo "Secret 'llama-stack-secrets' already exists, skipping creation ..."
    else
        kubectl apply -n "$DEPLOYMENT_NAMESPACE" -f "$ROOTDIR/tmp/lightspeed-secret.yaml"
    fi

    if kubectl get configmap lightspeed-stack -n "$DEPLOYMENT_NAMESPACE" >/dev/null 2>&1; then
        echo "ConfigMap 'lightspeed-stack' already exists, skipping creation ..."
    else
        if [ "$op_sys" == "Darwin" ]; then
            configure_lcs_stack_darwin
        else
            configure_lcs_stack_linux
        fi
        kubectl create configmap lightspeed-stack --from-file="$ROOTDIR"/tmp/lightspeed-stack.yaml -n "$DEPLOYMENT_NAMESPACE"
    fi
    if kubectl get configmap llama-stack-config -n "$DEPLOYMENT_NAMESPACE" >/dev/null 2>&1; then
        echo "ConfigMap 'llama-stack-config' already exists, skipping creation ..."
    else
        if [ -f "$ROOTDIR"/tmp/run.yaml ]; then
            kubectl create configmap llama-stack-config --from-file="$ROOTDIR"/tmp/run.yaml -n "$DEPLOYMENT_NAMESPACE"
        fi
    fi
    
}

configure_sidecar_darwin() {
    # Mac users with gnu-sed will trigger --version, Darwin sed does not support
    if sed --version >/dev/null 2>&1; then
        configure_sidecar_linux
    else
        sed -i '' "s!sed.edit.LCS_IMAGE!$LCS_IMAGE!g" "$ROOTDIR"/tmp/sidecar-setup.yaml
        sed -i '' "s!sed.edit.LLS_IMAGE!$LLS_IMAGE!g" "$ROOTDIR"/tmp/sidecar-setup.yaml
        sed -i '' "s!sed.edit.RAG_IMAGE!$RAG_IMAGE!g" "$ROOTDIR"/tmp/sidecar-setup.yaml
        
        if [ ! -f "$ROOTDIR"/tmp/run.yaml ]; then
            sed -i '' '/# LLAMA_OVERRIDE_MOUNT_START/,/# LLAMA_OVERRIDE_MOUNT_END/d' "$ROOTDIR"/tmp/sidecar-setup.yaml
            sed -i '' '/# LLAMA_OVERRIDE_VOLUME_START/,/# LLAMA_OVERRIDE_VOLUME_END/d' "$ROOTDIR"/tmp/sidecar-setup.yaml
        fi
    fi
}

configure_sidecar_linux() {
    sed -i "s!sed.edit.LCS_IMAGE!$LCS_IMAGE!g" "$ROOTDIR"/tmp/sidecar-setup.yaml
    sed -i "s!sed.edit.LLS_IMAGE!$LLS_IMAGE!g" "$ROOTDIR"/tmp/sidecar-setup.yaml
    sed -i "s!sed.edit.RAG_IMAGE!$RAG_IMAGE!g" "$ROOTDIR"/tmp/sidecar-setup.yaml
    
    if [ ! -f "$ROOTDIR"/tmp/run.yaml ]; then
        sed -i '/# LLAMA_OVERRIDE_MOUNT_START/,/# LLAMA_OVERRIDE_MOUNT_END/d' "$ROOTDIR"/tmp/sidecar-setup.yaml
        sed -i '/# LLAMA_OVERRIDE_VOLUME_START/,/# LLAMA_OVERRIDE_VOLUME_END/d' "$ROOTDIR"/tmp/sidecar-setup.yaml
    fi
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

    if [ "$op_sys" == "Darwin" ]; then
        configure_sidecar_darwin
    else
        configure_sidecar_linux
    fi

    yq eval -i '
    .spec.deployment.patch.spec.template.spec.initContainers += load("'"${ROOTDIR}/tmp/sidecar-setup.yaml"'").initContainers |
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

echo "Detected OS is $op_sys"

env_var_checks
trap cleanup ERR
setup_editing_env
apply_resources
configure_and_apply_resources
cleanup
