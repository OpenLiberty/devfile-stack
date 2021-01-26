# Step 1: Build the user's application
FROM {{.STACK_IMAGE}} as compile

# Make a well known place for shared library jars separate from the rest of the <server> contents (to help with caching)
RUN mkdir /work/configlibdir \
   && mkdir /work/config \
   &&  mkdir /work/shared

# Copy the rest of the application source
COPY --chown=1001:0 ./src /work/outer-loop-app/src
COPY --chown=1001:0 ./pom.xml /work/outer-loop-app/pom.xml

# Build (and run unit tests) 
#  also liberty:create copies config from src->target
#  also remove quick-start-security.xml since it's convenient for local dev mode but should not be in the production image.
RUN cd /work/outer-loop-app && \
    echo "QUICK START SECURITY IS NOT SECURE FOR PRODUCTION ENVIRONMENTS. IT IS BEING REMOVED" && \
    rm -f src/main/liberty/config/configDropins/defaults/quick-start-security.xml && \
    mvn -e liberty:create package

# Process any resources or shared libraries - if they are present in the dependencies block for this project (there may be none potentially)
# test to see if each is present and move to a well known location for later processing in the next stage
# 
RUN cd /work/outer-loop-app/target/liberty/wlp/usr/servers && \
    if [ -d ./*/lib ]; then mv ./*/lib /work/configlibdir; fi && \
    if [ ! -d /work/configlibdir/lib ]; then mkdir /work/configlibdir/lib; fi && \
    mv -f */* /work/config/ && \
    if [ -d ../shared ]; then mv ../shared/* /work/shared/; fi

# Step 2: Package Open Liberty image
FROM {{.OL_UBI_IMAGE}}

# 2a) Copy user defined shared resources 
COPY --from=compile --chown=1001:0 /work/shared /opt/ol/wlp/usr/shared/

RUN true

# 2b) Copy user defined shared libraries
#      but can't assume config/lib exists - copy from previous stage to a tmp holding place and test
COPY --from=compile --chown=1001:0 /work/configlibdir/ /config

RUN true

# 2c) Copy user defined server config, bootstrap.properties, etc.
COPY --from=compile --chown=1001:0 /work/config/ /config/

# 2d) Install the required features based on the defined configuration. This enables Liberty features and image size to be fit-for-purpose using featureUtility.
RUN features.sh

# 2e) Add the microprofile health feature configuration if it is not already defined in the user's configuration.
RUN mkdir -p /tmp/stack/config/configDropins/defaults
COPY --from=compile --chown=1001:0 /stack/ol/config/configDropins/defaults/ /tmp/stack/config/configDropins/defaults/
RUN if ! /opt/ol/wlp/bin/productInfo featureInfo | grep -q mpHealth-[0-9]*.[0-9]*; then \
        cp /tmp/stack/config/configDropins/defaults/liberty-stack-mpHealth.xml /config/configDropins/defaults; \
        features.sh; \
    fi
RUN rm -rf /tmp/stack

# 2f) Copy the application binary
COPY --from=compile --chown=1001:0 /work/outer-loop-app/target/*.[ew]ar /config/apps
RUN configure.sh && \
    chmod 664 /opt/ol/wlp/usr/servers/*/configDropins/defaults/keystore.xml
