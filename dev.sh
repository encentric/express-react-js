#!/bin/bash -e

SCRIPTPATH="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

# app name is the dir name
APP_NAME=$(basename "$PWD")

updateVersion() {
    docker run --rm -v "${SCRIPTPATH}:/repo" gittools/gitversion:5.6.6 /repo > .version
}

banner() {
    echo ----------------------
    echo $1
    echo ----------------------
}

#
# inner loop dev.  pack and startup. packes and restarts server on file changes
#
dev() {
    npx webpack --watch --mode development    
}

#
# build a production container
#
build() {
    banner Building ...

    npm --version

    banner Install ...
    npm ci

    # compile time check code for correctness.  does not emit compiled code
    banner Compile checks ...
    npx tsc 

    # pack and transpile client side js code
    banner Webpack ...
    npx webpack --mode production
}

image() {
    # ensure docker is installed
    which docker > /dev/null

    updateVersion

    GIT_VER=$(cat .version | jq -r '.MajorMinorPatch')-$(cat .version | jq -r '.BranchName')$(cat .version | jq -r '.BuildMetaDataPadded')

    VER=${GIT_VER:-latest}
    TAG="${APP_NAME}:${VER}"

    echo Building container ${TAG}

    docker build --progress=plain -t ${TAG} .    
}

"$@"