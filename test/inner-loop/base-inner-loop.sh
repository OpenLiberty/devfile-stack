#!/bin/bash

# Component name. 
COMP_NAME="${COMP_NAME:-default-component}"

# Namespace/project name.
PROJ_NAME="${PROJ_NAME:-default-test}"

# Application name.
APP_NAME="${APP_NAME:-intro}"

# Application resource path. Do not add a leading slash.
APP_RESOURCE_PATH="${APP_RESOURCE_PATH:-api/resource}"

# App deployment validation string.
APP_VALIDATION_STRING="${APP_VALIDATION_STRING:-Hello! Welcome to Open Liberty}"

# Health check validation switch.
DO_HEALTH_CHECK="${DO_HEALTH_CHECK:-true}"

# Liberty server config directory path.
LIBERTY_SERVER_LOGS_DIR_PATH="${LIBERTY_SERVER_LOGS_DIR_PATH:-/opt/ol/wlp/usr/servers/defaultServer/logs}"

# Base work directory.
BASE_WORK_DIR="${BASE_WORK_DIR:-/home/runner/work/application-stack/application-stack}"

# Current time.
currentTime=(date +"%Y/%m/%d-%H:%M:%S:%3N")

cleanup()
{
    echo -e "\n> $(${currentTime[@]}): Cleanup: Delete component"
    odo delete -a -f
    count=1  
    while [ ! -z $(kubectl get pod -l component=$COMP_NAME -o jsonpath='{.items[*].metadata.name}') ]; do
        if [ $count -eq 24 ]; then
            echo "$(${currentTime[@]}): Timed out waiting for component pod to be terminated"
            $BASE_WORK_DIR/test/utils.sh printLibertyDebugData "component=$COMP_NAME" $PROJ_NAME $LIBERTY_SERVER_LOGS_DIR_PATH
        fi
        count=`expr $count + 1`
        echo "$(${currentTime[@]}): Waiting for component pod to be terminated..." && sleep 5
    done

    echo -e "\n> $(${currentTime[@]}): Cleanup: Delete project"
    odo project delete $PROJ_NAME -f
    count=1
    while odo project list | grep -q $PROJ_NAME; do 
        if [ $count -eq 24 ]; then
            echo "$(${currentTime[@]}): Timed out waiting for project $PROJECT_NAME to be deleted. Namespace information:"
            kubectl get namespace $PROJECT_NAME -o yaml
        fi
        count=`expr $count + 1`
        echo "$(${currentTime[@]}): Waiting for project to be deleted..." && sleep 5
    done
}

# Base inner loop test using ODO.
echo -e "\n> $(${currentTime[@]}): Create new odo project"
odo project create $PROJ_NAME

echo -e "\n> $(${currentTime[@]}): Create new odo component"
odo create $COMP_NAME

echo -e "\n> $(${currentTime[@]}): Create URL with Minikube IP"
odo url create --host $(minikube ip).nip.io --ingress

echo -e "\n> $(${currentTime[@]}): ODO env:"
cat .odo/env/env.yaml

echo -e "\n> $(${currentTime[@]}): Checking on ingress readiness"
kubectl get pods -n kube-system 

echo -e "\n> $(${currentTime[@]}): Push to Minikube"
odo push
rc=$?
if [ $rc -ne 0 ]; then
    echo "\n> $(${currentTime[@]}): Retrying odo push" && sleep 5
    odo push -v 4 --show-log
    rc=$?
    if [ $rc -ne 0 ]; then 
      cleanup
      exit 12
    fi
fi

echo -e "\n> $(${currentTime[@]}): Wait for the $APP_NAME application to become available"
count=1
printMsgLog=($BASE_WORK_DIR/test/utils.sh printLibertyServerMsgLog "component=$COMP_NAME" $PROJ_NAME $LIBERTY_SERVER_LOGS_DIR_PATH)
while ! ${printMsgLog[@]} | grep -q "CWWKZ0001I: Application $APP_NAME started"; do 
    if [ $count -eq 24 ]; then
        echo "$(${currentTime[@]}): Timed out waiting for the $APP_NAME application to become available."
        $BASE_WORK_DIR/test/utils.sh printLibertyDebugData "component=$COMP_NAME" $PROJ_NAME $LIBERTY_SERVER_LOGS_DIR_PATH
        cleanup
        exit 12
    fi
    count=`expr $count + 1`
    echo "$(${currentTime[@]}): Waiting for the $APP_NAME application to become available... " && sleep 5
done

if [ $DO_HEALTH_CHECK = "true" ]; then
    echo -e "\n> $(${currentTime[@]}): Test liveness endpoint"
    callLivenessEndpoint=(curl http://ep1.$(minikube ip).nip.io/health/live)
    count=1
    while ! ${callLivenessEndpoint[@]} | grep -qF '{"checks":[{"data":{},"name":"SampleLivenessCheck","status":"UP"}],"status":"UP"}'; do 
        if [ $count -eq 24 ]; then
            # Last attempt to perform a liveness check using the health endpoint:
            callHealthEndpoint=(curl http://${COMP_NAME}.$(minikube ip).nip.io/health)
            if ${callHealthEndpoint[@]} | grep -qF '{"data":{},"name":"SampleLivenessCheck","status":"UP"}'; then
                break
            fi

            # Print debug data and exit.
            echo " $(${currentTime[@]}): Timed out waiting for the liveness check to pass. Liveness and health output:"
            ${callLivenessEndpoint[@]}
            ${callHealthEndpoint[@]}
            $BASE_WORK_DIR/test/utils.sh printLibertyDebugData "component=$COMP_NAME" $PROJ_NAME $LIBERTY_SERVER_LOGS_DIR_PATH
            cleanup
            exit 12
        fi
        count=`expr $count + 1`
        echo "$(${currentTime[@]}): Waiting for liveness check to pass... " && sleep 5
    done

    echo -e "\n> $(${currentTime[@]}): Test readiness endpoint"
    callReadinessEndpoint=(curl http://ep1.$(minikube ip).nip.io/health/ready)
    count=1
    while ! ${callReadinessEndpoint[@]} | grep -qF '{"checks":[{"data":{},"name":"SampleReadinessCheck","status":"UP"}],"status":"UP"}'; do 
        if [ $count -eq 24 ]; then
            # Last attempt to perform a readiness check using the health endpoint:
            callHealthEndpoint=(curl http://${COMP_NAME}.$(minikube ip).nip.io/health)
            if ${callHealthEndpoint[@]} | grep -qF '{"data":{},"name":"SampleReadinessCheck","status":"UP"}'; then
                break
            fi
            echo "$(${currentTime[@]}): Timed out waiting for the readiness check to pass. Readiness and health output:"
            ${callReadinessEndpoint[@]}
            ${callHealthEndpoint[@]}
            $BASE_WORK_DIR/test/utils.sh printLibertyDebugData "component=$COMP_NAME" $PROJ_NAME $LIBERTY_SERVER_LOGS_DIR_PATH
            cleanup
            exit 12
        fi
        count=`expr $count + 1`
        echo "$(${currentTime[@]}): Waiting for readiness check to pass... " && sleep 5
    done
fi

echo -e "\n> $(${currentTime[@]}): Test the application's REST endpoint"
callAppEndpoint=(curl http://ep1.$(minikube ip).nip.io/$APP_RESOURCE_PATH)
count=1
while ! ${callAppEndpoint[@]} | grep -qF "$APP_VALIDATION_STRING"; do
    if [ $count -eq 12 ]; then
        echo "$(${currentTime[@]}): Timed out waiting for the $APP_NAME application REST endpoint to return the expected response."
        ${callAppEndpoint[@]}
        $BASE_WORK_DIR/test/utils.sh printLibertyDebugData "component=$COMP_NAME" $PROJ_NAME $LIBERTY_SERVER_LOGS_DIR_PATH
        cleanup
        exit 12
    fi
    count=`expr $count + 1`
    echo "$(${currentTime[@]}): Waiting for the $APP_NAME application REST endpoint to return the expected response ..." && sleep 5
done

echo -e "\n> Run odo test"
odo test
rc=$?
if [ $rc -ne 0 ]; then
    echo "\n> $(${currentTime[@]}): Retrying odo test" && sleep 5
    odo test -v 4 --show-log
    rc=$?
    if [ $rc -ne 0 ]; then
        echo "$(${currentTime[@]}): Odo test run failed:"
        $BASE_WORK_DIR/test/utils.sh printLibertyDebugData "component=$COMP_NAME" $PROJ_NAME $LIBERTY_SERVER_LOGS_DIR_PATH
        cleanup
        exit 12
    fi
fi

cleanup