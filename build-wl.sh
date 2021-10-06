#!/bin/bash

####
# For more documentation, see:
#  https://github.com/OpenLiberty/application-stack/wiki/Open-Liberty-Application-Stack-Customization
####

#
# Stack name
#
STACK_NAME="${STACK_NAME:-WebSphere Liberty}"
 
#
# Stack short name
#
STACK_SHORT_NAME="${STACK_SHORT_NAME:-websphereliberty}"

#
# Base image used to build stack image
#
# USE OF adoptopenjdk/openjdk11-openj9:jdk-11.0.12_7_openj9-0.27.0-ubi IS A TEMPORARY WORKAROUND - waiting for adoptopenjdk/openjdk11-openj9:ubi to be finalized at which point we should revert back to it.
BASE_OS_IMAGE="${BASE_OS_IMAGE:-adoptopenjdk/openjdk11-openj9:jdk-11.0.12_7_openj9-0.27.0-ubi}"

#
# Version of Open Liberty runtime to install in the stack image
#
LIBERTY_RUNTIME_VERSION="${LIBERTY_RUNTIME_VERSION:-21.0.0.9}"

#
# Archive Id of the Liberty runtime archive
#
LIBERTY_RUNTIME_ARTIFACTID="${LIBERTY_RUNTIME_ARTIFACTID:-wlp-javaee8}"

#
# Group Id of the Liberty runtime archive
#
LIBERTY_RUNTIME_GROUPID="${LIBERTY_RUNTIME_GROUPID:-com.ibm.websphere.appserver.runtime}"

#
# Installation path for Liberty in official Liberty images. This is also used as the installation path for the innerloop stack image
#
WLP_INSTALL_PATH="${WLP_INSTALL_PATH:-/opt/ibm/wlp}"

#
# The Open Liberty base image used in the final stage of the outer loop Dockerfile used to build your application image from
#
LIBERTY_IMAGE="${LIBERTY_UBI_IMAGE:-websphere-liberty:21.0.0.9-full-java11-openj9}"

#
# The name and tag of the stack image you will build.  This will used to create your inner loop development containers, and also as the base image for the first stage of your outer loop image build.
#
STACK_IMAGE_MAVEN="${STACK_IMAGE_MAVEN:-openliberty/application-stack:wl-0.8}"
STACK_IMAGE_GRADLE="${STACK_IMAGE_GRADLE:-openlibery/application-stack:gradle-wl-0.3}"

#
# URL at which your outer loop Dockerfile is hosted
#
OUTERLOOP_DOCKERFILE_MAVEN_LOC="${OUTERLOOP_DOCKERFILE_MAVEN_LOC:-https://github.com/OpenLiberty/application-stack/releases/download/maven-0.7.0/Dockerfile}"
OUTERLOOP_DOCKERFILE_GRADLE_LOC="${OUTERLOOP_DOCKERFILE_GRADLE_LOC:-https://github.com/OpenLiberty/application-stack/releases/download/gradle-0.2.0/Dockerfile}"

#
# URL at which your outer loop deploy YAML template is hosted
#
DEVFILE_DEPLOY_YAML_MAVEN_LOC="${DEVFILE_DEPLOY_YAML_MAVEN_LOC:-https://github.com/OpenLiberty/application-stack/releases/download/maven-0.7.0/app-deploy.yaml}"
DEVFILE_DEPLOY_YAML_GRADLE_LOC="${DEVFILE_DEPLOY_YAML_GRADLE_LOC:-https://github.com/OpenLiberty/application-stack/releases/download/gradle-0.2.0/app-deploy.yaml}"

#
# The previous major microprofile spec API version supported by the stack.
#
ECLIPSE_MP_API_PREV_VERSION="${ECLIPSE_MP_API_PREV_VERSION:-3.3}"

#
# The previous OpenLiberty major microprofile feature version supported by the stack.
#
OL_MP_FEATURE_PREV_VERSION="${OL_MP_FEATURE_PREV_VERSION:-3.3}"

. ./build.sh $@