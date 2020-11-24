#!/bin/bash

####
# For more documentation, see:
#  https://github.com/OpenLiberty/application-stack/wiki/Open-Liberty-Application-Stack-Customization
####

#
# Base image used to build stack image
#
BASE_OS_IMAGE="${BASE_OS_IMAGE:-adoptopenjdk/openjdk11-openj9:ubi}"

#
# Version of Open Liberty runtime to use within both inner and outer loops
#
OL_RUNTIME_VERSION="${OL_RUNTIME_VERSION:-20.0.0.10}"

#
# The Open Liberty base image used in the final stage of the outer loop Dockerfile used to build your application image from
#
OL_UBI_IMAGE="${OL_UBI_IMAGE:-openliberty/open-liberty:20.0.0.10-kernel-java11-openj9-ubi}"

#
# The name and tag of the "stack image you will build.  This will used to create your inner loop development containers, and also as the base image for the first stage of your outer loop image build.
#
STACK_IMAGE="${STACK_IMAGE:-openliberty/application-stack:0.4}"

#
# URL at which your outer loop Dockerfile is hosted
#
DEVFILE_DOCKERFILE_LOC="${DEVFILE_DOCKERFILE_LOC:-https://raw.githubusercontent.com/OpenLiberty/application-stack-registry/releases/outer-loop/0.4/Dockerfile}"

#
# URL at which your outer loop deploy YAML template is hosted
#
DEVFILE_DEPLOY_YAML_LOC="${DEVFILE_DEPLOY_YAML_LOC:-https://raw.githubusercontent.com/OpenLiberty/application-stack-registry/releases/outer-loop/0.4/app-deploy.yaml}"

generate() {

    # Base customization.
    mkdir -p generated
    sed -e "s!{{.OL_RUNTIME_VERSION}}!$OL_RUNTIME_VERSION!; s!{{.STACK_IMAGE}}!$STACK_IMAGE!; s!{{.DEVFILE_DOCKERFILE_LOC}}!$DEVFILE_DOCKERFILE_LOC!; s!{{.DEVFILE_DEPLOY_YAML_LOC}}!$DEVFILE_DEPLOY_YAML_LOC!" templates/devfile.yaml > generated/devfile.yaml
    sed -e "s!{{.BASE_OS_IMAGE}}!$BASE_OS_IMAGE!; s!{{.OL_RUNTIME_VERSION}}!$OL_RUNTIME_VERSION!" templates/stackimage/Dockerfile > generated/stackimage-Dockerfile

    # Outer loop customization of Dockerfile
    sed -e "s!{{.STACK_IMAGE}}!$STACK_IMAGE!; s!{{.OL_UBI_IMAGE}}!$OL_UBI_IMAGE!" templates/outer-loop/Dockerfile > generated/Dockerfile

}

release() {

    SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
    REGISTRY_HOME=$SCRIPT_DIR/../application-stack-registry

    if [ ! -d "$REGISTRY_HOME" ]; then
        echo "Expecting to find application-stack-registry repo in $REGISTRY_HOME.  Clone this and re-run" 
        exit 1
    fi

    RELEASES_DIR=$REGISTRY_HOME/releases

    # copy devfile to releases
    DIRS="outer-loop/0.4 outer-loop/0.4.0 outer-loop/latest"
    for d in $DIRS; do 
        mkdir -p $RELEASES_DIR/$d 
        cp generated/Dockerfile $RELEASES_DIR/$d 
        # (no customization at present)
        cp templates/outer-loop/app-deploy.yaml $RELEASES_DIR/$d
    done

    # copy devfile to releases
    DIRS="devfile/0.4 devfile/0.4.0  devfile/latest"
    mkdir -p $DIRS
    for d in $DIRS; do 
        mkdir -p $RELEASES_DIR/$d 
        cp generated/devfile.yaml $RELEASES_DIR/$d
    done

    # copy devfile to devfiles (for 'odo create')
    cp generated/devfile.yaml $REGISTRY_HOME/devfiles/java-openliberty
    cp templates/meta.yaml $REGISTRY_HOME/devfiles/java-openliberty

    cd $REGISTRY_HOME
    git add releases devfiles
    git commit -m "Commit 0.4.0 release artifacts"
}

#set the action, default to generate if none passed.
ACTION="generate"
if [ $# -ge 1 ]; then
  ACTION=$1
  shift
fi
case "${ACTION}" in
  release)
    generate
    release
  ;;
  generate)
    generate
  ;;
  *)
    echo "Invalid input action. Allowed values: generate, release. Default: generate."
    exit 1
  ;;
esac
