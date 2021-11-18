#!/bin/bash

# Inner loop test using the devfile-stack-intro application that requires/uses microprofile 3.3 APIs and OL features.
echo -e "\n> Microprofile 3.3 inner loop test."

# Base work directory.
BASE_DIR=$(pwd)

# WLP install path
WLP_INSTALL_PATH="${WLP_INSTALL_PATH:-/opt/ol/wlp}"

mkdir inner-loop-mp3-plugin-test-dir
cd inner-loop-mp3-plugin-test-dir

echo -e "\n> Clone devfile-stack-intro project and customize it."
git clone https://github.com/OpenLiberty/devfile-stack-intro.git
cd devfile-stack-intro

echo -e "\n> Replace the needed files."
if [ "$1" = "gradle" ]; then
  cp $BASE_DIR/generated/devfiles/gradle/devfile.yaml devfile.yaml
  WLP_INSTALL_PATH=/projects/build/wlp
  cp $BASE_DIR/test/files/intro-app/microprofile-v3/build.gradle build.gradle
  cat build.gradle
else
  cp $BASE_DIR/generated/devfiles/maven/devfile.yaml devfile.yaml
  cp $BASE_DIR/test/files/intro-app/microprofile-v3/pom.xml pom.xml
  cat pom.xml
fi

cp $BASE_DIR/test/files/intro-app/microprofile-v3/server.xml src/main/liberty/config/server.xml
cat src/main/liberty/config/server.xml
cp $BASE_DIR/test/files/intro-app/microprofile-v3/SampleLivenessCheck.java src/main/java/dev/odo/sample/SampleLivenessCheck.java
cat src/main/java/dev/odo/sample/SampleLivenessCheck.java
cp $BASE_DIR/test/files/intro-app/microprofile-v3/SampleReadinessCheck.java src/main/java/dev/odo/sample/SampleReadinessCheck.java
cat src/main/java/dev/odo/sample/SampleReadinessCheck.java

# Remove the startup check. It is only supported in MP health 3.1 part of MP 4.1.
rm -f src/main/java/dev/odo/sample/SampleStartupCheck.java

# Customize the devfile with a workaround to avoid surefire fork failures when running the GHA test suite.
# Issue #138 has been opened to track and address this add the -DforkCount arg to the odo test cmd only for this run
echo -e "\n> Copy stack devfile and customize it."
sed -i 's/failsafe:integration-test/-DforkCount=0 failsafe:integration-test/' devfile.yaml

echo -e "\n Updated devfile contents."
cat devfile.yaml

echo -e "\n> Inner loop parent plugin test run."
BASE_WORK_DIR=$BASE_DIR \
COMP_NAME=mp3-comp \
PROJ_NAME=mp3-proj \
LIBERTY_SERVER_LOGS_DIR_PATH=$WLP_INSTALL_PATH/usr/servers/defaultServer/logs \
$BASE_DIR/test/inner-loop/base-inner-loop.sh

rc=$?
if [ $rc -ne 0 ]; then
    exit 12
fi

echo -e "\n> Cleanup: Delete created directories."
cd $BASE_DIR; rm -rf inner-loop-mp3-plugin-test-dir