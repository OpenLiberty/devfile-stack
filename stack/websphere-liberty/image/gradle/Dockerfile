# 1. Aquire all software prerequisites.
FROM ibmsemeruruntime/open-11-jdk:ubi-jdk AS prereq

RUN yum upgrade --disableplugin=subscription-manager -y \
   && yum clean --disableplugin=subscription-manager packages \
   && echo 'Finished installing dependencies'

RUN  useradd --uid 1001 --gid 0 --shell /bin/bash --create-home java_user

# Command dependency installation.
RUN yum install --disableplugin=subscription-manager -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm \
   && yum install --disableplugin=subscription-manager -y unzip curl ca-certificates wget xmlstarlet procps

# Gradle installation.
ARG GRADLE_VERSION=6.8.3
ARG SHA=7faa7198769f872826c8ef4f1450f839ec27f0b4d5d1e51bade63667cbccd205
ARG BASE_URL=https://services.gradle.org/distributions
ARG GRADLE_DIR=/usr/share/gradle

RUN mkdir -p ${GRADLE_DIR} /tmp/stack/gradle/unzip\
  && curl -fsSL -o /tmp/stack/gradle/gradle.zip ${BASE_URL}/gradle-${GRADLE_VERSION}-bin.zip \
  && echo "${SHA}  /tmp/stack/gradle/gradle.zip" | sha256sum --check - \
  && unzip -d /tmp/stack/gradle/unzip /tmp/stack/gradle/gradle.zip \
  && cp -r /tmp/stack/gradle/unzip/gradle-*/* ${GRADLE_DIR} \
  && rm -rf /tmp/stack \
  && ln -s ${GRADLE_DIR}/bin/gradle /usr/bin/gradle

# 2. Cache all needed data required to build and run the liberty server in dev mode.
FROM prereq AS builder

ENV OPENJ9_JAVA_OPTIONS="-Xshareclasses:name=liberty,nonfatal,cacheDir=/output/.classCache/"

RUN mkdir -p /stacks/java-openliberty/primer/jaxrs \
  && mkdir -p /stacks/java-openliberty/config \
  && chown -R java_user /stacks \
  && mkdir -p /output \
  && chown -R java_user /output \
  && chmod 775 /output

COPY ./LICENSE /licenses/

USER java_user

COPY ./config /stacks/java-openliberty/config
COPY ./primer/jaxrs/src /stacks/java-openliberty/primer/jaxrs/src
COPY ./primer/jaxrs/build.gradle ./primer/jaxrs/settings.gradle /stacks/java-openliberty/primer/jaxrs/

WORKDIR /stacks/java-openliberty/primer/jaxrs

ENV LIBERTY_RUNTIME_VERSION=22.0.0.1
ENV LIBERTY_RUNTIME_ARTIFACTID=wlp-javaee8
ENV LIBERTY_RUNTIME_GROUPID=com.ibm.websphere.appserver.runtime

# Build the priming application to populate the cache (java_user home dir: /home/java_user/.gradle).
RUN umask -S u=rwx,g=rwx,o=rx; gradle build -Pliberty.runtime.version=${LIBERTY_RUNTIME_VERSION} -Pliberty.runtime.name=${LIBERTY_RUNTIME_ARTIFACTID} -Pliberty.runtime.group=${LIBERTY_RUNTIME_GROUPID} --no-daemon

# Start the Liberty server in dev mode. There are dependencies that are detected during dev mode execution due to the use of mojo executor, etc.
RUN nohup bash -c "umask -S u=rwx,g=rwx,o=rx; gradle libertyDev -Pliberty.runtime.version=${LIBERTY_RUNTIME_VERSION} -Pliberty.runtime.name=${LIBERTY_RUNTIME_ARTIFACTID} -Pliberty.runtime.group=${LIBERTY_RUNTIME_GROUPID} --hotTests &" \
 && sleep 600 \
 && echo  && echo "Done sleeping" && echo

# Delete the defaultServer directory created during libertyDev task execution. Users will customize their own. 
RUN rm -rf /stacks/java-openliberty/primer/jaxrs/build/wlp/usr/servers/defaultServer

# 3. Gather all installed software, Liberty basic installation, and cached Liberty data into the final image. 
FROM prereq

ENV WLP_INSTALL_PATH=/opt/ibm/wlp

ENV OPENJ9_JAVA_OPTIONS="-Xshareclasses:name=liberty,nonfatal,cacheDir=/output/.classCache/"

RUN mkdir -p /output \
  && chown -R java_user /output \
  && chmod 775 /output \
  && mkdir -p $WLP_INSTALL_PATH \
  && chown -R java_user $WLP_INSTALL_PATH/.. \
  && chmod 775 $WLP_INSTALL_PATH/.. \
  && mkdir -p /work/outer-loop-app \
  && chown -R java_user /work \
  && chmod -R 775 /work \
  && mkdir -p /stack/ol/config/configDropins/defaults \
  && chmod -R 775 /stack/ol/config/configDropins/defaults

COPY --chown=1001:0 --from=builder /home/java_user/.gradle /.gradle

# Remove daemon cached data to avoid write issues.
RUN  rm -rf /.gradle/daemon; chmod -R 775 /.gradle

COPY --chown=1001:0 --from=builder /stacks/java-openliberty/config/configDropins/defaults/ /stack/ol/config/configDropins/defaults/

COPY --chown=1001:0 --from=builder /stacks/java-openliberty/primer/jaxrs/build/wlp $WLP_INSTALL_PATH
COPY --chown=1001:0 ./LICENSE /licenses/

USER java_user
CMD /bin/bash