#!/bin/bash

# Generates application stack artifacts.
generate() {
    # Output directories.
    mkdir -p generated/outer-loop/maven; mkdir -p generated/outer-loop/gradle
    mkdir -p generated/stackimage/maven; mkdir -p generated/stackimage/gradle 
    mkdir -p generated/devfiles/maven; mkdir -p generated/devfiles/gradle

    # Devfile customization.
    sed -e "s!{{.STACK_NAME}}!$STACK_NAME!; s!{{.STACK_SHORT_NAME}}!$STACK_SHORT_NAME!; s!{{.LIBERTY_RUNTIME_VERSION}}!$LIBERTY_RUNTIME_VERSION!; s!{{.LIBERTY_PLUGIN_VERSION}}!$LIBERTY_PLUGIN_VERSION!; s!{{.WLP_INSTALL_PATH}}!$WLP_INSTALL_PATH!; s!{{.STACK_IMAGE_MAVEN}}!$STACK_IMAGE_MAVEN!; s!{{.OUTERLOOP_DOCKERFILE_MAVEN_LOC}}!$OUTERLOOP_DOCKERFILE_MAVEN_LOC!; s!{{.DEVFILE_DEPLOY_YAML_MAVEN_LOC}}!$DEVFILE_DEPLOY_YAML_MAVEN_LOC!" templates/devfiles/maven/devfile.yaml > generated/devfiles/maven/devfile.yaml
    sed -e "s!{{.STACK_NAME}}!$STACK_NAME!; s!{{.STACK_SHORT_NAME}}!$STACK_SHORT_NAME!; s!{{.LIBERTY_RUNTIME_VERSION}}!$LIBERTY_RUNTIME_VERSION!; s!{{.LIBERTY_RUNTIME_ARTIFACTID}}!$LIBERTY_RUNTIME_ARTIFACTID!; s!{{.LIBERTY_RUNTIME_GROUPID}}!$LIBERTY_RUNTIME_GROUPID!; s!{{.STACK_IMAGE_GRADLE}}!$STACK_IMAGE_GRADLE!; s!{{.OUTERLOOP_DOCKERFILE_GRADLE_LOC}}!$OUTERLOOP_DOCKERFILE_GRADLE_LOC!; s!{{.DEVFILE_DEPLOY_YAML_GRADLE_LOC}}!$DEVFILE_DEPLOY_YAML_GRADLE_LOC!" templates/devfiles/gradle/devfile.yaml > generated/devfiles/gradle/devfile.yaml
 
    # Stack image docker file customization.
    sed -e "s!{{.BASE_OS_IMAGE}}!$BASE_OS_IMAGE!; s!{{.WLP_INSTALL_PATH}}!$WLP_INSTALL_PATH!; s!{{.LIBERTY_RUNTIME_VERSION}}!$LIBERTY_RUNTIME_VERSION!; s!{{.LIBERTY_RUNTIME_ARTIFACTID}}!$LIBERTY_RUNTIME_ARTIFACTID!; s!{{.LIBERTY_RUNTIME_GROUPID}}!$LIBERTY_RUNTIME_GROUPID!; s!{{.ECLIPSE_MP_API_PREV_VERSION}}!$ECLIPSE_MP_API_PREV_VERSION!; s!{{.OL_MP_FEATURE_PREV_VERSION}}!$OL_MP_FEATURE_PREV_VERSION!" templates/stackimage/maven/Dockerfile > generated/stackimage/maven/Dockerfile
    sed -e "s!{{.BASE_OS_IMAGE}}!$BASE_OS_IMAGE!; s!{{.WLP_INSTALL_PATH}}!$WLP_INSTALL_PATH!; s!{{.LIBERTY_RUNTIME_VERSION}}!$LIBERTY_RUNTIME_VERSION!; s!{{.LIBERTY_RUNTIME_ARTIFACTID}}!$LIBERTY_RUNTIME_ARTIFACTID!; s!{{.LIBERTY_RUNTIME_GROUPID}}!$LIBERTY_RUNTIME_GROUPID!; s!{{.ECLIPSE_MP_API_PREV_VERSION}}!$ECLIPSE_MP_API_PREV_VERSION!; s!{{.OL_MP_FEATURE_PREV_VERSION}}!$OL_MP_FEATURE_PREV_VERSION!" templates/stackimage/gradle/Dockerfile > generated/stackimage/gradle/Dockerfile

    # Outer loop docker file customization.
    sed -e "s!{{.OUTERLOOP_STACK_IMAGE_MAVEN}}!$OUTERLOOP_STACK_IMAGE_MAVEN!; s!{{.WLP_INSTALL_PATH}}!$WLP_INSTALL_PATH!; s!{{.LIBERTY_RUNTIME_VERSION}}!$LIBERTY_RUNTIME_VERSION!; s!{{.LIBERTY_PLUGIN_VERSION}}!$LIBERTY_PLUGIN_VERSION!; s!{{.OUTERLOOP_LIBERTY_IMAGE}}!$OUTERLOOP_LIBERTY_IMAGE!;" templates/outer-loop/maven/Dockerfile > generated/outer-loop/maven/Dockerfile
    sed -e "s!{{.OUTERLOOP_STACK_IMAGE_GRADLE}}!$OUTERLOOP_STACK_IMAGE_GRADLE!; s!{{.WLP_INSTALL_PATH}}!$WLP_INSTALL_PATH!; s!{{.LIBERTY_RUNTIME_VERSION}}!$LIBERTY_RUNTIME_VERSION!; s!{{.OUTERLOOP_LIBERTY_IMAGE}}!$OUTERLOOP_LIBERTY_IMAGE!;" templates/outer-loop/gradle/Dockerfile > generated/outer-loop/gradle/Dockerfile    
}

# Build the stack image 
buildStackImage() {
    # Build Maven image
    docker build -t stack-image-maven -f generated/stackimage/maven/Dockerfile stackimage
    
    # Build Gradle image
    docker build -t stack-image-gradle -f generated/stackimage/gradle/Dockerfile stackimage
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
    buildStackImage)
        buildStackImage
    ;;
    *)
    echo "Invalid input action. Allowed action values: generate | buildStackImage. Default: generate."
    exit 1
    ;;
esac
