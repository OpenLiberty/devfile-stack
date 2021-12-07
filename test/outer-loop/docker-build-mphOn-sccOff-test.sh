#!/bin/bash

# Outer loop test using the devfile-stack-intro application.
# The application image is built using the following arguments: 
# ADD_MP_HEALTH=true and ENABLE_OPENJ9_SCC=false.
echo -e "\n> Docker build with MPH true SCC false args outer loop test"

# Base work directory.
BASE_DIR=$(pwd)

# Component name. 
MPHON_SCCOFF_COMP_NAME="dbuild-mphon-sccoff"

mkdir outer-loop-mphOn-sccOff-test-dir
cd outer-loop-mphOn-sccOff-test-dir

echo -e "\n> Clone devfile-stack-intro project"
git clone https://github.com/OpenLiberty/devfile-stack-intro.git
cd devfile-stack-intro

echo -e "\n> Copy Dockerfile"
runtime="$1"
buldType="$2"
runtimeDir="open-liberty"
if [ "$runtime" = "wl" ]; then
    runtimeDir="websphere-liberty"
fi

if [ "$buldType" = "gradle" ]; then
    cp $BASE_DIR/stack/"${runtimeDir}"/outer-loop/gradle/Dockerfile Dockerfile
else
    cp $BASE_DIR/stack/"${runtimeDir}"/outer-loop/maven/Dockerfile Dockerfile
fi

echo -e "\n> Copy app-deploy.yaml"
cp $BASE_DIR/stack/"${runtimeDir}"/outer-loop/app-deploy.yaml app-deploy.yaml

echo -e "\n> Build Docker image"
sed -i '/COPY --from=compile/a RUN true' Dockerfile
docker build --build-arg ADD_MP_HEALTH=true --build-arg ENABLE_OPENJ9_SCC=false -t outerloop/devfile-stack-intro:1.0 .

echo -e "\n> Replace variables in app-deploy.yaml"
sed -i 's/{{\.PORT}}/9080/g' app-deploy.yaml
sed -i "s/{{\.COMPONENT_NAME}}/${MPHON_SCCOFF_COMP_NAME}/g" app-deploy.yaml
sed -i 's/{{\.CONTAINER_IMAGE}}/outerloop\/devfile-stack-intro:1\.0/g' app-deploy.yaml

echo -e "\n> Base outer loop test run"
BASE_WORK_DIR=$BASE_DIR COMP_NAME=${MPHON_SCCOFF_COMP_NAME} $BASE_DIR/test/outer-loop/base-outer-loop.sh
rc=$?
if [ $rc -ne 0 ]; then
    exit 12
fi

echo -e "\n> Cleanup: Delete created directories"
cd $BASE_DIR; rm -rf outer-loop-mphOn-sccOff-test-dir
