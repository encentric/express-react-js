#!/bin/bash -e

SCRIPTPATH="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

# app name is the dir name
APP_NAME=$(basename "$PWD")
OS=$(uname -s)

banner() {
    echo 
    echo $1
    echo ----------------------
}

ensureTool() {
    tool=$1
    if [ ! -x "$(command -v ${tool})" ]; then
        banner "Installing ${tool}"
        brew install ${tool} 
    fi    
}

#----------------------------------------------------------------------------------
# DEV
# inner loop dev.  pack and startup. packes and restarts server on file changes
#----------------------------------------------------------------------------------

dev() {
    npx webpack --watch --mode development    
}

#----------------------------------------------------------------------------------
# BUILD
#----------------------------------------------------------------------------------

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

updateVersion() {
    echo "updating version ..."

    ensureTool gitversion

    gitversion > .version.info

    GIT_VER=$(cat .version.info | jq -r '.MajorMinorPatch')-$(cat .version.info | jq -r '.EscapedBranchName')$(cat .version.info | jq -r '.BuildMetaDataPadded')
    echo $GIT_VER > .version
    cat .version
}

image() {
    banner "Building Container Image"

    # ensure docker is installed
    which docker > /dev/null

    updateVersion

    GIT_VER=$(cat .version)
    VER=${GIT_VER:-latest}
    TAG="${APP_NAME}:${VER}"

    echo Building container ${TAG}

    docker build --progress=plain -t ${TAG} -t ${APP_NAME}:latest .    

    docker images | grep ${APP_NAME}
}

#----------------------------------------------------------------------------------
# TEST
#----------------------------------------------------------------------------------

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

    # TODO fragile. do connect loop or use a real web testing fx (webdriver.io etc)
    sleep 10
    
    banner tests

    echo test home page
    curl -X GET "http://localhost:3000"
    curl -s -X GET "http://localhost:3000" | grep "Hello World"

    stop
}

#----------------------------------------------------------------------------------
# DEPLOY
#----------------------------------------------------------------------------------

healthcheck() {
    URL=${1}
    echo "Checking ${APP_NAME} on ${URL}"

    # app start time
    # TODO, replace with backoff
    sleep 5
    curl -fLs GET "${URL}" > /dev/null
}

kubeEnv() {
    echo "Setting up minikube environment"
    which brew >/dev/null || ( echo "brew required" && exit 1 )

    ensureTool minikube

    # sets variables for minikube to have it's own container registry
    if [ -z "$MINIKUBE_ACTIVE_DOCKERD" ]; then
        eval $(minikube -p $KUBE_CLUSTER_NAME docker-env)
    fi       

    echo "env: ${MINIKUBE_ACTIVE_DOCKERD}"
}

# ./dev deploy {targetEnv}
# targetEnv = dev, staging, prod
deploy() {
    targetEnv=$1

    case $targetEnv in
        dev|staging|prod) banner "Deploying to ${targetEnv}";;
        *)  echo "Invalid env.  must be dev, staging or prod" && exit 1;;
    esac

    echo Current context:
    kubectl config current-context
    if [ "${2}" != "-y" ]; then 
        read -p "Press enter to continue.  ctlc to exit."
    fi

    [ "${targetEnv}" == "dev" ] && kubeEnv

    image

    VER=$(cat .version)
    IMG=${APP_NAME}:${VER}

    echo "Updating kustomization: set image ${IMG}"

    ensureTool kustomize
    pushd ./deploy
    kustomize edit set image "${IMG}"
    popd

    docker images | grep ${APP_NAME}

    echo Deploying ${APP_NAME} service ...

    echo "Apply kubernetes deploy ..."
    kubectl apply -k ./deploy --wait=true # wait for deletes

    # wait for the deployment
    echo "Wait for deployment ..."
    kubectl wait --for=condition=available --timeout=60s deployment/${APP_NAME}

    # [ "${targetEnv}" == "dev" ]
    URL=$(minikube -p $KUBE_CLUSTER_NAME service ${APP_NAME} --url)

    healthcheck ${URL}
}

devupdate() {
    banner "Updating Deployment"

    kubeEnv
    image 
    kubectl rollout restart deploy ${APP_NAME}

    # wait for the deployment
    kubectl wait --for=condition=available --timeout=60s deployment/${APP_NAME}

    healthcheck
}

KUBE_CLUSTER_NAME='local-dev'
KUBE_VERSION='v1.23.0'
KUBE_DISK_SIZE='10GB'
KUBE_MEMORY='2GB'
KUBE_DRIVER='virtualbox'

setupDevCluster() {
    ensureTool minikube 

    echo "minikube cluster: ${KUBE_CLUSTER_NAME}"
    
    echo "Creating minikube cluster $KUBE_CLUSTER_NAME"

    minikube config set WantVirtualBoxDriverWarning false
    minikube start -p $KUBE_CLUSTER_NAME \
            --vm-driver=$KUBE_DRIVER \
            --feature-gates="StartupProbe=true" \
            --feature-gates="EphemeralContainers=true" \
            --extra-config="apiserver.service-node-port-range=1-65535"

    # vmware driver needs
    # if [ $OS == 'Darwin' ]; then
    #     minikube ssh -p $KUBE_CLUSTER_NAME "sudo systemd-resolve --set-dns=1.1.1.1 --interface eth0"
    # fi

    echo "Created."

    minikube status -p $KUBE_CLUSTER_NAME
}

stopDevCluster() {
    ensureTool minikube 

    minikube status -p $KUBE_CLUSTER_NAME
    minikube stop -p $KUBE_CLUSTER_NAME
}


"$@"