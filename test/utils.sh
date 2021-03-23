#!/bin/bash

buildStackImage() {

    echo "> Building Stack Image";
    docker run --rm -it --network=host alpine ash -c "apk add socat && socat TCP-LISTEN:5000,reuseaddr,fork TCP:$(minikube ip):5000"

    stackImage=$(cat generated/devfile.yaml | grep "localhost:5000/test-image")
    echo $stackImage
    
    docker build -t localhost:5000/test-image --build-arg stacklabel=$SHA -f generated/stackimage-Dockerfile stackimage
    docker push localhost:5000/test-image
}

buildStack() {

    echo "> Building Stack";
    
    export STACK_IMAGE=localhost:5000/test-image
    ./build.sh
    ls -al generated
}

# printPodConfig prints pod information associated to the input label.
# Parm 1: The label (key=value) that identifies the pod of interest.
# Parm 2: The namespace where the target pod is deployed.
printPodConfig() {
    echo "Pod config information:"
    podname=$(kubectl get pod -l $1 -n $2 -o jsonpath='{.items[*].metadata.name}')
    if [[ ! -z $1 && ! -z $podname ]]; then
        kubectl get pods $podname -n $2 -o yaml
    fi
}

# printPodLog prints the pod log associated to the input label in the current namespace.
# Parm 1: The label (key=value) that identifies the pod of interest.
# Parm 2: The namespace where the target pod is deployed.
printPodLog() {
    echo "Pod log output:"
    podname=$(kubectl get pod -l $1 -n $2 -o jsonpath='{.items[*].metadata.name}')
    if [[ ! -z $1 && ! -z $podname ]]; then
        kubectl logs $podname -n $2
    fi
}

# printLibertyServerMsgLog prints the Open Liberty server messages.log running 
# on the pod associated to the input label in the current namespace.
# Parm 1: The label (key=value) that identifies the pod of interest.
# Parm 2: The namespace where the target pod is deployed.
# Parm 3: The path of the Open Liberty Liberty logs directory.
printLibertyServerMsgLog() { 
    echo "Liberty server messages.log:"
    podname=$(kubectl get pod -l $1 -n $2 -o jsonpath='{.items[*].metadata.name}')
    kubectl exec $podname -n $2 -- ls $3/messages.log
    rc=$?
    if [ $rc -eq 0 ]; then
        kubectl exec $podname -n $2 -- cat $3/messages.log
    fi
}

# printDebugData prints debug data.
# Parm 1: The label (key=value) that identifies the pod of interest.
# Parm 2: The namespace where the target pod is deployed.
# Parm 3: The path of the Open Liberty Liberty logs directory.
printDebugData() {
    printPodConfig $1 $2
    printLibertyServerMsgLog $1 $2 $3
    printPodLog $1 $2
}

# Execute the specified action.
if [ $# -ge 1 ]; then
    COMMAND=$1
fi
case "${COMMAND}" in
    buildStackImage)
        buildStackImage
    ;;
    buildStack)
        buildStack
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
    printDebugData)
        printDebugData $2 $3 $4
    ;;
    *)
    echo "Invalid command. Allowed values: buildStackImage, buildStack, printPodConfig, printPodLog, printLibertyServerMsgLog, and printDebugData"
    exit 1
    ;;
esac