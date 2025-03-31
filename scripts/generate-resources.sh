#!/bin/bash

SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )" 
ROOTDIR=$(realpath $SCRIPTDIR/..)

mkdir -p "$ROOTDIR"/resources && cp "$ROOTDIR"/templates/skeleton/* "$ROOTDIR"/resources/