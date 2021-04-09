#!/bin/bash

# Inner loop test using the application-stack-intro application that requires/uses microprofile 3.3 APIs and OL features.
echo -e "\n> Microprofile 3.3 inner loop test."
mkdir inner-loop-mp3-plugin-test-dir
cd inner-loop-mp3-plugin-test-dir

echo -e "\n> Clone application-stack-intro project and customize it."
git clone https://github.com/OpenLiberty/application-stack-intro.git
cd application-stack-intro
cp ../../test/files/intro-app/microprofile-v3/pom.xml pom.xml
cp ../../test/files/intro-app/microprofile-v3/server.xml src/main/liberty/config/server.xml

echo -e "\n Updated pom.xml and server.xml contents."
cat pom.xml
cat src/main/liberty/config/server.xml

# Copy the stack devfile and customize it with a workaround to avoid surefire fork failures when running the GHA test suite.
# Issue #138 has been opened to track and address this add the -DforkCount arg to the odo test cmd only for this run
echo -e "\n> Copy stack devfile and customize it."
cp ../../generated/devfile.yaml devfile.yaml
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