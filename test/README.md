# Test Overview

The devfile-stack repo is tested using Github Actions. 
The tests are run whenever a PR is created/updated/merged.
The main workflow is defined in `stack-regression-tests.yml`.

## Test Steps

### Software Installation

1. Minikube. This is done via the `manusa/actions-setup-minikube` actions plugin.

2. ODO. The latest version is installed.

3. Open Liberty Operator.


### Stack customization 

The stack is build using the build.sh script to customize/populate stack artifacts based on the runtime type (Open Liberty or WebSphere Liberty) needed to run the test application. 

The stack image is built into the local docker registry located at `localhost:5000`.


### Inner-loop test execution

Setup:

1. Clones devfile-stack-intro.
2. Runs `odo project create` to create a project/namespace for the application to run in the cluster.
3. Runs `odo create` to create a test component.
4. Runs `odo push` to create the needed resources and push the application to the cluster.

Validation:

1. Using endpoint: /health/live
2. Using endpoint: /health/ready
3. Using endpoint: /api/resource

Cleanup:

1. Runs `odo delete` to delete the resources created to run the application.
2. Runs `odo project delete` to delete the created project.
3. Cleans up created directories.


### Outer-loop test execution

Setup:

1. Clones devfile-stack-intro.
2. Builds a docker image using the outer-loop Dockerfile provided by the stack.
3. Pushes the built image to the local registry.
3. Populates the OpenLibertyApplication template provided by the stack.
4. Runs `odo project create` to create a project/namespace for the application to run in the cluster.
5. Runs `kubectl apply -f` on the customized OpenLibertyApplication template provided by the stack.


Validation:

1. Using endpoint: /health/live
2. Using endpoint: /health/ready
3. Using endpoint: /api/resource

Cleanup:

1. Runs `kubectl delete -f` on the customized OpenLibertyApplication template provided by the stack.
2. Runs `odo project delete` to delete the created project.
3. Cleans up created directories.