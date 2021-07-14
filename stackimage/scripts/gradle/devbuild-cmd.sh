#!/bin/sh

if [ -e /projects/.disable-bld-cmd ]; then
    echo "Found the disable-bld-cmd file" && echo "The devBuild command will not run" && exit 0;
elif [ ! -e /projects/build.gradle ]; then 
    echo "  ERROR: This project does not contain a pom.xml or a build.gradle file. Please correct the issue and try again.";
    exit 1
else
    echo "will run the devBuild command using gradle" && mkdir -p /projects/build
    if [ ! -d /projects/build/wlp ]; then 
        echo "...moving liberty"; mv /opt/ol/wlp /projects/build; touch ./.liberty-mv;
    elif [[ -d /projects/build/wlp && ! -e /projects/.liberty-mv ]]; then
        echo "STACK WARNING - LIBERTY RUNTIME WAS LOADED FROM HOST";
    fi
    gradle -Dgradle.user.home=/.gradle assemble
fi

touch ./.disable-bld-cmd