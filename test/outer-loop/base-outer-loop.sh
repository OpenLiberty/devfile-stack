#!/bin/bash

# Component name. 
COMP_NAME="${COMP_NAME:-outer-loop}"

# Namespace/project name.
NAMESPACE="outer-loop"

# Liberty server config directory path.
LIBERTY_SERVER_LOGS_DIR_PATH='/logs'

echo -e "\n> Create and switch namespaces using ODO"
odo project create ${NAMESPACE}

echo -e "\n> Display kube-system pods"
kubectl get pods -n kube-system 

echo -e "\n> Increase the OpenLibertyApplication resource's validation failure threshold and deploy it"
sed -i 's!failureThreshold: 12!failureThreshold: 20!' app-deploy.yaml
cat app-deploy.yaml
kubectl apply -f app-deploy.yaml -n ${NAMESPACE}

echo -e "\n> Wait for the OpenLibertyApplication resource pod to start"
count=1
while [[ $(kubectl get pods -n ${NAMESPACE} -l app.kubernetes.io/name=${COMP_NAME} -o 'jsonpath={..status.conditions[?(@.type=="Ready")].status}') != "True" ]]; do 
    echo "waiting for the OpenLibertyApplication resource pod to start" && sleep 3; 
    count=`expr $count + 1`
    if [ $count -eq 20 ]; then
        echo "Timed out waiting for the OpenLibertyApplication resource pod to start. Pod config:"
        ./../../test/utils.sh printPodConfig "app.kubernetes.io/name=${COMP_NAME}" ${NAMESPACE}
        echo "OpenLibertyApplication resource pod log:"
        ./../../test/utils.sh printPodLog "app.kubernetes.io/name=${COMP_NAME}" ${NAMESPACE}
        echo "Open Liberty Operator pod log:"
        ./../../test/utils.sh printPodLog "name=open-liberty-operator" ${NAMESPACE}
    exit 12
fi
done

echo -e "\n> Wait for the intro application to become available"
count=1
olpodlog=$(./../../test/utils.sh printLibertyServerMsgLog "app.kubernetes.io/name=${COMP_NAME}" ${NAMESPACE} $LIBERTY_SERVER_LOGS_DIR_PATH)
while ! echo $olpodlog | grep -q "CWWKZ0001I: Application intro started"; do 
    echo "Waiting for the intro application to become available... " && sleep 3
    count=`expr $count + 1`
    if [ $count -eq 40 ]; then
        echo "Timed out waiting for the intro application to become available"
        echo $olpodlog
        ./../../test/utils.sh printLibertyDebugData "app.kubernetes.io/name=${COMP_NAME}" ${NAMESPACE} $LIBERTY_SERVER_LOGS_DIR_PATH
        exit 12
    fi
done

echo -e "\n> Test liveness endpoint"
livenessResults=$(curl http://${COMP_NAME}.$(minikube ip).nip.io/health/live)
count=1
while ! echo $livenessResults | grep -qF '{"checks":[{"data":{},"name":"SampleLivenessCheck","status":"UP"}],"status":"UP"}'; do 
    echo "Waiting for liveness check to pass... " && sleep 5; 
    count=`expr $count + 1`
    if [ $count -eq 20 ]; then
        echo "Timed out waiting for liveness check to pass. Liveness results:"
        echo $livenessResults
        echo "App service resource config:"
        kubectl describe service ${COMP_NAME} -n ${NAMESPACE}
        echo "App ingress resource config:"
        kubectl describe ingress ${COMP_NAME} -n ${NAMESPACE}
        echo "Nginx ingress controller config:"
        ./../../test/utils.sh printPodConfig "app.kubernetes.io/name=ingress-nginx,app.kubernetes.io/component=controller" "kube-system"
        echo "Nginx ingress controller pod log:"
        ./../../test/utils.sh printPodLog "app.kubernetes.io/name=ingress-nginx,app.kubernetes.io/component=controller" "kube-system"
        echo "Liberty debug data:"
        ./../../test/utils.sh printLibertyDebugData "app.kubernetes.io/name=${COMP_NAME}" ${NAMESPACE} $LIBERTY_SERVER_LOGS_DIR_PATH
        exit 12
    fi
done

echo -e "\n> Test readiness endpoint"
readinessResults=$(curl http://${COMP_NAME}.$(minikube ip).nip.io/health/ready)
count=1
while ! echo $readinessResults | grep -qF '{"checks":[{"data":{},"name":"SampleReadinessCheck","status":"UP"}],"status":"UP"}'; do 
    echo "Waiting for readiness check to pass... " && sleep 5; 
    count=`expr $count + 1`
    if [ $count -eq 20 ]; then
        echo "Timed out waiting for Readiness check to pass. Readiness results:"
        echo $readinessResults
        ./../../test/utils.sh printLibertyDebugData "app.kubernetes.io/name=${COMP_NAME}" ${NAMESPACE} $LIBERTY_SERVER_LOGS_DIR_PATH
        exit 12
    fi
done

echo -e "\n> Test REST endpoint"
restResults=$(curl http://${COMP_NAME}.$(minikube ip).nip.io/api/resource)
if echo $restResults | grep -qF 'Hello! Welcome to Open Liberty'; then
    echo "REST endpoint check passed!"
else
    echo "REST endpoint check failed. REST endpoint returned:"
    echo $restResults
    ./../../test/utils.sh printLibertyDebugData "app.kubernetes.io/name=${COMP_NAME}" ${NAMESPACE} $LIBERTY_SERVER_LOGS_DIR_PATH
    exit 12
fi

echo -e "\n> Check the Liberty server for error and warning messages"
./../../test/utils.sh checkLibertyServerLogForErrorAndWarnings "component=${COMP_NAME}" ${NAMESPACE} $LIBERTY_SERVER_LOGS_DIR_PATH
rc=$?
if [ $rc -ne 0 ]; then
     ./../../test/utils.sh printLibertyDebugData "component=${COMP_NAME}" ${NAMESPACE} $LIBERTY_SERVER_LOGS_DIR_PATH
     exit 12
fi

echo -e "\n> Cleanup: Outer-loop deployment"
kubectl delete -f app-deploy.yaml -n ${NAMESPACE}
count=1
while [ ! -z $(kubectl get pod -n ${NAMESPACE} -l app.kubernetes.io/name=${COMP_NAME} -o jsonpath='{.items[*].metadata.name}') ]; do
    echo "Waiting for outer-loop deployment pod to be terminated..." && sleep 3; 
    count=`expr $count + 1`
    if [ $count -eq 20 ]; then
        echo "Timed out waiting for outer-loop deployment pod to be terminated"
        ./../../test/utils.sh printLibertyDebugData "app.kubernetes.io/name=${COMP_NAME}" ${NAMESPACE} $LIBERTY_SERVER_LOGS_DIR_PATH
        exit 12
    fi
done