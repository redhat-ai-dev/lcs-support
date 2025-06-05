#!/bin/bash

set -o errexit
set -o errtrace

SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )" 
ROOTDIR=$(realpath $SCRIPTDIR/..)

echo "Sourcing values from $ROOTDIR/env/harvester-values ..."
source "$ROOTDIR"/env/harvester-values.sh

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

configure_resources() {
    sed -i "s!sed.edit.PGUSER!$PGUSER!g" "$ROOTDIR"/tmp-postgres/secret/secret.yaml
    sed -i "s!sed.edit.PGPASSWORD!$PGPASSWORD!g" "$ROOTDIR"/tmp-postgres/secret/secret.yaml
    sed -i "s!sed.edit.PGDATABASE!$PGDATABASE!g" "$ROOTDIR"/tmp-postgres/secret/secret.yaml
}

apply_resources() {
    kubectl apply -k "$ROOTDIR"/tmp-postgres
    kubectl apply -n "$RHDH_NAMESPACE" -f "$ROOTDIR/tmp-postgres/secret/secret.yaml"
}

cleanup() {
    rm -rf "$ROOTDIR"/tmp-postgres
}

env_var_checks
trap cleanup ERR
setup_editing_env
configure_resources
apply_resources
cleanup