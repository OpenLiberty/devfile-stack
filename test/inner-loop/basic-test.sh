#!/bin/bash

# Base inner loop test using the application-stack-intro application.
echo -e "\n> Base Inner loop test setup"
mkdir inner-loop-test-dir
cd inner-loop-test-dir

echo -e "\n> Clone application-stack-intro project"
git clone https://github.com/OpenLiberty/application-stack-intro.git
cd application-stack-intro

echo -e "\n> Copy devfile"
cp ../../generated/devfile.yaml devfile.yaml

# this is a workaround to avoid surefire fork failures when running
# the GHA test suite.
# Issue #138 has been opened to track and address this
# add the -DforkCount arg to the odo test cmd only for this run
echo -e "\n> Modifying the odo test command"
sed -i 's/\B-Dmicroshed_hostname/-DforkCount=0 &/' devfile.yaml

echo -e "\n Updated devfile contents:"
cat devfile.yaml

echo -e "\n> Base Inner loop test run"
COMP_NAME=my-ol-component PROJ_NAME=inner-loop-test ./../../test/stack-inner-loop.sh
rc=$?
if [ $rc -ne 0 ]; then
    exit 12
fi

echo -e "\n> Cleanup: Delete created directories"
cd ../../; rm -rf inner-loop-test-dir