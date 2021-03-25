#!/bin/bash

mkdir inner-loop-test-dir
cd inner-loop-test-dir

echo -e "\n> Clone application-stack-intro project"
git clone https://github.com/OpenLiberty/application-stack-intro.git
cd application-stack-intro

echo -e "\n> Copy devfile and scripts"
cp ../../generated/devfile.yaml devfile.yaml

# this is a workaround to avoid surefire fork failures when running
# the GHA test suite.
# Issue #138 has been opened to track and address this
# add the -DforkCount arg to the odo test cmd only for this run
echo -e "\n> Modifying the odo test command"
sed -i 's/\B-Dmicroshed_hostname/-DforkCount=0 &/' devfile.yaml

echo -e "\n Updated devfile contents:"
cat devfile.yaml

echo -e "\n> Create new odo project"
odo project create inner-loop-test

echo -e "\n> Create new odo component"
odo create my-ol-component

echo -e "\n> Create URL with Minikube IP"
odo url create --host $(minikube ip).nip.io

echo -e "\n> Checking on ingress readiness"
kubectl get pods -n kube-system 

echo -e "\n> Push to Minikube"
odo push

echo -e "\n> Check for server start"
count=1
while ! odo log | grep -q "CWWKF0011I: The defaultServer server"; do 
    echo "waiting for server start... " && sleep 3; 
    count=`expr $count + 1`
    if [ $count -eq 20 ]; then
        echo "Timed out waiting for server to start"
        exit 12
    fi
done

echo -e "\n> Test liveness endpoint"
livenessResults=$(curl http://my-ol-component-9080.$(minikube ip).nip.io/health/live)
if echo $livenessResults | grep -qF '{"checks":[{"data":{},"name":"SampleLivenessCheck","status":"UP"}],"status":"UP"}'; then
    
    echo "Liveness check passed!"
else
    echo "Liveness check failed. Liveness endpoint returned: " 
    echo $livenessResults
    exit 12
fi

echo -e "\n> Test readiness endpoint"
readinessResults=$(curl http://my-ol-component-9080.$(minikube ip).nip.io/health/ready)
if echo $readinessResults | grep -qF '{"checks":[{"data":{},"name":"SampleReadinessCheck","status":"UP"}],"status":"UP"}'; then
    
    echo "Readiness check passed!"
else
    echo "Readiness check failed! Readiness endpoint returned: " 
    echo $readinessResults
    exit 12
fi

echo -e "\n> Test REST endpoint"
restResults=$(curl http://my-ol-component-9080.$(minikube ip).nip.io/health/live)
if ! echo $restResults | grep -qF 'Hello! Welcome to Open Liberty'; then
    
    echo "REST endpoint check passed!"
else
    echo "REST endpoint check failed. REST endpoint returned: " 
    echo $restResults
    exit 12
fi

echo -e "\n> Run odo test"
odo test -v 4 --show-log
rc=$?
if [ $rc -ne 0 ]; then
    echo "--------------------------------"
    odo log
    echo "--------------------------------"
    echo "odo test completed with failures"
    exit 12
fi

