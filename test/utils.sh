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

# Execute the specified action.
if [ $# -ge 1 ]; then
    COMMAND=$1
    shift
fi
case "${COMMAND}" in
    buildStackImage)
        buildStackImage
    ;;
    buildStack)
        buildStack
    ;;
    *)
    echo "Invalid command. Allowed values: buildStackImage."
    exit 1
    ;;
esac