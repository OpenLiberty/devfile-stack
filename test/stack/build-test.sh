#!/bin/bash

set -E

# main Tests that the user built the stack before calling merge.
main() {
    # Validate the input.
    local runtimeType="$1"
    local argCount="$#"
    if [[ "$argCount" -ne 1 || -z "$1" ]]; then
        echo "ERROR: An invalid number of arguments were specified. Specify one of these values: \"ol\", \"wl\"."
        exit 1
    fi

    # Process validation.
    case "$runtimeType" in
        "ol"|"wl")
            # Figure out the directory matching the runtime type currently being processed.
            local stackRuntimeDir="open-liberty"
            if [ "$runtimeType" = "wl" ]; then
                stackRuntimeDir="websphere-liberty"
            fi

            # Make a copy of the stack directory.
            cp -r stack stack.merged

            # Build the stack
            ./build.sh

            # Compare the merged stack output files match the ones we just built.
            diffout=$(diff -r "stack.merged/$stackRuntimeDir" "stack/$stackRuntimeDir")
            if [ $? -ne 0 ]; then
                printf "ERROR: Files in stack.merged/$stackRuntimeDir and stack/$stackRuntimeDir do not match. See details:\n$diffout"
                exit 1
            fi

            # Files matched. Cleanup.
            rm -rf stack.merged
        ;;
        *)
            echo "ERROR: Invalid argument: $runtimeType. Specify one of these values: \"ol\", \"wl\""
        ;;
    esac
}

main "$@"