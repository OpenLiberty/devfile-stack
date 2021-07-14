#!/bin/bash

# Inner loop test using the application-stack-intro application that requires/uses microprofile 3.3 APIs and OL features.
echo -e "\n> Microprofile 3.3 inner loop test."
mkdir inner-loop-mp3-plugin-test-dir
cd inner-loop-mp3-plugin-test-dir

echo -e "\n> Clone application-stack-intro project and customize it."
git clone https://github.com/OpenLiberty/application-stack-intro.git
cd application-stack-intro

echo -e "\n> Replace the needed files."
if [ $1 -eq "gradle" ]; then
  cp ../../generated/devfiles/gradle/devfile.yaml devfile.yaml
  cp ../../test/files/intro-app/microprofile-v3/build.gradle build.gradle
  cat build.gradle
else
  cp ../../generated/devfiles/maven/devfile.yaml devfile.yaml
  cp ../../test/files/intro-app/microprofile-v3/pom.xml pom.xml
  cat pom.xml
fi

cp ../../test/files/intro-app/microprofile-v3/server.xml src/main/liberty/config/server.xml
cat src/main/liberty/config/server.xml
cp ../../test/files/intro-app/microprofile-v3/SampleLivenessCheck.java src/main/java/dev/odo/sample/SampleLivenessCheck.java
cat src/main/java/dev/odo/sample/SampleLivenessCheck.java
cp ../../test/files/intro-app/microprofile-v3/SampleReadinessCheck.java src/main/java/dev/odo/sample/SampleReadinessCheck.java
cat src/main/java/dev/odo/sample/SampleReadinessCheck.java

# Customize the devfile with a workaround to avoid surefire fork failures when running the GHA test suite.
# Issue #138 has been opened to track and address this add the -DforkCount arg to the odo test cmd only for this run
echo -e "\n> Copy stack devfile and customize it."
sed -i 's/failsafe:integration-test/-DforkCount=0 failsafe:integration-test/' devfile.yaml

echo -e "\n Updated devfile contents."
cat devfile.yaml

echo -e "\n> Inner loop parent plugin test run."
COMP_NAME=mp3-comp PROJ_NAME=mp3-proj ./../../test/inner-loop/base-inner-loop.sh
rc=$?
if [ $rc -ne 0 ]; then
    exit 12
fi

echo -e "\n> Cleanup: Delete created directories."
cd ../../; rm -rf inner-loop-mp3-plugin-test-dir