#!/bin/bash

# Outer loop test using the application-stack-intro application.
# The application image is built using the following arguments: 
#ADD_MP_HEALTH=false and ENABLE_OPENJ9_SCC=true.
echo -e "\n> Docker build with MPH false SCC true args outer loop test"

# Component name. 
MPHOFF_SCCON_COMP_NAME="dbuild-mphoff-sccon"

mkdir outer-loop-mphOff-sccOn-test-dir
cd outer-loop-mphOff-sccOn-test-dir

echo -e "\n> Clone application-stack-intro project"
git clone https://github.com/OpenLiberty/application-stack-intro.git
cd application-stack-intro

echo -e "\n> Copy Dockerfile"
cp ../../generated/Dockerfile Dockerfile

echo -e "\n> Copy app-deploy.yaml"
cp ../../templates/outer-loop/app-deploy.yaml app-deploy.yaml

echo -e "\n> Build Docker image"
sed -i '/COPY --from=compile/a RUN true' Dockerfile
docker build --build-arg ADD_MP_HEALTH=false --build-arg ENABLE_OPENJ9_SCC=true -t outerloop/application-stack-intro:1.0 .

echo -e "\n> Replace variables in app-deploy.yaml"
sed -i 's/{{\.PORT}}/9080/g' app-deploy.yaml
sed -i "s/{{\.COMPONENT_NAME}}/${MPHOFF_SCCON_COMP_NAME}/g" app-deploy.yaml
sed -i 's/{{\.CONTAINER_IMAGE}}/outerloop\/application-stack-intro:1\.0/g' app-deploy.yaml

echo -e "\n> Base outer loop test run"
COMP_NAME=${MPHOFF_SCCON_COMP_NAME}  ./../../test/outer-loop/base-outer-loop.sh
rc=$?
if [ $rc -ne 0 ]; then
    exit 12
fi

echo -e "\n> Cleanup: Delete created directories"
cd ../../; rm -rf outer-loop-mphOff-sccOn-test-dir
