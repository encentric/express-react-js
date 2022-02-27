#!/bin/bash -e

SCRIPTPATH="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

# app name is the dir name
APP_NAME=$(basename "$PWD")
OS=$(uname -s)

updateVersion() {
    banner "updating version ..."
    docker run --rm -v "${SCRIPTPATH}:/repo" gittools/gitversion:5.6.6 /repo
    docker run --rm -v "${SCRIPTPATH}:/repo" gittools/gitversion:5.6.6 /repo > .version.info
    cat .version.info
    GIT_VER=$(cat .version.info | jq -r '.MajorMinorPatch')-$(cat .version.info | jq -r '.EscapedBranchName')$(cat .version.info | jq -r '.BuildMetaDataPadded')
    echo $GIT_VER > .version
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

ensureDeps() {
    BIN_PATH=${SCRIPTPATH}/deps

    # download kustomize cli
    KUSTOMIZE_PATH=${BIN_PATH}/kustomize

    if [ ! -f "${KUSTOMIZE_PATH}" ]; then 
        echo "${KUSTOMIZE_PATH} does not exist. downloading ..."
        mkdir -p ${BIN_PATH}
        pushd "${BIN_PATH}"
        curl -s "https://raw.githubusercontent.com/kubernetes-sigs/kustomize/master/hack/install_kustomize.sh"  | bash    
        popd
    fi
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

    GIT_VER=$(cat .version)
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

    # TODO fragile. do connect loop or use a real web testing fx (webdriver.io etc)
    sleep 10
    
    banner tests

    echo test home page
    curl -X GET "http://localhost:3000"
    curl -s -X GET "http://localhost:3000" | grep "Hello World"

    stop
}

healthcheck() {
    echo "${APP_NAME} running:"
    URL=$(minikube -p $KUBE_CLUSTER_NAME service ${APP_NAME} --url)
    echo $URL

    # app start time
    # TODO, replace with backoff
    sleep 5
    curl -X GET "${URL}"
}

deploy() {
    banner Deploy

    echo Current context:
    kubectl config current-context
    if [ "${2}" != "-y" ]; then 
        read -p "Press enter to continue.  ctlc to exit."
    fi

    ensureDeps

    image

    GIT_VER=$(cat .version)
    VER=${GIT_VER:-latest}
    IMG=${APP_NAME}:${VER}

    echo "Updating kustomization"
    echo "set image ${IMG}"
    pushd ./deploy
    ../deps/kustomize edit set image "${IMG}"
    popd

    docker images | grep ${APP_NAME}

    echo
    echo Deploying ${APP_NAME} service ...

    echo "Apply kubernetes deploy ..."
    kubectl apply -k ./deploy --wait=true # wait for deletes

    # wait for the deployment
    echo "Wait for deployment ..."
    kubectl wait --for=condition=available --timeout=60s deployment/${APP_NAME}

    healthcheck
}

update() {
    ensureDeps

    image 

    kubectl rollout restart deploy ${APP_NAME}

    # wait for the deployment
    kubectl wait --for=condition=available --timeout=60s deployment/${APP_NAME}

    healthcheck
}

KUBE_CLUSTER_NAME='local-dev'

setupDevCluster() {
    KUBE_VERSION='v1.23.0'
    KUBE_DISK_SIZE='10GB'
    KUBE_MEMORY='2GB'
    
    echo "minikube cluster: ${KUBE_CLUSTER_NAME}"
    
    echo "Creating minikube cluster $KUBE_CLUSTER_NAME"
    minikube start -p $KUBE_CLUSTER_NAME \
            --feature-gates="StartupProbe=true" \
            --feature-gates="EphemeralContainers=true" \
            --extra-config="apiserver.service-node-port-range=1-65535"
            #--kubernetes-version=$KUBE_VERSION \
            # --vm-driver=$KUBE_DRIVER \
            # --disk-size=$KUBE_DISK_SIZE \
            # --memory=$KUBE_MEMORY  \            

    # if [ $OS == 'Darwin' ]; then
    #     minikube ssh -p $KUBE_CLUSTER_NAME "sudo systemd-resolve --set-dns=1.1.1.1 --interface eth0"
    # fi
    # The specified interface eth0 is managed by systemd-networkd. Operation refused.
    # Please configure DNS settings for systemd-networkd managed interfaces directly in their .network files.
    # ssh: exit status 1

    echo "Created."

    minikube status -p $KUBE_CLUSTER_NAME

    # if using minikube, setup the proper context so docker and kubectl commands work properly
    # this also allows minikube to see local docker images
    if [ -z "$MINIKUBE_ACTIVE_DOCKERD" ]; then
        eval $(minikube -p $KUBE_CLUSTER_NAME docker-env)
    fi
}

stopDevCluster() {
    minikube status -p $KUBE_CLUSTER_NAME
    minikube stop -p $KUBE_CLUSTER_NAME
}


"$@"