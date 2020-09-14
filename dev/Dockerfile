# Step 1: Build the user's application
FROM ajymau/java-openliberty-odo:0.1.3 as compile

# Make a well known place for shared library jars seperate from the rest of the defaultServer contents (to help with caching)
RUN mkdir /configlibdir \
   && mkdir /config \
   &&  mkdir /shared


# Copy the rest of the application source
COPY ./src /project/user-app/src
COPY ./pom.xml /project/user-app/pom.xml

# Build (and run unit tests) 
#  also liberty:create copies config from src->target
#  also remove quick-start-security.xml since it's convenient for local dev mode but should not be in the production image.
RUN cd /project/user-app && \
    echo "QUICK START SECURITY IS NOT SECURE FOR PRODUCTION ENVIRONMENTS. IT IS BEING REMOVED" && \
    rm -f src/main/liberty/config/configDropins/defaults/quick-start-security.xml && \
    mvn liberty:create package

# process any resources or shared libraries - if they are present in the dependencies block for this project (there may be none potentially)
# test to see if each is present and move to a well known location for later processing in the next stage
# 
RUN cd /project/user-app/target/liberty/wlp/usr/servers && \
    if [ -d ./defaultServer/lib ]; then mv ./defaultServer/lib /configlibdir; fi && \
    if [ ! -d /configlibdir/lib ]; then mkdir /configlibdir/lib; fi && \
    mv -f defaultServer/* /config/ && \
    if [ -d ../shared ]; then mv ../shared/* /shared/; fi

# Step 2: Package Open Liberty image
FROM openliberty/open-liberty:20.0.0.9-kernel-java11-openj9-ubi

#2a) copy any resources 
COPY --from=compile /shared /opt/ol/wlp/usr/shared/

# 2b) next copy shared library
#      but can't assume config/lib exists - copy from previous stage to a tmp holding place and test
COPY --from=compile /configlibdir/ /config

# 2c) Server config, bootstrap.properties, and everything else
COPY --from=compile /config/ /config/

# 2d) Changes to the application binary
COPY --from=compile /project/user-app/target/*.[ew]ar /config/apps
RUN configure.sh && \
    chmod 664 /opt/ol/wlp/usr/servers/defaultServer/configDropins/defaults/keystore.xml
