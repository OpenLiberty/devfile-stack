#!/bin/sh

if [ -e /projects/.disable-bld-cmd ];
then
    echo "found the disable file" && echo "devBuild command will not run" && exit 0;
else
    if [ ! -e /projects/pom.xml ];
	then 
	     echo "\npom.xml not found, non-viable or empty maven project. Please add src code and re-push\n" && exit 1;
	else
         echo "will run the devBuild command" && mkdir -p /projects/target/liberty
         if [ ! -d /projects/target/liberty/wlp ]; then 
             echo "...moving liberty"; mv /opt/ol/wlp /projects/target/liberty; touch ./.liberty-mv;
         elif [[ -d /projects/target/liberty/wlp && ! -e /projects/.liberty-mv ]]; then
             echo "STACK WARNING - LIBERTY RUNTIME WAS LOADED FROM HOST";
         fi
	fi	 
    mvn -Dliberty.runtime.version=$1 package
    touch ./.disable-bld-cmd
fi
