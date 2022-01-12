# Devfile Stack

* [Build](#build)
* [Test](#test)

## Prereqs
- ODO CLI 2.4.2 or later.
- Kubernetes Cluster. For this documentation an OpenShift cluster is used.

## Build

The stack is built using the build.sh script. This script provides a few build options that allow you to build the supported Liberty runtimes. By default all supported runtimes are built. For more usage details, run the build.sh script with the help option:

```
build.sh help 
```

### Customizing the stack for Open Liberty deployments

1. Update the default values in `customize-ol.env` with the values of your choice.

Example:

```
...
BASE_OS_IMAGE="ibmsemeruruntime/open-11-jdk:ubi-jdk"
LIBERTY_RUNTIME_VERSION="21.0.0.12"
STACK_IMAGE_MAVEN="<custom-stack-image-name-for-maven-deployments>:<tag>"
STACK_IMAGE_GRADLE="<custom-stack-image-name-for-gradle-deployments>:<tag>"
...
```

2. Run the build.sh script with the `ol` argument.

```
./build.sh ol
```

The artifacts in the `stack` directory are now customized for Open Liberty deployments.

3. Build the Maven-based and Gradle-based stack images and push them to an accessible repository. 

Maven:

```
docker build -t <value-of-STACK_IMAGE_MAVEN-in-customize.ol> -f stack/open-liberty/image/maven/Dockerfile tools/image
```
```
docker push <value-of-STACK_IMAGE_MAVEN-in-customize.ol>
```

Gradle:

```
docker build -t <value-of-STACK_IMAGE_GRADLE-in-customize.ol> -f stack/open-liberty/image/gradle/Dockerfile tools/image
```
```
docker push <value-of-STACK_IMAGE_GRADLE-in-customize.ol>
```

4. [Test](#test) your newly created stack images.

### Customizing the stack for WebSphere Liberty deployments

1. Update the default values in `customize-wl.env` with the values of your choice.

Example:

```
...
BASE_OS_IMAGE="ibmsemeruruntime/open-11-jdk:ubi-jdk"
LIBERTY_RUNTIME_VERSION="21.0.0.12"
STACK_IMAGE_MAVEN="<custom-stack-image-name-for-maven-deployments>:<tag>"
STACK_IMAGE_GRADLE="<custom-stack-image-name-for-gradle-deployments>:<tag>"
...
```

2. Run the build.sh script with the `wl` argument.

```
./build.sh wl
```

The artifacts in the `stack` directory are now customized for WebSphere Liberty deployments.

3. Build the Maven-based and Gradle-based stack images and push them to an accessible repository.

Maven:

```
docker build -t <value-of-STACK_IMAGE_MAVEN-in-customize.wl> -f stack/websphere-liberty/image/maven/Dockerfile tools/image
```
```
docker push <value-of-STACK_IMAGE_MAVEN-in-customize.wl>
```

Gradle:

```
docker build -t <value-of-STACK_IMAGE_GRADLE-in-customize.wl> -f stack/websphere-liberty/image/gradle/Dockerfile tools/image
```
```
docker push <value-of-STACK_IMAGE_GRADLE-in-customize.wl>
```

4. [Test](#Test) your newly created stack images.

## Test

Repeat the test steps below for each of the stack images that were created during the [Build stage](#Build):

- Open Liberty Maven stack image.

- Open Liberty Gradle stack image

- WebSphere Liberty Maven stack image.

- WebSphere Liberty Gradle stack image.

1. Access your test application and copy a customized devfile to the application's root directory.

`Open Liberty`

Maven:

```
cd <maven-built-application-project-dir>
```
```
cp devfile-stack/stack/open-liberty/devfiles/maven/devfile.yaml <maven-built-application-project-dir>/.
```

Gradle:

```
cd <gradle-built-application-project-dir>
```
```
cp devfile-stack/stack/open-liberty/devfiles/gradle/devfile.yaml <gradle-built-application-project-dir>/.
```

`WebSphere Liberty`

Maven:

```
cd <maven-built-application-project-dir>
```
```
cp devfile-stack/stack/websphere-liberty/devfiles/maven/devfile.yaml <maven-built-application-project-dir>/.
```

Gradle:

```
cd <gradle-built-application-project-dir>
```
```
cp devfile-stack/stack/websphere-liberty/devfiles/gradle/devfile.yaml <gradle-built-application-project-dir>/.
```

2. Create an ODO project.

```
odo project create test-proj
```

3. Create an ODO component.

```
odo create test-comp
```

4. Push of the application artifacts to the cluster.

```
odo push 
```

5. Validate that the application was deployed successfully.

```
odo url list
```

Sample output:

```
Found the following URLs for component test
NAME     STATE      URL                                                        PORT     SECURE     KIND
ep1      Pushed     http://ep1-test-proj-test-comp.apps.xxxx.xx.xx.xx.com      9080     false      route

```

Use the shown URL to access your application.

6. Clean up.

```
odo delete
```