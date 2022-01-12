#!/bin/bash

set -E

# main serves as the entry point for stack customization.
main() {
    local runtimeType="$1"

    # Add internal pre-set variables and trigger stack customization based on the Liberty runtime type.
    case "$runtimeType" in
        ol)
            source "$PWD"/tools/build/env/ol.env
            customize "$runtimeType"
        ;;
        wl)
            source "$PWD"/tools/build/env/wl.env
            customize "$runtimeType"
        ;;
        *)
            echo "ERROR: An invalid argument was specified. Input argument: $runtimeType"
            echo "$USAGE"
            exit 1
        ;;
    esac
}

# customize processes stack artifact updates based on set variables.
customize() {
    local runtime="$1"
    local destRootPath="$PWD/stack/open-liberty"

    if [ "$runtime" = "wl" ]; then
        destRootPath="$PWD/stack/websphere-liberty"
    fi

    # Customize devfiles.
    processDevfiles "$destRootPath"

    # Customize stack image files.
    processStackImageFiles "$destRootPath"

    # Customize outer-loop files.
    processOuterLoopFiles "$destRootPath"
}

# processDevfiles replaces devfile source template file entries with customization values.
processDevfiles() {
    local destFileRootPath="$1"

    # Maven files.
    sed -e "s!{{.STACK_NAME}}!$STACK_NAME!; s!{{.STACK_SHORT_NAME}}!$STACK_SHORT_NAME!; s!{{.LIBERTY_RUNTIME_VERSION}}!$LIBERTY_RUNTIME_VERSION!; s!{{.LIBERTY_MAVEN_PLUGIN_VERSION}}!$LIBERTY_MAVEN_PLUGIN_VERSION!; s!{{.WLP_INSTALL_PATH}}!$WLP_INSTALL_PATH!; s!{{.MAVEN_CMD}}!$MAVEN_CMD!; s!{{.STACK_IMAGE_MAVEN}}!$STACK_IMAGE_MAVEN!; s!{{.OUTERLOOP_DOCKERFILE_MAVEN_LOC}}!$OUTERLOOP_DOCKERFILE_MAVEN_LOC!; s!{{.OUTERLOOP_DEPLOY_YAML_MAVEN_LOC}}!$OUTERLOOP_DEPLOY_YAML_MAVEN_LOC!" src/devfiles/maven/devfile.yaml > "${destFileRootPath}"/devfiles/maven/devfile.yaml
    validate "${destFileRootPath}"/devfiles/maven/devfile.yaml

    # Gradle files.
    sed -e "s!{{.STACK_NAME}}!$STACK_NAME!; s!{{.STACK_SHORT_NAME}}!$STACK_SHORT_NAME!; s!{{.LIBERTY_RUNTIME_VERSION}}!$LIBERTY_RUNTIME_VERSION!; s!{{.LIBERTY_RUNTIME_ARTIFACTID}}!$LIBERTY_RUNTIME_ARTIFACTID!; s!{{.LIBERTY_RUNTIME_GROUPID}}!$LIBERTY_RUNTIME_GROUPID!; s!{{.STACK_IMAGE_GRADLE}}!$STACK_IMAGE_GRADLE!; s!{{.OUTERLOOP_DOCKERFILE_GRADLE_LOC}}!$OUTERLOOP_DOCKERFILE_GRADLE_LOC!; s!{{.OUTERLOOP_DEPLOY_YAML_GRADLE_LOC}}!$OUTERLOOP_DEPLOY_YAML_GRADLE_LOC!" src/devfiles/gradle/devfile.yaml > "${destFileRootPath}"/devfiles/gradle/devfile.yaml
    validate "${destFileRootPath}"/devfiles/gradle/devfile.yaml
}

# processStackImageFiles replaces stack image source template file entries with customization values.
processStackImageFiles() {
    local destFileRootPath="$1"

    # Maven files.
    sed -e "s!{{.BASE_OS_IMAGE}}!$BASE_OS_IMAGE!; s!{{.WLP_INSTALL_PATH}}!$WLP_INSTALL_PATH!; s!{{.LIBERTY_RUNTIME_VERSION}}!$LIBERTY_RUNTIME_VERSION!; s!{{.MAVEN_VERSION}}!$MAVEN_VERSION!; s!{{.MAVEN_SHA}}!$MAVEN_SHA!; s!{{.MAVEN_CMD}}!$MAVEN_CMD!; s!{{.MAVEN_REPO_LOCAL}}!$MAVEN_REPO_LOCAL!; s!{{.LIBERTY_MAVEN_PLUGIN_VERSION}}!$LIBERTY_MAVEN_PLUGIN_VERSION!; s!{{.LIBERTY_RUNTIME_ARTIFACTID}}!$LIBERTY_RUNTIME_ARTIFACTID!; s!{{.LIBERTY_RUNTIME_GROUPID}}!$LIBERTY_RUNTIME_GROUPID!" src/image/maven/Dockerfile > "${destFileRootPath}"/image/maven/Dockerfile
    validate "${destFileRootPath}"/image/maven/Dockerfile

    # Gradle files.
    sed -e "s!{{.BASE_OS_IMAGE}}!$BASE_OS_IMAGE!; s!{{.WLP_INSTALL_PATH}}!$WLP_INSTALL_PATH!; s!{{.LIBERTY_RUNTIME_VERSION}}!$LIBERTY_RUNTIME_VERSION!; s!{{.GRADLE_VERSION}}!$GRADLE_VERSION!; s!{{.LIBERTY_RUNTIME_ARTIFACTID}}!$LIBERTY_RUNTIME_ARTIFACTID!; s!{{.LIBERTY_RUNTIME_GROUPID}}!$LIBERTY_RUNTIME_GROUPID!" src/image/gradle/Dockerfile > "${destFileRootPath}"/image/gradle/Dockerfile
    validate "${destFileRootPath}"/image/gradle/Dockerfile
}

# processOuterLoopFiles replaces outer-loop source template file entries with customization values.
processOuterLoopFiles() {
    local destFileRootPath="$1"

    # Re-format the STACK_IMAGE_MAVEN default customization value for ourter loop file usage. 
    # Customizations that contain the {{{liberty-version}} entry are automatically replaced with the correct variable format for Docker files.
    outerLoopStackImageMaven=$(echo $STACK_IMAGE_MAVEN | sed "s!\\\\{\\\\{liberty-version\\\\}\\\\}!\\\\$\\\\{LIBERTY_VERSION\\\\}!")
    outerLoopStackImageGradle=$(echo $STACK_IMAGE_GRADLE | sed "s!\\\\{\\\\{liberty-version\\\\}\\\\}!\\\\$\\\\{LIBERTY_VERSION\\\\}!")

    # Maven files.
    sed -e "s!{{.STACK_IMAGE_MAVEN}}!$outerLoopStackImageMaven!; s!{{.WLP_INSTALL_PATH}}!$WLP_INSTALL_PATH!; s!{{.LIBERTY_RUNTIME_VERSION}}!$LIBERTY_RUNTIME_VERSION!; s!{{.LIBERTY_MAVEN_PLUGIN_VERSION}}!$LIBERTY_MAVEN_PLUGIN_VERSION!; s!{{.OUTERLOOP_LIBERTY_IMAGE}}!$OUTERLOOP_LIBERTY_IMAGE!" src/outer-loop/maven/Dockerfile > "${destFileRootPath}"/outer-loop/maven/Dockerfile
    validate "${destFileRootPath}"/outer-loop/maven/Dockerfile

    # Gradle files.
    sed -e "s!{{.STACK_IMAGE_GRADLE}}!$outerLoopStackImageGradle!; s!{{.WLP_INSTALL_PATH}}!$WLP_INSTALL_PATH!; s!{{.LIBERTY_RUNTIME_VERSION}}!$LIBERTY_RUNTIME_VERSION!; s!{{.OUTERLOOP_LIBERTY_IMAGE}}!$OUTERLOOP_LIBERTY_IMAGE!;s!{{.LIBERTY_MAVEN_PLUGIN_VERSION}}!$LIBERTY_MAVEN_PLUGIN_VERSION!; s!{{.LIBERTY_RUNTIME_ARTIFACTID}}!$LIBERTY_RUNTIME_ARTIFACTID!; s!{{.LIBERTY_RUNTIME_GROUPID}}!$LIBERTY_RUNTIME_GROUPID!" src/outer-loop/gradle/Dockerfile > "${destFileRootPath}"/outer-loop/gradle/Dockerfile
    validate "${destFileRootPath}"/outer-loop/gradle/Dockerfile
}

# validate verifies that input file does not contain replaceable template entries, but actual values.
validate() {
    local file="$1"

    # Basic validation. Search for unreplaced entries of the form: {{.SOME_NAME}}
    grepOutput=$(grep {{\\..*}} "$file")
    rc=$?
    if [ "$rc" -eq 0 ]; then 
        echo "ERROR: customization validation detected that file $file contains one or more uncustomized entries: $grepOutput"
        exit 1
    fi
}

main "$@"
