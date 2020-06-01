FROM kabanero/ubi8-maven:0.3.1
RUN  groupadd --gid 1000 java_group \
  && useradd --uid 1000 --gid java_group --shell /bin/bash --create-home java_user \
  && mkdir -p /mvn/repository \
  && chown -R java_user:java_group /mvn \
  && mkdir -p /opt/ol \
  && chown -R java_user:java_group /opt \
  && mkdir -p /stacks/java-openliberty/stackfiles/util \
  && chown -R java_user:java_group /stacks/java-openliberty/stackfiles/util

RUN chmod -R 777 /stacks/java-openliberty/stackfiles

COPY ./LICENSE /licenses/
COPY --chown=java_user:java_group ./project/pom.xml /stacks/java-openliberty/stackfiles
COPY --chown=java_user:java_group ./project/util /stacks/java-openliberty/stackfiles/util/

RUN  /stacks/java-openliberty/stackfiles/util/check_version build

WORKDIR /stacks/java-openliberty/stackfiles
USER java_user
RUN mvn -B -Dmaven.repo.local=/mvn/repository -N io.takari:maven:wrapper -Dmaven=$(mvn help:evaluate -Dexpression=maven.version -q -DforceStdout)
RUN mvn -B -Pstack-image-package -Dmaven.repo.local=/mvn/repository liberty:install-server install dependency:go-offline
RUN chmod -R 777 /opt/ol
RUN chmod -R 777 /mvn/repository
