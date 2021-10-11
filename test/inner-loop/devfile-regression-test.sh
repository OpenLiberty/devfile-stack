#!/bin/bash

# Devfile regression inner loop test using the application-stack-intro application.
echo -e "\n> Make stacktest regression dir"

# Base work directory.
BASE_DIR=$(pwd)

# WLP install path
WLP_INSTALL_PATH="${WLP_INSTALL_PATH:-/opt/ol/wlp}"

mkdir stacktest-reg
cd stacktest-reg

# Get the currently released version of the devfile template and generate
# this will allow us to run the current devfile with the new stack image
# introduced via this current PR being tested
echo -e "\n> Clone the main branch stack repo"
git clone https://github.com/OpenLiberty/application-stack.git

echo -e "\n> Run buildStack from the main branch in stack repo that was just cloned"
cd application-stack
./test/utils.sh buildStack

echo -e "\n> Make a test app dir for test project"
mkdir devfile-regression-inner-loop-test-dir
cd devfile-regression-inner-loop-test-dir

echo -e "\n> Clone application-stack-intro project"
git clone https://github.com/OpenLiberty/application-stack-intro.git
cd application-stack-intro

# This is a copy of the 'main' version of the devfile - vs an updated devfile from this PR.
# vis-a-vie the fact that we git cloned the main branch of the stack repo above
echo -e "\n> Copy devfile and scripts"
if [ "$1" = "gradle" ]; then
  cp $BASE_DIR/stacktest-reg/application-stack/generated/devfiles/gradle/devfile.yaml devfile.yaml
  WLP_INSTALL_PATH=/projects/build/wlp
else
  cp $BASE_DIR/stacktest-reg/application-stack/generated/devfiles/maven/devfile.yaml devfile.yaml
fi

# This is a workaround to avoid surefire fork failures when running
# the GHA test suite.
# Issue #138 has been opened to track and address this
# add the -DforkCount arg to the odo test cmd only for this run
echo -e "\n> Modifying the odo test command"
sed -i 's/failsafe:integration-test/-DforkCount=0 failsafe:integration-test/' devfile.yaml

echo -e "\n Updated devfile contents:"
cat devfile.yaml

# Call common script here
# the only accomodation we have to make is that
# we are one dir level deeper from the GHA test dir
echo -e "\n> Base Inner loop test run"
BASE_WORK_DIR=$BASE_DIR \
COMP_NAME=my-ol-component \
PROJ_NAME=devfile-regression-inner-loop-test \
LIBERTY_SERVER_LOGS_DIR_PATH=$WLP_INSTALL_PATH/usr/servers/defaultServer/logs \
$BASE_DIR/test/inner-loop/base-inner-loop.sh

rc=$?
if [ $rc -ne 0 ]; then
    exit 12
fi

echo -e "\n> Cleanup: Delete created directories"
echo $PWD; cd $BASE_DIR; echo $PWD; ls -l; rm -rf stacktest-reg; echo $PWD; ls -l; 
