#!/bin/bash

# Inner loop test using the application-stack-intro application that defines a pom.xml containing the liberty-maven-app-parent artifact.
echo -e "\n> Parent plugin inner loop test."
mkdir inner-loop-parent-plugin-test-dir
cd inner-loop-parent-plugin-test-dir

echo -e "\n> Clone application-stack-intro project"
git clone https://github.com/OpenLiberty/application-stack-intro.git
cd application-stack-intro

echo -e "\n> Add the liberty maven parent entry to pom.xml"
sed -i '/<\/modelVersion>/a\\n\ \ \ \ <parent>\n\ \ \ \ \ \ \ \ <groupId>io.openliberty.tools<\/groupId>\n\ \ \ \ \ \ \ \ <artifactId>liberty-maven-app-parent<\/artifactId>\n\ \ \ \ \ \ \ \ <version>3.3.4<\/version>\n\ \ \ \ <\/parent>\n' pom.xml

echo -e "\n> Updated pom.xml"
cat pom.xml

echo -e "\n> Copy devfile"
cp ../../generated/devfile.yaml devfile.yaml

# this is a workaround to avoid surefire fork failures when running
# the GHA test suite.
# Issue #138 has been opened to track and address this
# add the -DforkCount arg to the odo test cmd only for this run
echo -e "\n> Modifying the odo test command"
sed -i 's/failsafe:integration-test/-DforkCount=0 failsafe:integration-test/' devfile.yaml

echo -e "\n Updated devfile contents:"
cat devfile.yaml

echo -e "\n> Inner loop parent plugin test run."
COMP_NAME=parent-plugin-comp PROJ_NAME=parent-plugin-proj ./../../test/inner-loop/base-inner-loop.sh
rc=$?
if [ $rc -ne 0 ]; then
    exit 12
fi

echo -e "\n> Cleanup: Delete created directories"
cd ../../; rm -rf inner-loop-parent-plugin-test-dir