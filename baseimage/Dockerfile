FROM adoptopenjdk/openjdk11-openj9:ubi AS maven

RUN yum upgrade --disableplugin=subscription-manager -y \
   && yum clean --disableplugin=subscription-manager packages \
   && echo 'Finished installing dependencies'

RUN  useradd --uid 1000 --gid 0 --shell /bin/bash --create-home java_user

# Dependency install
RUN yum install --disableplugin=subscription-manager -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm \
   && yum install --disableplugin=subscription-manager -y unzip curl ca-certificates wget xmlstarlet

# Maven install
ARG MAVEN_VERSION=3.6.3
ARG SHA=c35a1803a6e70a126e80b2b3ae33eed961f83ed74d18fcd16909b2d44d7dada3203f1ffe726c17ef8dcca2dcaa9fca676987befeadc9b9f759967a8cb77181c0
ARG BASE_URL=https://archive.apache.org/dist/maven/maven-3/${MAVEN_VERSION}/binaries/

RUN mkdir -p /usr/share/maven /usr/share/maven/ref \
  && curl -fsSL -o /tmp/apache-maven.tar.gz ${BASE_URL}/apache-maven-${MAVEN_VERSION}-bin.tar.gz \
  && echo "${SHA}  /tmp/apache-maven.tar.gz" | sha512sum -c - \
  && tar -xzf /tmp/apache-maven.tar.gz -C /usr/share/maven --strip-components=1 \
  && rm -f /tmp/apache-maven.tar.gz \
  && ln -s /usr/share/maven/bin/mvn /usr/bin/mvn

FROM maven AS builder

RUN  mkdir -p /mvn/repository \
  && chown -R java_user /mvn \
  && mkdir -p /stacks/java-openliberty/priming-app \
  && chown -R java_user /stacks 

COPY ./LICENSE /licenses/

USER java_user

RUN chmod -R 755 /stacks/java-openliberty/priming-app

ADD ./priming-app/src /stacks/java-openliberty/priming-app/src
COPY ./priming-app/pom.xml /stacks/java-openliberty/priming-app/

WORKDIR /stacks/java-openliberty/priming-app

# This layer isn't strictly necessary given the next layer, but gets a bunch of mvn caching accomplished so there's a smaller delta we need to do in the next step, in the background
RUN mvn -DserverName=tmp -Dmaven.repo.local=/mvn/repository -Dliberty.runtime.version=20.0.0.9 liberty:create liberty:install-feature install
# A hack maybe but there's quite a few dependencies that only are detected when dev mode is executed, due to use of mojo executor, etc.
RUN nohup bash -c "mvn -DserverName=tmp -Dmaven.repo.local=/mvn/repository -Dliberty.runtime.version=20.0.0.9 liberty:dev -DhotTests=true &" && sleep 180 && echo "Done sleeping"

FROM maven
RUN mkdir /mvn
RUN mkdir -p /opt/ol
CMD /bin/bash
COPY --from=builder /mvn /mvn
COPY --from=builder /stacks/java-openliberty/priming-app/target/liberty /opt/ol
COPY --from=builder /licenses /licenses
# Delete the server, users will create their own server
RUN rm -rf /opt/ol/wlp/usr/servers/tmp
RUN chmod -R 775 /mvn
RUN chmod -R 775 /opt/ol
ARG stacklabel
LABEL org.opencontainers.image.revision=$stacklabel
