# Application Stack Gradle

Application stack built with gradle.

* [Build](#build)
* [Test](#test)

## Build

### Prereq
- Gradle 6.8.3 or later to build artiafcts.

### Procedure

1. Generate the needed artifacts with build.sh.

You can run build.sh with the target customization values as inputs or you can update the build.sh script itself if you intend run the script with no inputs.

**Examples:**

- Using customization arguments:

```
BASE_OS_IMAGE=adoptopenjdk/openjdk14-openj9:ubi \
OL_RUNTIME_VERSION=21.0.0.6 \
OL_UBI_IMAGE=openliberty/open-liberty:21.0.0.6-kernel-slim-java14-openj9-ubi \
STACK_IMAGE_MAVEN=<my-repo>/<image-maven>:<tag> \
STACK_IMAGE_GRADLE=<my-repo>/<image-gradle>:<tag> \
./build.sh
```

- Updating default values in build.sh:

```
vi build.sh
```
```
...
BASE_OS_IMAGE="${BASE_OS_IMAGE:-adoptopenjdk/openjdk14-openj9:ubi}"
OL_RUNTIME_VERSION="${OL_RUNTIME_VERSION:-21.0.0.6}"
OL_UBI_IMAGE="${OL_UBI_IMAGE:-openliberty/open-liberty:21.0.0.6-kernel-slim-java14-openj9-ubi}"
STACK_IMAGE_MAVEN="${STACK_IMAGE_MAVEN:-<my-repo>/<image-maven>:<tag>}"
STACK_IMAGE_GRADLE="${STACK_IMAGE_GRADLE:-<my-repo>/<image-gradle>:<tag>}"
...
```
```
./build.sh
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
- ODO CLI 2.2.3 or later.
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