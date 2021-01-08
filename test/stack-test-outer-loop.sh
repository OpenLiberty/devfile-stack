#!/bin/bash

OUTER_LOOP_TEST_NAMESPACE='outer-loop-test'

mkdir outer-loop-test-dir
cd outer-loop-test-dir

echo -e "\n> Clone application-stack-intro project"
git clone https://github.com/OpenLiberty/application-stack-intro.git
cd application-stack-intro

echo -e "\n> Copy Dockerfile"
cp ../../generated/Dockerfile Dockerfile

echo -e "\n> Copy app-deploy.yaml"
cp ../../templates/outer-loop/app-deploy.yaml app-deploy.yaml

echo -e "\n> Create new odo project"
odo project create ${OUTER_LOOP_TEST_NAMESPACE}

### This is only needed if the Minikube driver is "docker". As of now, we are using diver=none or "bare metal"
### which allows Minikube to use the local docker registry
#echo -e "\n Use the Minikube image registry"
#eval $(minikube docker-env)

echo -e "\n> Build Docker image"
docker build -t outerloop/application-stack-intro:1.0 .

echo -e "\n> Replace variables in app-deploy.yaml"
sed -i 's/{{\.PORT}}/9080/g' app-deploy.yaml
sed -i 's/{{\.COMPONENT_NAME}}/my-ol-deployment/g' app-deploy.yaml
sed -i 's/{{\.CONTAINER_IMAGE}}/outerloop\/application-stack-intro:1\.0/g' app-deploy.yaml

echo -e "\n> Install Open Liberty Operator"
kubectl apply -f https://raw.githubusercontent.com/OpenLiberty/open-liberty-operator/master/deploy/releases/0.7.0/openliberty-app-crd.yaml
curl -L https://raw.githubusercontent.com/OpenLiberty/open-liberty-operator/master/deploy/releases/0.7.0/openliberty-app-operator.yaml \
      | sed -e "s/OPEN_LIBERTY_WATCH_NAMESPACE/${OUTER_LOOP_TEST_NAMESPACE}/" \
      | kubectl apply -n ${OUTER_LOOP_TEST_NAMESPACE} -f -
      
echo -e "\n> Wait for operator pod to start"
count=1
while [[ $(kubectl get pods -l name=open-liberty-operator -o 'jsonpath={..status.conditions[?(@.type=="Ready")].status}') != "True" && $count -lt 20 ]]; do 
    kubectl get pods
    echo "waiting for operator pod" && sleep 3; 
    count=`expr $count + 1`
done
if [ $count -eq 20 ]; then
    echo "Timed out waiting for operator pod to start"
    kubectl describe pods -l name=open-liberty-operator
    exit 12
fi

echo -e "\n> Deploy image"
cat app-deploy.yaml
kubectl apply -f app-deploy.yaml

echo -e "\n> Wait for pod to start"
count=1
while [[ $(kubectl get pods -l app.kubernetes.io/name=my-ol-deployment -o 'jsonpath={..status.conditions[?(@.type=="Ready")].status}') != "True" && $count -lt 20 ]]; do 
    kubectl get pods
    echo "waiting for pod" && sleep 3; 
    count=`expr $count + 1`
done
if [ $count -eq 20 ]; then
    echo "Timed out waiting for pod to start"
    kubectl describe pods -l app.kubernetes.io/name=my-ol-deployment
    exit 12
fi

echo -e "\n> Test liveness endpoint"
livenessResults=$(curl http://my-ol-deployment.$(minikube ip).nip.io/health/live)
if echo $livenessResults | grep -qF '{"checks":[{"data":{},"name":"SampleLivenessCheck","status":"UP"}],"status":"UP"}'; then
    
    echo "Liveness check passed!"
else
    echo "Liveness check failed. Liveness endpoint returned: " 
    echo $livenessResults
    exit 12
fi

echo -e "\n> Test readiness endpoint"
readinessResults=$(curl http://my-ol-deployment.$(minikube ip).nip.io/health/ready)
if echo $readinessResults | grep -qF '{"checks":[{"data":{},"name":"SampleReadinessCheck","status":"UP"}],"status":"UP"}'; then
    
    echo "Readiness check passed!"
else
    echo "Readiness check failed! Readiness endpoint returned: " 
    echo $readinessResults
    exit 12
fi

echo -e "\n> Test REST endpoint"
restResults=$(curl http://my-ol-deployment.$(minikube ip).nip.io/health/live)
if ! echo $restResults | grep -qF 'Hello! Welcome to Open Liberty'; then
    
    echo "REST endpoint check passed!"
else
    echo "REST endpoint check failed. REST endpoint returned: " 
    echo $restResults
    exit 12
fi
