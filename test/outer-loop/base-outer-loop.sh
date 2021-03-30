#!/bin/bash

OUTER_LOOP_TEST_NAMESPACE='outer-loop-test'
LIBERTY_SERVER_LOGS_DIR_PATH='/logs'
COMP_NAME='my-ol-deployment'
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
sed -i '/COPY --from=compile/a RUN true' Dockerfile
docker build -t outerloop/application-stack-intro:1.0 .

echo -e "\n> Replace variables in app-deploy.yaml"
sed -i 's/{{\.PORT}}/9080/g' app-deploy.yaml
sed -i "s/{{\.COMPONENT_NAME}}/$COMP_NAME/g" app-deploy.yaml
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
while [[ $(kubectl get pods -l app.kubernetes.io/name=$COMP_NAME -o 'jsonpath={..status.conditions[?(@.type=="Ready")].status}') != "True" && $count -lt 20 ]]; do 
    kubectl get pods
    echo "waiting for pod" && sleep 3; 
    count=`expr $count + 1`
done
if [ $count -eq 20 ]; then
    echo "Timed out waiting for pod to start"
    kubectl describe pods -l app.kubernetes.io/name=$COMP_NAME
    exit 12
fi

echo -e "\n> Test liveness endpoint"
livenessResults=$(curl http://my-ol-deployment.$(minikube ip).nip.io/health/live)
count=1
while ! echo $livenessResults | grep -qF '{"checks":[{"data":{},"name":"SampleLivenessCheck","status":"UP"}],"status":"UP"}'; do 
    echo "Waiting for liveness check to pass... " && sleep 3; 
    count=`expr $count + 1`
    if [ $count -eq 20 ]; then
        echo "Timed out waiting for liveness check to pass. Liveness results:"
        echo $livenessResults
        ./../../test/utils.sh printDebugData "app.kubernetes.io/name=$COMP_NAME" $OUTER_LOOP_TEST_NAMESPACE $LIBERTY_SERVER_LOGS_DIR_PATH
        exit 12
    fi
done

echo -e "\n> Test readiness endpoint"
readinessResults=$(curl http://my-ol-deployment.$(minikube ip).nip.io/health/ready)
count=1
while ! echo $readinessResults | grep -qF '{"checks":[{"data":{},"name":"SampleReadinessCheck","status":"UP"}],"status":"UP"}'; do 
    echo "Waiting for readiness check to pass... " && sleep 3; 
    count=`expr $count + 1`
    if [ $count -eq 20 ]; then
        echo "Timed out waiting for Readiness check to pass. Readiness results:"
        echo $readinessResults
        ./../../test/utils.sh printDebugData "app.kubernetes.io/name=$COMP_NAME" $OUTER_LOOP_TEST_NAMESPACE $LIBERTY_SERVER_LOGS_DIR_PATH
        exit 12
    fi
done

echo -e "\n> Test REST endpoint"
restResults=$(curl http://my-ol-deployment.$(minikube ip).nip.io/health/live)
if ! echo $restResults | grep -qF 'Hello! Welcome to Open Liberty'; then
    echo "REST endpoint check passed!"
else
    echo "REST endpoint check failed. REST endpoint returned:"
    echo $restResults
    ./../../test/utils.sh printDebugData "app.kubernetes.io/name=$COMP_NAME" $OUTER_LOOP_TEST_NAMESPACE $LIBERTY_SERVER_LOGS_DIR_PATH
    exit 12
fi

echo -e "\n> Cleanup: Outer-loop deployment"
kubectl delete -f app-deploy.yaml
count=1
while [ ! -z $(kubectl get pod -l app.kubernetes.io/name=my-ol-deployment -o jsonpath='{.items[*].metadata.name}') ]; do
    echo "Waiting for outer-loop deployment pod to be terminated..." && sleep 3; 
    count=`expr $count + 1`
    if [ $count -eq 20 ]; then
        echo "Timed out waiting for outer-loop deployment pod to be terminated"
        ./../../test/utils.sh printDebugData "app.kubernetes.io/name=$COMP_NAME" $OUTER_LOOP_TEST_NAMESPACE $LIBERTY_SERVER_LOGS_DIR_PATH
        exit 12
    fi
done

echo -e "\n> Cleanup: Open Liberty Operator instance"
curl -L https://raw.githubusercontent.com/OpenLiberty/open-liberty-operator/master/deploy/releases/0.7.0/openliberty-app-operator.yaml \
      | sed -e "s/OPEN_LIBERTY_WATCH_NAMESPACE/${OUTER_LOOP_TEST_NAMESPACE}/" \
      | kubectl delete -n ${OUTER_LOOP_TEST_NAMESPACE} -f -
count=1
while [ ! -z $(kubectl get pod -l name=open-liberty-operator -o jsonpath='{.items[*].metadata.name}') ]; do
    echo "Waiting for OL operator pod to be terminated..." && sleep 3; 
    count=`expr $count + 1`
    if [ $count -eq 20 ]; then
        echo "Timed out waiting for OL operator pod to be terminated"
        ./../../test/utils.sh printPodConfig "name=open-liberty-operator" $OUTER_LOOP_TEST_NAMESPACE
        ./../../test/utils.sh printPodLog "name=open-liberty-operator" $OUTER_LOOP_TEST_NAMESPACE
        exit 12
    fi
done

echo -e "\n> Cleanup: Open Liberty Operator custom resources"
kubectl delete -f https://raw.githubusercontent.com/OpenLiberty/open-liberty-operator/master/deploy/releases/0.7.0/openliberty-app-crd.yaml
count=1
while  kubectl get crd openlibertyapplications.openliberty.io --ignore-not-found | grep -q openlibertyapplications.openliberty.io; do
    echo "Waiting for OL operator CRD to be deleted..." && sleep 3; 
    count=`expr $count + 1`
    if [ $count -eq 20 ]; then
        echo "Timed out waiting for OL operator CRD to be deleted"
        oc get crd openlibertyapplications.openliberty.io -o yaml
        exit 12
    fi
done

echo -e "\n> Cleanup: Delete project"
odo project delete ${OUTER_LOOP_TEST_NAMESPACE} -f
count=1
while odo project list | grep -q ${OUTER_LOOP_TEST_NAMESPACE}; do 
    echo "Waiting for project to be deleted..." && sleep 3; 
    count=`expr $count + 1`
    if [ $count -eq 20 ]; then
        echo "Timed out waiting for project ${OUTER_LOOP_TEST_NAMESPACE} to be deleted. Namespace information: "
        kubectl get namespace ${OUTER_LOOP_TEST_NAMESPACE} -o yaml
        exit 12
    fi
done

echo -e "\n> Cleanup: Delete created directories"
cd ../../; rm -rf outer-loop-test-dir