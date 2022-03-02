#!/bin/bash -e

SCRIPTPATH="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

# app name is the dir name
APP_NAME=$(basename "$PWD")
OS=$(uname -s)
 
#----------------------------------------------------------------------------------
# Config
#----------------------------------------------------------------------------------

URL_STAGING="http://someurl.com/path"
URL_PROD="http://someurl.com/path"

# dev minikube settings
KUBE_CLUSTER_NAME='local-dev'
KUBE_VERSION='v1.23.0'
KUBE_DISK_SIZE='10GB'
KUBE_MEMORY='2GB'
KUBE_DRIVER='virtualbox'


#----------------------------------------------------------------------------------
# Util
#----------------------------------------------------------------------------------

banner() {
    echo 
    echo "🟧 ${1}"
}

section() {
    echo 
    echo "👉 ${1}"
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
    section "Building ..."

    echo "npm: $(npm --version)"

    section "Install ..."
    npm ci

    # compile time check code for correctness.  does not emit compiled code
    section "Compile checks ..."
    npx tsc 

    # pack and transpile client side js code
    section "Webpack ..."
    npx webpack --mode production
}

updateVersion() {
    echo "updating version ..."

    echo "$(cat .version.info)-$(git branch --show-current)-$(git rev-list HEAD --count)" > .version
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

    echo "✅ Built ${TAG}"
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

    echo "✅ Passed"
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

getUrl() {
    mode=${1}

    case $mode in
        dev) echo $(minikube -p $KUBE_CLUSTER_NAME service ${APP_NAME} --url);;
        staging) echo ${URL_STAGING};;
        prod) echo ${URL_PROD};;
    esac 
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

preDeploy() {
    targetEnv=$1

    case $targetEnv in
        dev|staging|prod) echo "environment: ${targetEnv}";;
        *)  echo "Invalid env.  must be dev, staging or prod" && exit 1;;
    esac

    echo Current context:
    kubectl config current-context
    if [ "${2}" != "-y" ]; then 
        read -p "Press enter to continue.  ctlc to exit."
    fi

    [ "${targetEnv}" == "dev" ] && kubeEnv    
}

# ./dev deploy {targetEnv}
# targetEnv = dev, staging, prod
deploy() {
    banner "Deploying"
    preDeploy "$@"

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
    URL=$(getUrl ${targetEnv})
    healthcheck ${URL}

    echo "✅ Deployed ${URL}"
    open ${URL}
}

update() {
    banner "Updating Deployment"
    preDeploy "$@"    

    image 
    kubectl rollout restart deploy ${APP_NAME}

    # wait for the deployment
    kubectl wait --for=condition=available --timeout=60s deployment/${APP_NAME}

    URL=$(getUrl ${targetEnv})
    healthcheck ${URL}

    echo "✅ Updated ${URL}"
    open ${URL}
}

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