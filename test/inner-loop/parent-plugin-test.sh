#!/bin/bash

# Inner loop test using the devfile-stack-intro application that defines a pom.xml containing the liberty-maven-app-parent artifact.
echo -e "\n> Parent plugin inner loop test."

# Base work directory.
BASE_DIR=$(pwd)

# WLP install path
WLP_INSTALL_PATH="${WLP_INSTALL_PATH:-/opt/ol/wlp}"

mkdir inner-loop-parent-plugin-test-dir
cd inner-loop-parent-plugin-test-dir

echo -e "\n> Clone devfile-stack-intro project"
git clone https://github.com/OpenLiberty/devfile-stack-intro.git
cd devfile-stack-intro

echo -e "\n> Add the liberty maven parent entry to pom.xml"
sed -i '/<\/modelVersion>/a\\n\ \ \ \ <parent>\n\ \ \ \ \ \ \ \ <groupId>io.openliberty.tools<\/groupId>\n\ \ \ \ \ \ \ \ <artifactId>liberty-maven-app-parent<\/artifactId>\n\ \ \ \ \ \ \ \ <version>3.3.4<\/version>\n\ \ \ \ <\/parent>\n' pom.xml

echo -e "\n> Updated pom.xml"
cat pom.xml

echo -e "\n> Copy devfile"
runtime="$1"
buldType="$2"
runtimeDir="open-liberty"
if [ "$runtime" = "wl" ]; then
    runtimeDir="websphere-liberty"
fi

cp $BASE_DIR/stack/"${runtimeDir}"/devfiles/maven/devfile.yaml devfile.yaml

# This is a workaround to avoid surefire fork failures when running the GHA test suite.
# Issue #138 has been opened to track and address this
# add the -DforkCount arg to the odo test cmd only for this run
echo -e "\n> Modifying the odo test command"
sed -i 's/failsafe:integration-test/-DforkCount=0 failsafe:integration-test/' devfile.yaml

echo -e "\n Updated devfile contents:"
cat devfile.yaml

echo -e "\n> Inner loop parent plugin test run."
BASE_WORK_DIR=$BASE_DIR \
COMP_NAME=parent-plugin-comp \
PROJ_NAME=parent-plugin-proj \
LIBERTY_SERVER_LOGS_DIR_PATH=$WLP_INSTALL_PATH/usr/servers/defaultServer/logs \
$BASE_DIR/test/inner-loop/base-inner-loop.sh

rc=$?
if [ $rc -ne 0 ]; then
    exit 12
fi

echo -e "\n> Cleanup: Delete created directories"
cd $BASE_DIR; rm -rf inner-loop-parent-plugin-test-dir