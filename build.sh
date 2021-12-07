USAGE="
Usage:
  ./build.sh [Liberty runtime type]

Runtime types:
  ol: If used, it customizes the stack for deployments that use the Open Liberty runtime.
  wl: If used, it customizes the stack for deployments that use the WebSphere Liberty runtime.
  all: If used, it customizes the stack for deployments that use both Open Liberty and WebSphere Liberty runtimes. This is the default if no argument is specified.

Example:
  # Customize the stack for both Open Liberty and WebSphere Liberty deployments.
  ./build.sh
  ./buid.sh all

  # Customize the stack for Open Liberty deployments.
  ./build.sh ol

  # Customize the stack for WebSphere Liberty deployments. 
  ./build.sh wl
  "

# main serves as the entry point for stack customization.
main() {
    local runtimeType="$1"
    local argCount="$#"

    # Validate the input.
    if [ "$argCount" -eq 0 ]; then
        echo "No Liberty runtime type was specified. The default parameter of \"all\" is used."
        runtimeType="all"
    elif [ "$argCount" -gt 1 ]; then
        echo "ERROR: An invalid number of arguments were specified."
        echo "$USAGE"
        exit 1
    fi

    # Apply customizations and modify the stack artifacts based on the Liberty runtime type. 
    case "$runtimeType" in
        ol)
            source "$PWD"/customize-ol.env
            . "$PWD"/tools/build/scripts/customize.sh ol
        ;;
        wl)
            source "$PWD"/customize-wl.env
            . "$PWD"/tools/build/scripts/customize.sh wl
        ;;
        all)
            source "$PWD"/customize-ol.env
            . "$PWD"/tools/build/scripts/customize.sh ol
            source "$PWD"/customize-wl.env
            . "$PWD"/tools/build/scripts/customize.sh wl
        ;;
        *)
            echo "ERROR: An invalid argument was specified: $runtimeType"
            echo "$USAGE"
            exit 1
        ;;
    esac
}

main "$@"