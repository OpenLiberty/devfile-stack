#!/bin/bash

# Outer loop test using the devfile-stack-intro application.
# The application image is built using the following arguments: 
#ADD_MP_HEALTH=false and ENABLE_OPENJ9_SCC=true.
echo -e "\n> Docker build with MPH false SCC true args outer loop test"

# Variables.
RUNTIME="$1"
BUILD_TYPE="$2"
BASE_DIR=$(pwd)
RUNTIME_DIR="open-liberty"
MPHOFF_SCCON_COMP_NAME="dbuild-mphoff-sccon"
IMG_NAME="outerloop/devfile-stack-intro:1.0"

mkdir outer-loop-mphOff-sccOn-test-dir
cd outer-loop-mphOff-sccOn-test-dir

echo -e "\n> Clone devfile-stack-intro project"
git clone https://github.com/OpenLiberty/devfile-stack-intro.git
cd devfile-stack-intro

echo -e "\n> Copy Dockerfile and app-deploy.yaml"
if [ "$RUNTIME" = "wl" ]; then
    RUNTIME_DIR="websphere-liberty"
fi

cp "${BASE_DIR}"/stack/"${RUNTIME_DIR}"/outer-loop/"${BUILD_TYPE}"/Dockerfile Dockerfile
cp "${BASE_DIR}"/stack/"${RUNTIME_DIR}"/outer-loop/app-deploy.yaml app-deploy.yaml
IMG_NAME="${IMG_NAME}-${BUILD_TYPE}"

echo -e "\n> Build Docker image"
sed -i '/COPY --from=compile/a RUN true' Dockerfile
docker build --build-arg ADD_MP_HEALTH=false --build-arg ENABLE_OPENJ9_SCC=true -t "$IMG_NAME" .
rc="$?"
if [ "$rc" -ne 0 ]; then
    exit 12
fi

echo -e "\n> Replace variables in app-deploy.yaml"
sed -i 's/{{\.PORT}}/9080/g' app-deploy.yaml
sed -i "s/{{\.COMPONENT_NAME}}/$MPHOFF_SCCON_COMP_NAME/g" app-deploy.yaml
sed -i "s|{{\.CONTAINER_IMAGE}}|$IMG_NAME|g" app-deploy.yaml

echo -e "\n> Base outer loop test run"
BASE_WORK_DIR="$BASE_DIR" COMP_NAME="$MPHOFF_SCCON_COMP_NAME" "${BASE_DIR}"/test/outer-loop/base-outer-loop.sh
rc="$?"
if [ "$rc" -ne 0 ]; then
    exit 12
fi

echo -e "\n> Cleanup: Delete created directories"
cd "$BASE_DIR"; rm -rf outer-loop-mphOff-sccOn-test-dir
