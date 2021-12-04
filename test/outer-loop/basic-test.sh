#!/bin/bash

# Basic outer loop test using the devfile-stack-intro application.
# The application image is built using the default values. For example, 
# the following arguments: ADD_MP_HEALTH=true and ENABLE_OPENJ9_SCC=true.
echo -e "\n> Basic outer loop test"

# Base work directory.
BASE_DIR=$(pwd)

# WLP install path
WLP_INSTALL_PATH="${WLP_INSTALL_PATH:-/opt/ol/wlp}"

# Component name. 
BASIC_COMP_NAME="basic-outer-loop"

mkdir basic-outer-loop-test-dir
cd basic-outer-loop-test-dir

echo -e "\n> Clone devfile-stack-intro project"
git clone https://github.com/OpenLiberty/devfile-stack-intro.git
cd devfile-stack-intro

echo -e "\n> Copy Dockerfile and app-deploy.yaml"
runtime="$1"
buldType="$2"
runtimeDir="open-liberty"
if [ "$runtime" = "wl" ]; then
  runtimeDir="websphere-liberty"
fi

if [ "$buldType" = "gradle" ]; then
  cp $BASE_DIR/stack/"${runtimeDir}"/outer-loop/gradle/Dockerfile Dockerfile
  WLP_INSTALL_PATH=/projects/build/wlp
else
  cp $BASE_DIR/stack/"${runtimeDir}"/outer-loop/maven/Dockerfile Dockerfile
fi

cp $BASE_DIR/stack/"${runtimeDir}"/outer-loop/app-deploy.yaml app-deploy.yaml

echo -e "\n> Build Docker image"
sed -i '/COPY --from=compile/a RUN true' Dockerfile
docker build -t outerloop/devfile-stack-intro:1.0 .

echo -e "\n> Replace variables in app-deploy.yaml"
sed -i 's/{{\.PORT}}/9080/g' app-deploy.yaml
sed -i "s/{{\.COMPONENT_NAME}}/${BASIC_COMP_NAME}/g" app-deploy.yaml
sed -i 's/{{\.CONTAINER_IMAGE}}/outerloop\/devfile-stack-intro:1\.0/g' app-deploy.yaml

echo -e "\n> Base outer loop test run"
BASE_WORK_DIR=$BASE_DIR COMP_NAME=${BASIC_COMP_NAME} $BASE_DIR/test/outer-loop/base-outer-loop.sh
rc=$?
if [ $rc -ne 0 ]; then
    exit 12
fi

echo -e "\n> Cleanup: Delete created directories"
cd $BASE_DIR; rm -rf basic-outer-loop-test-dir
