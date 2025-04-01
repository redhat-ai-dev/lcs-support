#!/bin/bash

SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )" 
ROOTDIR=$(realpath $SCRIPTDIR/..)

echo "Copying files from $ROOTDIR/resources to $ROOTDIR/templates/skeleton ..."
mkdir -p "$ROOTDIR"/resources && cp "$ROOTDIR"/templates/skeleton/* "$ROOTDIR"/resources/
echo "DONE."