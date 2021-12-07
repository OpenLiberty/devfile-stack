#!/bin/bash

# Inner-loop multi-module OL maven plugin support test using the OL guide muti-module application.
echo -e "\n> multi-module inner loop test"

# Variables.
RUNTIME="$1"
BUILD_TYPE="$2"
BASE_DIR=$(pwd)
RUNTIME_DIR="open-liberty"
WLP_INSTALL_PATH="/opt/ol/wlp"

mkdir multi-module-inner-loop-test-dir
cd multi-module-inner-loop-test-dir

echo -e "\n> Clone guide-maven-multimodules project"
git clone https://github.com/OpenLiberty/guide-maven-multimodules.git
cd guide-maven-multimodules/finish

echo -e "\n> Copy devfile"
if [ "$RUNTIME" = "wl" ]; then
  RUNTIME_DIR="websphere-liberty"
  WLP_INSTALL_PATH="/opt/ibm/wlp"
fi

cp "${BASE_DIR}"/stack/"${RUNTIME_DIR}"/devfiles/maven/devfile.yaml devfile.yaml

# Update the test command execution in the devfile. Add -DforkCount=0 as a workaround to avoid 
# surefire fork failures when running the GHA test suite.Issue #138 has been opened to track 
# and address this.
echo -e "\n> Modifying the odo test command"
sed -i 's/failsafe:integration-test/-DforkCount=0 failsafe:integration-test/' devfile.yaml

echo -e "\n Updated devfile contents:"
cat devfile.yaml

echo -e "\n> Base Inner loop test run"
COMP_NAME=multi-module-component \
PROJ_NAME=multi-module-test \
APP_NAME=guide-maven-multimodules-ear \
APP_RESOURCE_PATH=converter/ \
APP_VALIDATION_STRING="Enter the height in centimeters" \
DO_HEALTH_CHECK=false \
BASE_WORK_DIR="$BASE_DIR" \
LIBERTY_SERVER_LOGS_DIR_PATH="${WLP_INSTALL_PATH}"/usr/servers/defaultServer/logs \
"${BASE_DIR}"/test/inner-loop/base-inner-loop.sh

rc="$?"
if [ "$rc" -ne 0 ]; then
    exit 12
fi

echo -e "\n> Cleanup: Delete created directories"
cd "$BASE_DIR"; rm -rf multi-module-inner-loop-test-dir
