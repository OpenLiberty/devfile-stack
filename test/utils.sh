#!/bin/bash

# buildStackImage builds stack images for the specified runtime.
buildStackImage() {
    local runtime="$1"
    local dockerfileRootPath="stack/open-liberty"

    if [ "$runtime" = "wl" ]; then
        dockerfileRootPath="stack/websphere-liberty"
    fi

    echo "> Start the docker registry";
    docker run --rm -it --network=host alpine ash -c "apk add socat && socat TCP-LISTEN:5000,reuseaddr,fork TCP:$(minikube ip):5000"

    echo "> Build/Push the Maven stack image";
    docker build -t localhost:5000/test-image-gradle --build-arg stacklabel=$SHA -f "${dockerfileRootPath}"/image/gradle/Dockerfile tools/image
    docker push localhost:5000/test-image-gradle

    echo "> Build/Push the Gradle stack image";
    docker build -t localhost:5000/test-image-maven --build-arg stacklabel=$SHA -f "${dockerfileRootPath}"/image/maven/Dockerfile tools/image
    docker push localhost:5000/test-image-maven
}

# customizeStack customizes stack artifacts for the specified Liberty runtime.
customizeStack() {
    local runtime="$1"

    echo "> Customizing the stack for Liberty deployments";
    sed -i 's!STACK_IMAGE_MAVEN=.*!STACK_IMAGE_MAVEN=\"localhost:5000\/test-image-maven\"!;
            s!STACK_IMAGE_GRADLE=.*!STACK_IMAGE_GRADLE=\"localhost:5000\/test-image-gradle\"!' customize-"${runtime}".env
    cat customize-"${runtime}".env
    ./build.sh "$runtime"
}

# installOpenLibertyOperator installs the Open Liberty operator.
installOpenLibertyOperator() {
    echo -e "\n> Installing Open Liberty operator CRDs"
    kubectl apply -f https://raw.githubusercontent.com/OpenLiberty/open-liberty-operator/master/deploy/releases/0.7.0/openliberty-app-crd.yaml

    echo -e "\n> Installing Open Liberty operator cluster level roles"
    curl -L https://raw.githubusercontent.com/OpenLiberty/open-liberty-operator/master/deploy/releases/0.7.0/openliberty-app-cluster-rbac.yaml \
      | sed -e "s/OPEN_LIBERTY_OPERATOR_NAMESPACE/default/" \
      | kubectl apply -f -

    echo -e "\n> Creating an Open Liberty application operator CR instance"
    curl -L https://raw.githubusercontent.com/OpenLiberty/open-liberty-operator/master/deploy/releases/0.7.0/openliberty-app-operator.yaml \
      | sed -e "s/OPEN_LIBERTY_WATCH_NAMESPACE/\"\"/" \
      | kubectl apply -n default -f -

    echo -e "\n> Wait for the Open Liberty operator application CR instance pod to start"
    count=1
    while [[ $(kubectl get pods -n default -l name=open-liberty-operator  -o 'jsonpath={..status.conditions[?(@.type=="Ready")].status}') != "True" ]]; do 
        kubectl get pods -n default
        echo "waiting for the Open Liberty operator application CR instance pod" && sleep 3; 
        count=`expr $count + 1`
        if [ $count -eq 20 ]; then
            echo "Timed out waiting for the Open Liberty operator application CR instance pod to start. Pod Config:"
            printPodConfig "name=open-liberty-operator" "default"
            echo "Open Liberty operator application CR instance pod log:"
            printPodLog "name=open-liberty-operator" "default"
            exit 12
        fi
    done
}

# printPodConfig prints pod information associated to the input label and namespace.
# Parm 1: The label (key=value) that identifies the pod of interest.
# Parm 2: The namespace where the target pod is deployed.
printPodConfig() {
    podname=$(kubectl get pod -l $1 -n $2 -o jsonpath='{.items[*].metadata.name}')
    if [[ ! -z $podname ]]; then
        kubectl describe pod $podname -n $2
    else
        echo "Pod with label $1 in namespace $2 was not found.";
    fi
}

# printPodLog prints the pod log associated to the input label and namespace.
# Parm 1: The label (key=value) that identifies the pod of interest.
# Parm 2: The namespace where the target pod is deployed.
printPodLog() {
    podname=$(kubectl get pod -l $1 -n $2 -o jsonpath='{.items[*].metadata.name}')
    if [[ ! -z $podname ]]; then
        kubectl logs $podname -n $2
    else
        echo "Pod with label $1 in namespace $2 was not found.";
    fi
}

# printLibertyServerMsgLog prints the Liberty server messages.log running 
# on the pod associated to the input label and namespace.
# Parm 1: The label (key=value) that identifies the pod of interest.
# Parm 2: The namespace where the target pod is deployed.
# Parm 3: The path of the Liberty logs directory.
printLibertyServerMsgLog() { 
    podname=$(kubectl get pod -l $1 -n $2 -o jsonpath='{.items[*].metadata.name}')
    if [[ ! -z $podname ]]; then
        kubectl exec $podname -n $2 -- ls $3/messages.log
        rc=$?
        if [ $rc -eq 0 ]; then
            kubectl exec $podname -n $2 -- cat $3/messages.log
        else
            echo "Liberty messages.log not found in pod with label $1, namespace $2, and log path $3";
        fi
    else
        echo "Pod with label $1 in namespace $2 was not found.";
    fi
}

# checkLibertyServerLogForErrorAndWarnings searches the Liberty server messages.log
# for warning or error messages. If they are found, the method exits with a non-zero return code. 
# The pod running the server is located using the input label and namespace.
# Parm 1: The label (key=value) that identifies the pod of interest.
# Parm 2: The namespace where the target pod is deployed.
# Parm 3: The path of the Liberty logs directory.
checkLibertyServerLogForErrorAndWarnings() {
    warnErrFound=$(printLibertyServerMsgLog $1 $2 $3 | grep -E "^.*[EW] .*[0-9]{4}[EW]:.*$")
    if [[ ! -z $warnErrFound ]]; then
        echo $warnErrFound
        exit 12
    fi
}

# printLibertyDebugData prints debug data associated to the liberty pod deployment.
# Parm 1: The label (key=value) that identifies the pod of interest.
# Parm 2: The namespace where the target pod is deployed.
# Parm 3: The path of the Liberty logs directory.
printLibertyDebugData() {
    echo "Pod (hosting liberty server) config:"
    printPodConfig $1 $2
    echo "Pod (hosting liberty server) log:"
    printPodLog $1 $2
    echo "liberty server messages.log:"
    printLibertyServerMsgLog $1 $2 $3
}

# Execute the specified action.
if [ $# -ge 1 ]; then
    COMMAND=$1
fi
case "${COMMAND}" in
    buildStackImage)
        buildStackImage $2
    ;;
    customizeStack)
        customizeStack $2
    ;;
    installOpenLibertyOperator)
        installOpenLibertyOperator
    ;;
    printPodConfig)
        printPodConfig $2 $3
    ;;
    printPodLog)
        printPodLog $2 $3
    ;;
    printLibertyServerMsgLog)
        printLibertyServerMsgLog $2 $3 $4
    ;;
    printLibertyDebugData)
        printLibertyDebugData $2 $3 $4
    ;;
    checkLibertyServerLogForErrorAndWarnings)
        checkLibertyServerLogForErrorAndWarnings $2 $3 $4
    ;;
    *)
    echo "Invalid command. Allowed values: buildStackImage, customizeStack, installOpenLibertyOperator, printPodConfig, printPodLog, printLibertyServerMsgLog, printLibertyDebugData, and checkLibertyServerLogForErrorAndWarnings"
    exit 1
    ;;
esac