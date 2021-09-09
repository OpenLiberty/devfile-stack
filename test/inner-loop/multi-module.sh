#!/bin/bash

# Inner-loop multi-module OL maven plugin support test using the OL guide muti-module application.
echo -e "\n> multi-module inner loop test"

# Base work directory.
BASE_DIR=$(pwd)

# Build type sub-path to the wlp installation.
BUILD_WLP_SUB_PATH=target/liberty

mkdir multi-module-inner-loop-test-dir
cd multi-module-inner-loop-test-dir

echo -e "\n> Clone guide-maven-multimodules project"
git clone https://github.com/OpenLiberty/guide-maven-multimodules.git
cd guide-maven-multimodules/finish

echo -e "\n> Copy devfile"
cp $BASE_DIR/generated/devfiles/maven/devfile.yaml devfile.yaml

# Update the test command execution in the devfile:
# 1. Add -DforkCount=0 as a workaround to avoid surefire fork failures when running
#    the GHA test suite.Issue #138 has been opened to track and address this
# 2. Add the test-compile phase to run the testCompile goal (ear/pom.xml), which allows the tests to 
#    be compiled and used when run. This is done to avoid errors such as: 
#    Could not find metadata io.openliberty.guides:guide-maven-multimodules-jar:1.0-SNAPSHOT/maven-metadata.xml
#    in local (/mvn/repository) 
echo -e "\n> Modifying the odo test command"
sed -i 's/failsafe:integration-test/-DforkCount=0 test-compile failsafe:integration-test/' devfile.yaml

echo -e "\n Updated devfile contents:"
cat devfile.yaml

echo -e "\n> Base Inner loop test run"
COMP_NAME=multi-module-component \
PROJ_NAME=multi-module-test \
APP_NAME=guide-maven-multimodules-ear \
APP_RESOURCE_PATH=converter/ \
APP_VALIDATION_STRING="Enter the height in centimeters" \
DO_HEALTH_CHECK=false \
BASE_WORK_DIR=$BASE_DIR \
LIBERTY_SERVER_LOGS_DIR_PATH=/projects/ear/$BUILD_WLP_SUB_PATH/wlp/usr/servers/defaultServer/logs \
$BASE_DIR/test/inner-loop/base-inner-loop.sh

rc=$?
if [ $rc -ne 0 ]; then
    exit 12
fi

echo -e "\n> Cleanup: Delete created directories"
cd $BASE_DIR; rm -rf multi-module-inner-loop-test-dir
