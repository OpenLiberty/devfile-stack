#!/bin/bash

# Basic inner loop test using the devfile-stack-intro application.
echo -e "\n> Basic inner loop test"

# Variables.
RUNTIME="$1"
BUILD_TYPE="$2"
BASE_DIR=$(pwd)
RUNTIME_DIR="open-liberty"
WLP_INSTALL_PATH="/opt/ol/wlp"

mkdir inner-loop-test-dir
cd inner-loop-test-dir

echo -e "\n> Clone devfile-stack-intro project"
git clone https://github.com/OpenLiberty/devfile-stack-intro.git
cd devfile-stack-intro
mvn -N io.takari:maven:0.7.7:wrapper

echo -e "\n> Process build tool specific actions"
if [ "$RUNTIME" = "wl" ]; then
  RUNTIME_DIR="websphere-liberty"
  WLP_INSTALL_PATH="/opt/ibm/wlp"
fi

if [ "$BUILD_TYPE" = "gradle" ]; then
    cp "${BASE_DIR}"/stack/"${RUNTIME_DIR}"/devfiles/gradle/devfile.yaml devfile.yaml
    WLP_INSTALL_PATH=/projects/build/wlp
else
    cp "${BASE_DIR}"/stack/"${RUNTIME_DIR}"/devfiles/maven/devfile.yaml devfile.yaml
    sed -i 's/mvn/\.\/mvnw/' devfile.yaml
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
BASE_WORK_DIR="$BASE_DIR" \
COMP_NAME=my-ol-component \
PROJ_NAME=inner-loop-test \
LIBERTY_SERVER_LOGS_DIR_PATH="${WLP_INSTALL_PATH}"/usr/servers/defaultServer/logs \
"${BASE_DIR}"/test/inner-loop/base-inner-loop.sh

rc="$?"
if [ "$rc" -ne 0 ]; then
    exit 12
fi

echo -e "\n> Cleanup: Delete created directories"
cd "$BASE_DIR"; rm -rf inner-loop-test-dir
