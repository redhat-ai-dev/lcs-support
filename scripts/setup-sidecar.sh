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
    if [ -z "$RCS_IMAGE" ]; then
        echo "RCS_IMAGE unset in environment variables file. Aborting ..."
        exit 1
    fi
    if [ -z "$BACKSTAGE_CR_NAME" ]; then
        echo "BACKSTAGE_CR_NAME unset in environment variables file. Aborting ..."
        exit 1
    fi
    if [ "$USE_RHDH_CONFIG" == "true" ]; then
        if [ -z "$RHDH_CONFIG_NAME" ]; then
            echo "RHDH_CONFIG_NAME unset in environment variables file with USE_RHDH_CONFIG set to 'true'. Aborting ..."
            exit 1
        fi
        if [ -z "$RHDH_CONFIG_FILENAME" ]; then
            echo "RHDH_CONFIG_FILENAME unset in environment variables file with USE_RHDH_CONFIG set to 'true'. Aborting ..."
            exit 1
        fi
        if [ -z "$RHDH_SECRETS_NAME" ]; then
            echo "RHDH_SECRETS_NAME unset in environment variables file with USE_RHDH_CONFIG set to 'true'. If your RHDH_CONFIG_FILENAME contains Secrets this should be set ..."
        fi
    fi    
}

setup_editing_env() {
    mkdir "$ROOTDIR"/tmp
    cp "$ROOTDIR"/templates/backstage/sidecar-setup.yaml "$ROOTDIR"/tmp/
    kubectl get -n "$DEPLOYMENT_NAMESPACE" Backstage "$BACKSTAGE_CR_NAME" -o yaml > "$ROOTDIR"/tmp/backstage.yaml
}

apply_resources() {
    echo "Applying resources to $DEPLOYMENT_NAMESPACE namespace ..."
    cp "$ROOTDIR"/resources/rcsconfig.yaml "$ROOTDIR"/tmp/
    if kubectl get secret provider-keys -n "$DEPLOYMENT_NAMESPACE" >/dev/null 2>&1; then
        echo "Secret 'provider-keys' already exists, skipping creation ..."
        echo "[NOTICE] If you have updated the Secret, you will need to run 'make remove-sidecar' and then 'make deploy-sidecar' to apply the changes."
    else
        kubectl apply -n "$DEPLOYMENT_NAMESPACE" -f "$ROOTDIR"/resources/rcssecret.yaml
    fi

    if kubectl get configmap rcsconfig -n "$DEPLOYMENT_NAMESPACE" >/dev/null 2>&1; then
        echo "ConfigMap 'rcsconfig' already exists, skipping creation ..."
        echo "[NOTICE] If you have updated the ConfigMap, you will need to run 'make remove-sidecar' and then 'make deploy-sidecar' to apply the changes."
    else
        kubectl create configmap rcsconfig --from-file="$ROOTDIR"/tmp/rcsconfig.yaml -n "$DEPLOYMENT_NAMESPACE"
    fi
}

configure_sidecar_darwin() {
    sed -i '' "s!sed.edit.RHDH_CONFIG_NAME!$RHDH_CONFIG_NAME!g" "$ROOTDIR"/tmp/sidecar-setup.yaml
    sed -i '' "s!sed.edit.RHDH_CONFIG_FILENAME!$RHDH_CONFIG_FILENAME!g" "$ROOTDIR"/tmp/sidecar-setup.yaml
    sed -i '' "s!sed.edit.RHDH_SECRETS_NAME!$RHDH_SECRETS_NAME!g" "$ROOTDIR"/tmp/sidecar-setup.yaml
    sed -i '' "s!sed.edit.RCS_IMAGE!$RCS_IMAGE!g" "$ROOTDIR"/tmp/sidecar-setup.yaml
}

configure_sidecar_linux() {
    sed -i "s!sed.edit.RHDH_CONFIG_NAME!$RHDH_CONFIG_NAME!g" "$ROOTDIR"/tmp/sidecar-setup.yaml
    sed -i "s!sed.edit.RHDH_CONFIG_FILENAME!$RHDH_CONFIG_FILENAME!g" "$ROOTDIR"/tmp/sidecar-setup.yaml
    sed -i "s!sed.edit.RHDH_SECRETS_NAME!$RHDH_SECRETS_NAME!g" "$ROOTDIR"/tmp/sidecar-setup.yaml
    sed -i "s!sed.edit.RCS_IMAGE!$RCS_IMAGE!g" "$ROOTDIR"/tmp/sidecar-setup.yaml
}

configure_and_apply_resources() {
    if yq -e '(.spec.deployment.patch.spec.template.spec.containers[] | select(.name == "road-core-sidecar"))' "$ROOTDIR"/tmp/backstage.yaml >/dev/null 2>&1; then
        echo "Sidecar container 'road-core-sidecar' already present in Backstage CR, skipping patch ..."
        echo "[NOTICE] If you have updated the image, you will need to restart the Backstage Pod to trigger a pull of the new image."
        return
    fi

    if [ "$USE_RHDH_CONFIG" != "true" ]; then
        yq -i '(.containers[].env) |= map(select(.name != "RHDH_CONFIG_FILE"))' "$ROOTDIR"/tmp/sidecar-setup.yaml
        yq -i '(.containers[].volumeMounts) |= map(select(.name != "sed.edit.RHDH_CONFIG_NAME"))' "$ROOTDIR"/tmp/sidecar-setup.yaml
        yq -i '(.containers[].envFrom) |= map(select(.secretRef.name != "sed.edit.RHDH_SECRETS_NAME"))' "$ROOTDIR"/tmp/sidecar-setup.yaml
    else
        if [ -z "$RHDH_SECRETS_NAME" ]; then
            yq -i '(.containers[].envFrom) |= map(select(.secretRef.name != "sed.edit.RHDH_SECRETS_NAME"))' "$ROOTDIR"/tmp/sidecar-setup.yaml
        fi
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
