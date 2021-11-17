# Devfile Stack

* [Build](#build)
* [Test](#test)

## Build

### Prereq
- Gradle 6.8.3 or later.
- Maven 3.6.3 or later.

### Procedure

1. Generate the needed artifacts with build.sh.

The build-ol.env and build-wl.env files contain default values for various build inputs for the Open Liberty stack and WebSphere Liberty stack respectively. 
You can run build.sh with the target customization values as inputs or you can update the `build-<ol|wl>.env` script itself if you intend to run the script with no inputs.

**Examples:**

- Using customization arguments:

```
source build-ol.env
BASE_OS_IMAGE=ibmsemeruruntime/open-11-jdk:ubi-jdk \
LIBERTY_RUNTIME_VERSION=21.0.0.9 \
STACK_IMAGE_MAVEN=<my-repo>/<image-maven>:<tag> \
STACK_IMAGE_GRADLE=<my-repo>/<image-gradle>:<tag> \
. ./build.sh
```

- Updating default values in build-ol.env:

```
vi build-ol.env
```
```
...
BASE_OS_IMAGE="ibmsemeruruntime/open-11-jdk:ubi-jdk"
LIBERTY_RUNTIME_VERSION="21.0.0.9"
STACK_IMAGE_MAVEN="<my-repo>/<image-maven>:<tag>"
STACK_IMAGE_GRADLE="<my-repo>/<image-gradle>:<tag>"
...
```
```
source build-ol.env
. ./build.sh
```

2. Build the stack image

Maven:

```
docker build -t <value of STACK_IMAGE_MAVEN in build.sh> -f generated/stackimage/maven/Dockerfile stackimage
```

Gradle:

```
docker build -t <value of STACK_IMAGE_GRADLE in build.sh> -f generated/stackimage/gradle/Dockerfile stackimage
```

3. Push the built images to an accessible repository.

```
docker push <value of STACK_IMAGE_MAVEN in build.sh>
```

```
docker push <value of STACK_IMAGE_GRADLE in build.sh>
```


5. [Test](#test) your build.

## Test

### Prereq
- ODO CLI 2.3.1 or later.
- Kubernetes Cluster. For the procedure that follows an OpenShift cluster is used.

### Procedure

1. Copy the generated maven/gradle devfile to your maven/gradle built test application project root directory.

```
cd <path-to-gradle-project-root-dir>
```
```
cp <path-to>/generated/devfiles/<maven or gradle>/devfile.yaml <path-to-gradle-project-root-dir>/.
```

2. Create an ODO component..

```
odo project create test
```
```
odo create mycomponent
```

3. Push of the gradle application artifacts to the cluster.

```
odo push 
```

4. Validate that the application was deployed successfully using the generated route host to access your application.

```
odo url list
```
```
Sample output:

Found the following URLs for component mycomponent
NAME     STATE      URL                                                        PORT     SECURE     KIND
ep1      Pushed     http://ep1-mycomponent-test.apps.xxxx.xx.xx.xx.com         9080     false      route

```
5. Clean up.

```
odo delete
```