## Test Overview

The devfile-stack repo is tested using Github Actions. The main workflow is defined in `stack-regression-tests.yml` and performs the following steps:

### Install Minikube 

This is done via the `manusa/actions-setup-minikube` actions plugin

### Install ODO

The latest version is installed

### Build stack 

This runs the `build.sh` script to generate all stack content in the `generated/` dir based on the PRs branch.

### Build stack image

The stack image is built into the local docker registry using the name:version specified in the devfile

### Run inner loop tests

Basic setup:

Clone devfile-stack-intro, create, push.

Tests against following endpoints:

1. /health/live
1. /health/ready
1. /api/resource

### Run outer loop tests

Basic setup:

Clone devfile-stack-intro, build docker image, install OL operator, deploy.

Tests against following endpoints:

1. /health/live
1. /health/ready
1. /api/resource


## Additional features

1. Tests are triggered on each PR or update to a PR
1. All local docker images are available for use by the Minikube cluster since Minikube is installed/started with `driver=none` (bare metal)


## Known issues

1. Intermittent Ingress connection refused errors:

```
Applying URL changes
 ✗  Failed To Update Config To Component Deployed.
Error: unable to create ingress: error creating ingress: Internal error occurred: failed calling webhook "validate.nginx.ingress.kubernetes.io": Post https://ingress-nginx-controller-admission.kube-system.svc:443/extensions/v1beta1/ingresses?timeout=30s: dial tcp 10.96.251.20:443: connect: connection refused
```

If this occurs, the tests will need to be rerun. 

## Future Tests

1. Validate version changes in build.sh to make sure proper incrementation (i.e. you changed the outerloop Dockerfile but didnt increment the outerloop version)
