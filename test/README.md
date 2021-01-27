## Test Overview

The application-stack repo is tested using Github Actions. The main workflow is defined in `stack-regression-tests.yml` and performs the following steps:

### Install Minikube 

This is done via the `manusa/actions-setup-minikube` actions plugin

### Install ODO

The latest version is installed

### Build stack 

This runs the `build.sh` script to generate all stack content in the `generated/` dir based on the PRs branch.

### Build stack image

The stack image is built if changes are detected to `stackimage/` or `templates/stackimage`

### Run inner loop tests

Basic setup:

Clone application-stack-intro, create, push.

Tests against following endpoints:

1. /health/live
1. /health/ready
1. /api/resource

### Run outer loop tests

Outerloop tests are only done if changes are detected to `templates/outer-loop` or any stack image content (`stackimage/` or `templates/stackimage`)
Basic setup:

Clone application-stack-intro, build docker image, install OL operator, deploy.

Tests against following endpoints:

1. /health/live
1. /health/ready
1. /api/resource


## Additional features

1. Tests are triggered on each PR or update to a PR
1. All local docker images are available for use by the Minikube cluster since Minikube is installed/started with `driver=none` (bare metal)
1. Changes to specific files (which gates what steps are run) is controlled via the `softprops/diffset@v1` actions plugin


## Known issues

1. Intermittent Ingress connection refused errors:

```
Applying URL changes
 ✗  Failed To Update Config To Component Deployed.
Error: unable to create ingress: error creating ingress: Internal error occurred: failed calling webhook "validate.nginx.ingress.kubernetes.io": Post https://ingress-nginx-controller-admission.kube-system.svc:443/extensions/v1beta1/ingresses?timeout=30s: dial tcp 10.96.251.20:443: connect: connection refused
```

If this occurs, the tests will need to be rerun. 

1. Warning message due to known "bug" in `softprops/diffset@v1` plugin (https://github.com/softprops/diffset/issues/5):

```
Unexpected input(s) 'stackimage_files', valid inputs are ['base']
```

## Future Tests

1. Validate version changes in build.sh to make sure proper incrementation (i.e. you changed the outerloop Dockerfile but didnt increment the outerloop version)
