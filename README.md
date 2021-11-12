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
[![Gitter](https://badges.gitter.im/OpenLiberty/developer-experience.svg)](https://gitter.im/OpenLiberty/developer-experience)

# Summary

A devfile-based application stack for Open Liberty

# Open Liberty Application Stack

The Open Liberty application stack provides a consistent way of developing microservices based upon the [Jakarta EE](https://jakarta.ee/) and [Eclipse MicroProfile](https://microprofile.io) specifications. This stack lets you use [Maven](https://maven.apache.org) or [Gradle](https://gradle.org/) to develop applications for [Open Liberty](https://openliberty.io) runtime, that is running on OpenJDK with container-optimizations in OpenJ9.

This stack is based on OpenJDK with container-optimizations in OpenJ9 and Open Liberty. It provides live reloading during development by utilizing the ["dev mode"](https://openliberty.io/blog/2021/02/18/dev-mode-container-liberty-maven-gradle-plugins.html) capability in the liberty-maven-plugin or liberty-gradle-plugin.  

**Note:** Maven or Gradle is provided by the stack. This allows you to build, test, and debug your Java application without installing those tools locally.

## Getting Started With the Intro Sample

> It's recommended to use the latest version of OpenShift Do (odo). You can install odo using [these instructions](https://odo.dev/docs/installing-odo/)

1. Perform an `oc login` to your cluster.

1. Clone the devfile-stack-intro repository

    ```shell
    git clone git@github.com:OpenLiberty/devfile-stack-intro.git
    cd devfile-stack-intro
    ```

1. Create your odo component

   If you want the application to be built and deployed using Maven:

    ```shell
    odo create java-openliberty my-component
    ```

   If you want the application to be built and deployed using Gradle:

    ```shell
    odo create java-openliberty-gradle my-component
    ```

1. Push the sample application to OpenShift

    ```shell
    odo push
    ```
1. Wait for tests to complete

    ```shell
    odo log -f
    ```

1. Retrieve the URL for your app deployed to OpenShift

    ```shell
    odo url list
    ```

    This URL will show the intro app's welcome page by default.  

   Click the link:  *Try your new Microservice "here"* to invoke the JAX-RS resource within (or invoke the URL at `<endpoint>/api/resource` to do so directly).

1. If you wish to continue and make changes to your local project, you can start odo watch

    ```shell
    odo watch
    ```

You can now begin developing your app (in another shell or editor)! Changes will be detected and pushed automatically.

## Further Reading

### Creating a new stack project

To use the starter to create new projects, see: https://github.com/OpenLiberty/devfile-stack/wiki/Using-the-Default-Starter

### Creating a java-openliberty devfile component from an existing project

See:  https://github.com/OpenLiberty/devfile-stack/wiki/Migrating-Existing-Maven-Apps-To-Stack

### User Doc

Checkout the devfile-stack [wiki](https://github.com/OpenLiberty/devfile-stack/wiki) for details on using the Open Liberty stack.

### odo.dev

 follow the guides from the [odo.dev](https://odo.dev) site.


## Contributing

Our [CONTRIBUTING](https://github.com/OpenLiberty/devfile-stack/blob/main/CONTRIBUTING.md) document contains details for submitting pull requests.

## License

Usage is provided under the [Apache 2.0 license](https://opensource.org/licenses/Apache-2.0).  See LICENSE for the full details.
