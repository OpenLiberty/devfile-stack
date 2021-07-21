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
OL_RUNTIME_VERSION="${OL_RUNTIME_VERSION:-21.0.0.6}"

#
# The Open Liberty base image used in the final stage of the outer loop Dockerfile used to build your application image from
#
OL_UBI_IMAGE="${OL_UBI_IMAGE:-openliberty/open-liberty:21.0.0.6-full-java11-openj9-ubi}"

#
# The name and tag of the stack image you will build.  This will used to create your inner loop development containers, and also as the base image for the first stage of your outer loop image build.
#
STACK_IMAGE_MAVEN="${STACK_IMAGE_MAVEN:-openliberty/application-stack:0.6.0}"
STACK_IMAGE_GRADLE="${STACK_IMAGE_GRADLE:-openliberty/application-stack:gradle-0.1.0}"

#
# URL at which your outer loop Dockerfile is hosted
#
OUTERLOOP_DOCKERFILE_MAVEN_LOC="${OUTERLOOP_DOCKERFILE_MAVEN_LOC:-https://github.com/OpenLiberty/application-stack/releases/download/maven-0.6.0/Dockerfile}"
OUTERLOOP_DOCKERFILE_GRADLE_LOC="${OUTERLOOP_DOCKERFILE_GRADLE_LOC:-https://github.com/OpenLiberty/application-stack/releases/download/gradle-0.1.0/Dockerfile}"

#
# URL at which your outer loop deploy YAML template is hosted
#
DEVFILE_DEPLOY_YAML_MAVEN_LOC="${DEVFILE_DEPLOY_YAML_MAVEN_LOC:-https://github.com/OpenLiberty/application-stack/releases/download/maven-0.6.0/app-deploy.yaml}"
DEVFILE_DEPLOY_YAML_GRADLE_LOC="${DEVFILE_DEPLOY_YAML_GRADLE_LOC:-https://github.com/OpenLiberty/application-stack/releases/download/gradle-0.1.0/app-deploy.yaml}"

#
# The previous major microprofile spec API version supported by the stack.
#
ECLIPSE_MP_API_PREV_VERSION="${ECLIPSE_MP_API_PREV_VERSION:-3.3}"

#
# The previous OpenLiberty major microprofile feature version supported by the stack.
#
OL_MP_FEATURE_PREV_VERSION="${OL_MP_FEATURE_PREV_VERSION:-3.3}"

# Generates application stack artifacts.
generate() {
    # Output directories.
    mkdir -p generated/outer-loop/maven; mkdir -p generated/outer-loop/gradle
    mkdir -p generated/stackimage/maven; mkdir -p generated/stackimage/gradle 
    mkdir -p generated/devfiles/maven; mkdir -p generated/devfiles/gradle

    # Devfile customization.
    sed -e "s!{{.OL_RUNTIME_VERSION}}!$OL_RUNTIME_VERSION!; s!{{.STACK_IMAGE_MAVEN}}!$STACK_IMAGE_MAVEN!; s!{{.OUTERLOOP_DOCKERFILE_MAVEN_LOC}}!$OUTERLOOP_DOCKERFILE_MAVEN_LOC!; s!{{.DEVFILE_DEPLOY_YAML_MAVEN_LOC}}!$DEVFILE_DEPLOY_YAML_MAVEN_LOC!" templates/devfiles/maven/devfile.yaml > generated/devfiles/maven/devfile.yaml
    sed -e "s!{{.OL_RUNTIME_VERSION}}!$OL_RUNTIME_VERSION!; s!{{.STACK_IMAGE_GRADLE}}!$STACK_IMAGE_GRADLE!; s!{{.OUTERLOOP_DOCKERFILE_GRADLE_LOC}}!$OUTERLOOP_DOCKERFILE_GRADLE_LOC!; s!{{.DEVFILE_DEPLOY_YAML_GRADLE_LOC}}!$DEVFILE_DEPLOY_YAML_GRADLE_LOC!" templates/devfiles/gradle/devfile.yaml > generated/devfiles/gradle/devfile.yaml
 
    # Stack image docker file customization.
    sed -e "s!{{.BASE_OS_IMAGE}}!$BASE_OS_IMAGE!; s!{{.OL_RUNTIME_VERSION}}!$OL_RUNTIME_VERSION!; s!{{.ECLIPSE_MP_API_PREV_VERSION}}!$ECLIPSE_MP_API_PREV_VERSION!; s!{{.OL_MP_FEATURE_PREV_VERSION}}!$OL_MP_FEATURE_PREV_VERSION!" templates/stackimage/maven/Dockerfile > generated/stackimage/maven/Dockerfile
    sed -e "s!{{.BASE_OS_IMAGE}}!$BASE_OS_IMAGE!; s!{{.OL_RUNTIME_VERSION}}!$OL_RUNTIME_VERSION!; s!{{.ECLIPSE_MP_API_PREV_VERSION}}!$ECLIPSE_MP_API_PREV_VERSION!; s!{{.OL_MP_FEATURE_PREV_VERSION}}!$OL_MP_FEATURE_PREV_VERSION!" templates/stackimage/gradle/Dockerfile > generated/stackimage/gradle/Dockerfile

    # Outer loop docker file customization.
    sed -e "s!{{.STACK_IMAGE_MAVEN}}!$STACK_IMAGE_MAVEN!; s!{{.OL_UBI_IMAGE}}!$OL_UBI_IMAGE!; s!{{.OL_RUNTIME_VERSION}}!$OL_RUNTIME_VERSION!" templates/outer-loop/maven/Dockerfile > generated/outer-loop/maven/Dockerfile
    sed -e "s!{{.STACK_IMAGE_GRADLE}}!$STACK_IMAGE_GRADLE!; s!{{.OL_UBI_IMAGE}}!$OL_UBI_IMAGE!; s!{{.OL_RUNTIME_VERSION}}!$OL_RUNTIME_VERSION!" templates/outer-loop/gradle/Dockerfile > generated/outer-loop/gradle/Dockerfile    
}

# Execute the specified action. The generate action is the default if none is specified.
ACTION="generate"
if [ $# -ge 1 ]; then
    ACTION=$1
    shift
fi
case "${ACTION}" in
    generate)
        generate
    ;;
    *)
    echo "Invalid input action. Allowed action values: generate. Default: generate."
    exit 1
    ;;
esac
