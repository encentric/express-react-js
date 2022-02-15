#!/bin/bash -e

SCRIPTPATH="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

# app name is the dir name
APP_NAME=$(basename "$PWD")

updateVersion() {
    banner "updating version ..."
    docker run --rm -v "${SCRIPTPATH}:/repo" gittools/gitversion:5.6.6 /repo
    docker run --rm -v "${SCRIPTPATH}:/repo" gittools/gitversion:5.6.6 /repo > .version
    cat .version
}

banner() {
    echo 
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
    banner "Building ..."

    npm --version

    banner "Install ..."
    npm ci

    # compile time check code for correctness.  does not emit compiled code
    banner "Compile checks ..."
    npx tsc 

    # pack and transpile client side js code
    banner "Webpack ..."
    npx webpack --mode production
}

image() {
    # ensure docker is installed
    which docker > /dev/null

    updateVersion

    GIT_VER=$(cat .version | jq -r '.MajorMinorPatch')-$(cat .version | jq -r '.EscapedBranchName')$(cat .version | jq -r '.BuildMetaDataPadded')

    VER=${GIT_VER:-latest}
    TAG="${APP_NAME}:${VER}"

    echo Building container ${TAG}

    docker build --progress=plain -t ${TAG} -t ${APP_NAME}:latest .    

    docker images | grep ${APP_NAME}
}

function stopSvc {
    docker stop $1 > /dev/null 2>&1 || true
    docker rm $1 > /dev/null 2>&1 || true    
}

run() {
    banner "stopping ..."
    stopSvc ${APP_NAME}

    banner run ...
    docker run -d --rm -p 3000:3000 --name ${APP_NAME}  ${APP_NAME}:latest
}

stop() {
    banner "stopping ..."
    stopSvc ${APP_NAME}
}

e2e() {
    banner "e2e..."
    run

    sleep 2
    
    banner tests

    echo test home page
    curl -s -X GET "http://localhost:3000" | grep "Hello World"

    stop
}


"$@"