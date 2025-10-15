#!/bin/bash

SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )" 
ROOTDIR=$(realpath $SCRIPTDIR/..)

echo "Creating copy of environment files in $ROOTDIR/env ..."
cp "$ROOTDIR/env/default-values" "$ROOTDIR/env/values"
echo "Files generated ..."