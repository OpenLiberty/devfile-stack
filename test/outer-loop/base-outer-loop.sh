#!/bin/bash

# Component name. 
COMP_NAME="${COMP_NAME:-outer-loop}"

# Namespace/project name.
NAMESPACE="outer-loop"

# Liberty server config directory path.
LIBERTY_SERVER_LOGS_DIR_PATH='/logs'

# Base work directory.
BASE_WORK_DIR="${BASE_WORK_DIR:-/home/runner/work/application-stack/application-stack}"

# Current time.
currentTime=(date +"%Y/%m/%d-%H:%M:%S:%3N")

echo -e "\n> $(${currentTime[@]}): Create and switch namespaces using ODO"
odo project create ${NAMESPACE}

echo -e "\n> $(${currentTime[@]}): Display kube-system pods"
kubectl get pods -n kube-system 

echo -e "\n> $(${currentTime[@]}): Increase the OpenLibertyApplication resource's validation failure threshold and deploy it"
sed -i 's!failureThreshold: 12!failureThreshold: 20!' app-deploy.yaml
cat app-deploy.yaml
kubectl apply -f app-deploy.yaml -n ${NAMESPACE}

echo -e "\n> $(${currentTime[@]}): Wait for the OpenLibertyApplication resource pod to start"
count=1
while [[ $(kubectl get pods -n ${NAMESPACE} -l app.kubernetes.io/name=${COMP_NAME} -o 'jsonpath={..status.conditions[?(@.type=="Ready")].status}') != "True" ]]; do 
    echo "$(${currentTime[@]}): waiting for the OpenLibertyApplication resource pod to start" && sleep 3; 
    count=`expr $count + 1`
    if [ $count -eq 20 ]; then
        echo "$(${currentTime[@]}): Timed out waiting for the OpenLibertyApplication resource pod to start. Pod config:"
        $BASE_WORK_DIR/test/utils.sh printPodConfig "app.kubernetes.io/name=${COMP_NAME}" ${NAMESPACE}
        echo "$(${currentTime[@]}): OpenLibertyApplication resource pod log:"
        $BASE_WORK_DIR/test/utils.sh printPodLog "app.kubernetes.io/name=${COMP_NAME}" ${NAMESPACE}
        echo "$(${currentTime[@]}): Open Liberty Operator pod log:"
        $BASE_WORK_DIR/test/utils.sh printPodLog "name=open-liberty-operator" ${NAMESPACE}
    exit 12
fi
done

echo -e "\n> $(${currentTime[@]}): Wait for the intro application to become available"
count=1
olpodlog=($BASE_WORK_DIR/test/utils.sh printLibertyServerMsgLog "app.kubernetes.io/name=${COMP_NAME}" ${NAMESPACE} $LIBERTY_SERVER_LOGS_DIR_PATH)
while ! ${olpodlog[@]} | grep -q "CWWKZ0001I: Application intro started"; do 
    echo "$(${currentTime[@]}): Waiting for the intro application to become available... " && sleep 3
    count=`expr $count + 1`
    if [ $count -eq 40 ]; then
        echo "$(${currentTime[@]}): Timed out waiting for the intro application to become available"
        echo ${olpodlog[@]}
        $BASE_WORK_DIR/test/utils.sh printLibertyDebugData "app.kubernetes.io/name=${COMP_NAME}" ${NAMESPACE} $LIBERTY_SERVER_LOGS_DIR_PATH
        exit 12
    fi
done

echo -e "\n> $(${currentTime[@]}): Test liveness endpoint"
livenessResults=(curl http://${COMP_NAME}.$(minikube ip).nip.io/health/live)
count=1
while ! ${livenessResults[@]} | grep -qF '{"checks":[{"data":{},"name":"SampleLivenessCheck","status":"UP"}],"status":"UP"}'; do 
    echo "$(${currentTime[@]}): Waiting for the liveness check to pass... " && sleep 5; 
    count=`expr $count + 1`
    if [ $count -eq 20 ]; then
        # Last attempt to perform a liveness check using the health endpoint:
        healthEndpointResult=(curl http://${COMP_NAME}.$(minikube ip).nip.io/health)
        if ${healthEndpointResult[@]} | grep -qF '{"data":{},"name":"SampleLivenessCheck","status":"UP"}'; then
            break
        fi

        # Print debug data and exit.
        echo "$(${currentTime[@]}): Timed out waiting for the liveness check to pass."
        echo ${healthEndpointResult[@]}
        echo ${livenessResults[@]}
        echo "$(${currentTime[@]}): App service resource config:"
        kubectl describe service ${COMP_NAME} -n ${NAMESPACE}
        echo "$(${currentTime[@]}): App ingress resource config:"
        kubectl describe ingress ${COMP_NAME} -n ${NAMESPACE}
        echo "$(${currentTime[@]}): Nginx ingress controller config:"
        $BASE_WORK_DIR/test/utils.sh printPodConfig "app.kubernetes.io/name=ingress-nginx,app.kubernetes.io/component=controller" "kube-system"
        echo "$(${currentTime[@]}): Nginx ingress controller pod log:"
        $BASE_WORK_DIR/test/utils.sh printPodLog "app.kubernetes.io/name=ingress-nginx,app.kubernetes.io/component=controller" "kube-system"
        echo "$(${currentTime[@]}): Liberty debug data:"
        $BASE_WORK_DIR/test/utils.sh printLibertyDebugData "app.kubernetes.io/name=${COMP_NAME}" ${NAMESPACE} $LIBERTY_SERVER_LOGS_DIR_PATH
        exit 12
    fi
done

echo -e "\n> $(${currentTime[@]}): Test readiness endpoint"
readinessResults=(curl http://${COMP_NAME}.$(minikube ip).nip.io/health/ready)
count=1
while ! ${readinessResults[@]} | grep -qF '{"checks":[{"data":{},"name":"SampleReadinessCheck","status":"UP"}],"status":"UP"}'; do 
    echo "$(${currentTime[@]}): Waiting for the readiness check to pass... " && sleep 5; 
    count=`expr $count + 1`
    if [ $count -eq 20 ]; then
        # Last attempt to perform a readiness check using the health endpoint:
        healthEndpointResult=(curl http://${COMP_NAME}.$(minikube ip).nip.io/health)
        if ${healthEndpointResult[@]} | grep -qF '{"data":{},"name":"SampleReadinessCheck","status":"UP"}'; then
            break
        fi

        # Print debug data and exit.
        echo "$(${currentTime[@]}): Timed out waiting for the readiness check to pass."
        echo ${healthEndpointResult[@]}
        echo ${readinessResults[@]}
        $BASE_WORK_DIR/test/utils.sh printLibertyDebugData "app.kubernetes.io/name=${COMP_NAME}" ${NAMESPACE} $LIBERTY_SERVER_LOGS_DIR_PATH
        exit 12
    fi
done

echo -e "\n> $(${currentTime[@]}): Test REST endpoint"
restResults=(curl http://${COMP_NAME}.$(minikube ip).nip.io/api/resource)
if ${restResults[@]} | grep -qF 'Hello! Welcome to Open Liberty'; then
    echo "$(${currentTime[@]}): REST endpoint check passed!"
else
    echo "$(${currentTime[@]}): REST endpoint check failed. REST endpoint returned:"
    echo ${restResults[@]}
    $BASE_WORK_DIR/test/utils.sh printLibertyDebugData "app.kubernetes.io/name=${COMP_NAME}" ${NAMESPACE} $LIBERTY_SERVER_LOGS_DIR_PATH
    exit 12
fi

echo -e "\n> $(${currentTime[@]}): Check the Liberty server for error and warning messages"
./../../test/utils.sh checkLibertyServerLogForErrorAndWarnings "component=${COMP_NAME}" ${NAMESPACE} $LIBERTY_SERVER_LOGS_DIR_PATH
rc=$?
if [ $rc -ne 0 ]; then
     $BASE_WORK_DIR/test/utils.sh printLibertyDebugData "component=${COMP_NAME}" ${NAMESPACE} $LIBERTY_SERVER_LOGS_DIR_PATH
     exit 12
fi

echo -e "\n> $(${currentTime[@]}): Cleanup: Outer-loop deployment"
kubectl delete -f app-deploy.yaml -n ${NAMESPACE}
count=1
while [ ! -z $(kubectl get pod -n ${NAMESPACE} -l app.kubernetes.io/name=${COMP_NAME} -o jsonpath='{.items[*].metadata.name}') ]; do
    echo "$(${currentTime[@]}): Waiting for outer-loop deployment pod to be terminated..." && sleep 3; 
    count=`expr $count + 1`
    if [ $count -eq 20 ]; then
        echo "$(${currentTime[@]}): Timed out waiting for outer-loop deployment pod to be terminated"
        $BASE_WORK_DIR/test/utils.sh printLibertyDebugData "app.kubernetes.io/name=${COMP_NAME}" ${NAMESPACE} $LIBERTY_SERVER_LOGS_DIR_PATH
        exit 12
    fi
done