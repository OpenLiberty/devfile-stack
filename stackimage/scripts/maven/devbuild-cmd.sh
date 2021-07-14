#!/bin/sh

if [ -e /projects/.disable-bld-cmd ]; then
    echo "Found the disable-bld-cmd file" && echo "The devBuild command will not run" && exit 0;
elif [ ! -e /projects/pom.xml ]; then 
    echo "  ERROR: This project does not contain a pom.xml or a build.gradle file. Please correct the issue and try again.";
    exit 1
else
    echo "will run the devBuild command using maven" && mkdir -p /projects/target/liberty
    if [ ! -d /projects/target/liberty/wlp ]; then 
        echo "...moving liberty"; mv /opt/ol/wlp /projects/target/liberty; touch ./.liberty-mv;
    elif [[ -d /projects/target/liberty/wlp && ! -e /projects/.liberty-mv ]]; then
        echo "STACK WARNING - LIBERTY RUNTIME WAS LOADED FROM HOST";
    fi	 
    mvn -Dliberty.runtime.version=$1 package
fi

touch ./.disable-bld-cmd