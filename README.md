<!-- PROJECT LOGO -->

<p align="center">
  <a href="https://openliberty.io/">
    <img src="https://openliberty.io/img/spaceship.svg" alt="Logo">
  </a>
</p>
<p align="center">
  <a href="https://openliberty.io/">
    <img src="https://github.com/OpenLiberty/open-liberty/blob/master/logos/logo_horizontal_light_navy.png" alt="title" width="400">
  </a>
</p>
<br />


[![License](https://img.shields.io/badge/License-ASL%202.0-green.svg)](https://opensource.org/licenses/Apache-2.0)

# Summary

A devfile-based application stack for Open Liberty

# Open Liberty Application Stack

The Open Liberty application stack provides a consistent way of developing microservices based upon the [Jakarta EE](https://jakarta.ee/) and [Eclipse MicroProfile](https://microprofile.io) specifications. This stack lets you use [Maven](https://maven.apache.org) to develop applications for [Open Liberty](https://openliberty.io) runtime, that is running on OpenJDK with container-optimizations in OpenJ9.

This stack is based on OpenJDK with container-optimizations in OpenJ9 and Open Liberty. It provides live reloading during development by utilizing the ["dev mode"](https://openliberty.io/blog/2019/10/22/liberty-dev-mode.html) capability in the liberty-maven-plugin.  

**Note:** Maven is provided by the stack, allowing you to build, test, and debug your Java application without installing Maven locally.

## Getting Started

> It's recommended to use the latest version of OpenShift Do (odo). You can install odo using [these instructions](https://odo.dev/docs/installing-odo/)

1. Perform an `oc login` to your cluster.

1. Create a new odo project

    ```shell
    odo project create my-project
    ```

    This will create a new namespace in your cluster called `my-project`

1. Initialize the local folder with the Open Liberty stack

    ```shell
    mkdir my-project
    cd my-project
    odo create java-openliberty --starter
    ```

    This will download the default starter app

1. Push your app to your cluster

    ```shell
    odo push
    ```

1. Retrieve the URL for your app

    ```shell
    odo url list
    ```

    This URL will show the starter app's welcome page by default.

1. Watch for changes in your local project

    ```shell
    odo watch
    ```

You can now begin developing your app! Changes will be detected and pushed automatically.

For more details on the starter, checkout https://github.com/OpenLiberty/application-stack/wiki/Using-the-Default-Starter

## Sample 

For a simple, sample application see:  https://github.com/OpenLiberty/application-stack-intro

## User Doc

Checkout the application-stack [wiki](https://github.com/OpenLiberty/application-stack/wiki) for details on using the Open Liberty stack.

## Contributing

Our [CONTRIBUTING](https://github.com/OpenLiberty/application-stack/blob/master/CONTRIBUTING.md) document contains details for submitting pull requests.

## License

Usage is provided under the [Apache 2.0 license](https://opensource.org/licenses/Apache-2.0).  See LICENSE for the full details.
