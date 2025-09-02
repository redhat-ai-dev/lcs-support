#!/bin/bash

set -o errexit
set -o errtrace

SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )" 
ROOTDIR=$(realpath $SCRIPTDIR/..)

echo "Sourcing values from $ROOTDIR/env/harvester-values ..."
source "$ROOTDIR"/env/harvester-values

env_var_checks() {
    if [ -z "$PGUSER" ]; then
        echo "PGUSER unset in environment variables file. Aborting ..."
        exit 1
    fi
    if [ -z "$PGPASSWORD" ]; then
        echo "PGPASSWORD unset in environment variables file. Aborting ..."
        exit 1
    fi
    if [ -z "$PGDATABASE" ]; then
        echo "PGDATABASE unset in environment variables file. Aborting ..."
        exit 1
    fi
    if [ -z "$RHDH_NAMESPACE" ]; then
        echo "RHDH_NAMESPACE unset in environment variables file. Aborting ..."
        exit 1
    fi

    echo "Successfully sourced values ..."
}

setup_editing_env() {
    mkdir "$ROOTDIR"/tmp-postgres
    cp -r "$ROOTDIR"/templates/postgres/* "$ROOTDIR"/tmp-postgres/
}

configure_postgres_linux() {
    sed -i "s!sed.edit.PGUSER!'$PGUSER'!g" "$ROOTDIR"/tmp-postgres/secret/secret.yaml
    sed -i "s!sed.edit.PGPASSWORD!'$PGPASSWORD'!g" "$ROOTDIR"/tmp-postgres/secret/secret.yaml
    sed -i "s!sed.edit.PGDATABASE!'$PGDATABASE'!g" "$ROOTDIR"/tmp-postgres/secret/secret.yaml
}

configure_postgres_darwin() {
    # Mac users with gnu-sed will trigger --version, Darwin sed does not support
    if sed --version >/dev/null 2>&1; then
        configure_postgres_linux
    else
        sed -i '' "s!sed.edit.PGUSER!'$PGUSER'!g" "$ROOTDIR"/tmp-postgres/secret/secret.yaml
        sed -i '' "s!sed.edit.PGPASSWORD!'$PGPASSWORD'!g" "$ROOTDIR"/tmp-postgres/secret/secret.yaml
        sed -i '' "s!sed.edit.PGDATABASE!'$PGDATABASE'!g" "$ROOTDIR"/tmp-postgres/secret/secret.yaml
    fi
}

configure_and_apply_resources() {
    if kubectl get namespace dev-postgres >/dev/null 2>&1; then
        echo "Namespace 'dev-postgres' already exists, skipping resource creation ..."
        echo "[NOTICE] If you have updated the Postgres resources, you will need to run 'make remove-postgres' and then 'make deploy-postgres' to apply the changes."
        return
    fi
    op_sys=$(uname -s)
    echo "Configuring Postgres resources ..."
    if [ "$op_sys" == "Darwin" ]; then
        configure_postgres_darwin
    else
        configure_postgres_linux
    fi

    echo "Applying Postgres resources ..."
    kubectl apply -k "$ROOTDIR"/tmp-postgres
    kubectl apply -n "$RHDH_NAMESPACE" -f "$ROOTDIR/tmp-postgres/secret/secret.yaml"
    echo "Successfully applied Postgres resources ..."
}

cleanup() {
    rm -rf "$ROOTDIR"/tmp-postgres
}

env_var_checks
trap cleanup ERR
setup_editing_env
configure_and_apply_resources
cleanup