#!/bin/bash

# Base inner loop test using the devfile-stack-intro application and a build tooling specific container image to run the application.
echo -e "\n> Build tooling specific container image inner loop test"

# Base work directory.
BASE_DIR=$(pwd)

# WLP install path
WLP_INSTALL_PATH="${WLP_INSTALL_PATH:-/projects/target/liberty/wlp}"

mkdir inner-loop-test-dir
cd inner-loop-test-dir

echo -e "\n> Clone devfile-stack-samples project"
git clone https://github.com/OpenLiberty/devfile-stack-samples.git

echo -e "\n> Clone devfile-stack-intro project"
git clone https://github.com/OpenLiberty/devfile-stack-intro.git
cd devfile-stack-intro

echo -e "\n> Process build tool specific actions"
if [ "$1" = "gradle" ]; then
  cp $BASE_DIR/inner-loop-test-dir/devfile-stack-samples/devfiles/gradle-image/devfile.yaml devfile.yaml
  WLP_INSTALL_PATH=/projects/build/wlp
else
  cp $BASE_DIR/inner-loop-test-dir/devfile-stack-samples/devfiles/maven-image/devfile.yaml devfile.yaml
fi

# This is a workaround to avoid surefire fork failures when running
# the GHA test suite.
# Issue #138 has been opened to track and address this
# add the -DforkCount arg to the odo test cmd only for this run
echo -e "\n> Modifying the odo test command"
sed -i 's/failsafe:integration-test/-DforkCount=0 failsafe:integration-test/' devfile.yaml

echo -e "\n Updated devfile contents:"
cat devfile.yaml

echo -e "\n> Base Inner loop test run"
BASE_WORK_DIR=$BASE_DIR \
COMP_NAME=my-ol-component \
PROJ_NAME=inner-loop-test \
LIBERTY_SERVER_LOGS_DIR_PATH=$WLP_INSTALL_PATH/usr/servers/defaultServer/logs \
$BASE_DIR/test/inner-loop/base-inner-loop.sh

rc=$?
if [ $rc -ne 0 ]; then
    exit 12
fi

echo -e "\n> Cleanup: Delete created directories"
cd $BASE_DIR; rm -rf inner-loop-test-dir
