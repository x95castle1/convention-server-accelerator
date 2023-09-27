# ARTIFACT_ID_PLACEHOLDER


## Component Overview

A sample convention server....add a description here

### server.go

This creates a basic http server to handle webhook calls from the Convention controller. It calls the handler to execute your conventions. 

This component shouldn't need changes (unless you have different logging needs, etc.)

### convention.go 

This contains the logic for your conventions. Each convention is part of variable array that overrides the functions in the convention interface from the framework package. 

## Convention Architecture

[Cartographer Convention Documentation](https://docs.vmware.com/en/VMware-Tanzu-Application-Platform/1.6/tap/cartographer-conventions-about.html)

## Pre-Requisites

* [Golang 1.20+](https://go.dev/doc/install) - Convention Server is written in Golang.
```shell
brew install go
```
* [Pack CLI](https://buildpacks.io/docs/tools/pack/) - Used to build image using Cloud Native Buildpacks.
```shell
brew install buildpacks/tap/pack
```
* [Set the default builder](https://buildpacks.io/docs/tools/pack/cli/pack_config_default-builder/)
```shell
pack config default-builder paketobuildpacks/builder-jammy-tiny
```
* [Tanzu CLI](https://docs.vmware.com/en/VMware-Tanzu-Application-Platform/1.6/tap/install-tanzu-cli.html) - Used to install repository and packages on TAP cluster.
```
brew install vmware-tanzu/tanzu/tanzu-cli
tanzu plugin install --group vmware-tap/default:v1.6.3
```

* [Kctrl CLI](https://github.com/carvel-dev/carvel) - Needed for bundling and releasing as a Carvel Package
```shell
brew install vmware-tanzu/carvel
```

* [jq](https://jqlang.github.io/jq/) - Utilized in build automation in the `Makefile`
```shell
brew install jq
```
* [gsed](https://formulae.brew.sh/formula/gnu-sed) - Utilized in build automation in the `Makefile`
```shell
brew install gsed
```

Logged into Staging Package Registry - Location to stage packaging.
```shell
docker login STAGING_REGISTRY_HOST
```

Logged into Production Package Registry - Location to release packaging.
```shell
docker login RELEASE_REGISTRY_HOST
```

Logged into Convention Image Registry - Location of built image.
```shell
docker login CONVENTION_IMAGE_REGISTRY_HOST
```

Convention Source code is in a git repo - Needed for build automation in `Makefile`
```shell
git init
git add .
git commit -m "Initial Commit"
git branch -M main
> git remote add origin https://github.com/<my-repo>.git
git push -u origin main
```

Initial TAG is set - Needed for build autmation in `Makefile`
```shell
git tag 0.0.0
```

## Available Options

| Annotation | Description | 
| --- | --- |
| `CONVENTION_PREFIX_PLACEHOLDER/readinessProbe` | define a readiness probe |

## Example Annotations for a Workload

```yaml
spec:
  params:
  - name: annotations
    value:
      CONVENTION_PREFIX_PLACEHOLDER/readinessProbe: '{"httpGet":{"path":"/healthz","port":8080},"initialDelaySeconds":5,"periodSeconds":5}'

```

It can sometimes be tricky to convert yaml to json to pass through the annotation. You can use these utilities:

* [Convert Yaml to JSON](https://onlineyamltools.com/convert-yaml-to-json)
* [Compact JSON](https://www.text-utils.com/json-formatter/)

## Example Workload

Below is an example workload that configured two probes.

```yaml
apiVersion: carto.run/v1alpha1
kind: Workload
metadata:
  labels:
    app.kubernetes.io/part-of: app-golang-kpack
    apps.tanzu.vmware.com/workload-type: web
  name: convention-workload
  namespace: demo
spec:
  params:
  - name: annotations
    value:
      CONVENTION_PREFIX_PLACEHOLDER/readinessProbe: '{"httpGet":{"path":"/healthz","port":8080},"initialDelaySeconds":5,"periodSeconds":5}'
  source:
    git:
      ref:
        branch: main
      url: https://github.com/carto-run/app-golang-kpack   
```

You can find more examples in the [workload-examples folder](/workload-examples/) in the repository.

## Example Generated PodSpec with Probes

```yaml
...
spec:
  containers:
  - image: gcr.io/ship-interfaces-dev/supply-chain/app-golang-kpack-dev@sha256:3830de13d0a844420caa3d0a8d77ee1ca5b05897a273465c682032522fc331b5
    name: workload
    readinessProbe:
      httpGet:
        path: /healthz
        port: 8080
      initialDelaySeconds: 5
      periodSeconds: 5
    resources: {}
...
```

## Install on a Cluster

The ARTIFACT_ID_PLACEHOLDER has been conveniently packaged up via Carvel and can be installed on a TAP cluster via the Tanzu CLI.

### Install Carvel Package Repository

Run the following command to output a list of available tags.

  ```shell
  imgpkg tag list -i RELEASE_PACKAGE_IMAGE_REGISTRY_PLACEHOLDER_URL | sort -V
  ```

  For example:

  ```shell
  imgpkg tag list -i RELEASE_PACKAGE_IMAGE_REGISTRY_PLACEHOLDER_URL | sort -V

  0.1.0
  0.2.0
  0.3.0
  0.4.0
  ```

Use the latest version returned by the command above.

1. Add ARTIFACT_ID_PLACEHOLDER package repository to the cluster by running:

    ```shell
    tanzu package repository add ARTIFACT_ID_PLACEHOLDER-repository \
      --url RELEASE_PACKAGE_IMAGE_REGISTRY_PLACEHOLDER_URL:$VERSION \
      --namespace tap-install
    ```

2. Get the status of ARTIFACT_ID_PLACEHOLDER package repository, and ensure that the status updates to `Reconcile succeeded` by running:

    ```shell
    tanzu package repository get ARTIFACT_ID_PLACEHOLDER-repository --namespace tap-install
    ```

    For example:

    ```console
    tanzu package repository get ARTIFACT_ID_PLACEHOLDER-repository --namespace tap-install

    NAMESPACE:               tap-install
    NAME:                    ARTIFACT_ID_PLACEHOLDER-repository
    SOURCE:                  (imgpkg) RELEASE_PACKAGE_IMAGE_REGISTRY_PLACEHOLDER_URL:0.4.0
    STATUS:                  Reconcile succeeded
    CONDITIONS:              - type: ReconcileSucceeded
      status: "True"
      reason: ""
      message: ""
    USEFUL-ERROR-MESSAGE:
    ```

3. List the available packages by running:

    ```shell
    tanzu package available list --namespace tap-install
    ```

    For example:

    ```shell
    $ tanzu package available list --namespace tap-install
    / Retrieving available packages...
      NAME                                                              DISPLAY-NAME                       SHORT-DESCRIPTION
      PACKAGE_NAME_PLACEHOLDER      ARTIFACT_ID_PLACEHOLDER    PACKAGE_SHORT_DESCRIPTION_PLACEHOLDER
    ```

### Prepare Convention Configuration

You can define the `--values-file` flag to customize the default configuration. You
must define the following fields in the `values.yaml` file for the Convention Server
configuration. You can add fields as needed to activate or deactivate behaviors.
You can append the values to the `values.yaml` file. Create a `values.yaml` file
by using the following configuration:

  ```yaml
  ---
  annotationPrefix: ANNOTATION-PREFIX
  ```

  Where:

  - `ANNOTATION-PREFIX` is the prefix you want to use on your annotation used in the workload. Defaults to `example.com`.

### Install ARTIFACT_ID_PLACEHOLDER

Define the `--values-file` flag to customize the default configuration. See `./examples/package/values.yaml`

The `values.yaml` file you created earlier is referenced with the `--values-file` flag when running your Tanzu install command:

```shell
tanzu package install REFERENCE-NAME \
  --package PACKAGE-NAME \
  --version VERSION \
  --namespace tap-install \
  --values-file PATH-TO-VALUES-YAML
```

Where:

- REFERENCE-NAME is the name referenced by the installed package. For example, ARTIFACT_ID_PLACEHOLDER.
- PACKAGE-NAME is the name of the convention package you retrieved earlier. For example, PACKAGE_NAME_PLACEHOLDER.
- VERSION is your package version number. For example, 0.4.0
- PATH-TO-VALUES-YAML is the path that points to the values.yaml file created earlier.

For example:

```console
tanzu package install ARTIFACT_ID_PLACEHOLDER  \
--package PACKAGE_NAME_PLACEHOLDER \
--version 0.4.0 \
--values-file ./examples/package/values.yaml
--namespace tap-install
```

## Setup Development Environment

This project has `Makefile` to `make` life easier for you. 

### Variables

* `CONVENTION_IMAGE_LOCATION` - The location to push the image built by the Makefile. Default: `CONVENTION_IMAGE_REGISTRY_PLACEHOLDER_URL`
* `DEV_IMAGE_LOCATION` - The image registry to push the carvel bundle. This is a staging repo. Default: `STAGING_PACKAGE_IMAGE_REGISTRY_PLACEHOLDER_URL`
* `PROMOTION_IMAGE_LOCATION` - The image registry to imgpkg copy to make the carvel bundle publically available. Default: `RELEASE_PACKAGE_IMAGE_REGISTRY_PLACEHOLDER_URL`
* `INSTALL_NAMESPACE` - Namespace where the bundle is installed. Used to restart the pods. Default: `ARTIFACT_ID_PLACEHOLDER`
* `CONVENTION_NAME` - Name of the image repository project. Appended to CONVENTION_IMAGE_LOCATION variable. Default:  `ARTIFACT_ID_PLACEHOLDER`

```shell
export CONVENTION_IMAGE_LOCATION=CONVENTION_IMAGE_REGISTRY_PLACEHOLDER_URL
```

### make build 

Builds and tests the source code. Testing includes running fmt and and vet commands.

```shell
make build
```

### make image

Uses `pack cli` to build image and publish to the `CONVENTION_IMAGE_LOCATION` location. 

```shell
export CONVENTION_IMAGE_LOCATION=CONVENTION_IMAGE_REGISTRY_PLACEHOLDER_URL

make image
```

### make install

This will deploy `install-server/server-it.yaml` onto the current cluster. This is useful for quick testing. This will create a new namespace `ARTIFACT_ID_PLACEHOLDER` and configure cartographer conventions to use this convention provider along with self signed certs.

```shell
make install
```

### make uninstall

This will uninstall `install-server/server-it.yaml` from the current cluster. This is use for tearing down the installation installed for quick testing.

```shell
make uninstall
```

### make restart

This will delete the convention server pod. This is useful during testing if making changes and are using the latest tag on your images to allow the pod to pull in the latest version. 

```shell
make restart
```

### make applyw

This will apply all the workloads in the `examples/workload` to the cluster. Useful to testing conventions.

```shell
make applyw
```

### make unapplyw

This will delete all the workloads in the `examples/workload` to the cluster. Useful to testing conventions.

```shell
make applyw
```

### make applyp

This will add the package repository and package for ARTIFACT_ID_PLACEHOLDER. This is useful when needing to install convention server via a package. 

```shell
make applyp
```

### make unapplyp

This will delete the package repository and package for ARTIFACT_ID_PLACEHOLDER. This is useful when tear down the convention server installed via a package. 

```shell
make unapplyp
```

### make package

This runs the `kctrl package` commands to create a package and repo to release the convention server and push the bundle to repo. Useful when you want to package the convention server into a carvel package.

```shell
make package
```

### make release

Only run this command when you are ready to package and release a version of the convention server. This command will do the following:

* stash - Git Stash any non-commited changes.
* updateGoDeps - Updates to the latest git dependencies. 
* commitGoDeps - Commits any changes from the dependencies.
* build - Builds source code
* tag - Creates a tag in the git repo that is incremented off the last version.
* updateLatestTagVariable - Updates any variables with the latest tag in the Makefile
* image - Build the image via BuildPack and pushes the image to a repo.
* updateTemplateImage - Updates the image in the carvel and examples folder to use the new sha.
* package - Creates a package and package repo bundle.
* commitReleasedFiles - Commits the new package files to git.
* promote - Performs an `imgpkg copy` on the package bundle to a production repository to make it available
* stashPop - Returns any previously stashed git changes.

```shell
make release
```

## Carvel Packaging

The multi purpose convention server has been packaged using Carvel for easy installation. There are 2 main components that make up the packaging that can be used by the `kctrl` cli: The package and the packagerepository. 

More info can be found on [Authoring packages with kctrl](https://carvel.dev/kapp-controller/docs/v0.47.x/kctrl-package-authoring/)

### Creating the Package

The first step is to create the package for the Convention Server.

#### carvel/config folder

This folder contains the actual kubernetes manifests that will be packaged and installed on the cluster via the Carvel pacakge. The `data-values-schema.yaml` contains values that can be provided to the packaging installation to change behavior. For example, the namespace property allows you to change what namespace the resources are installed.

#### carvel/package-build.yml 

This file controls how the package is built. The ```includePaths:``` property tells `kctrl` where to pull the manifests to be bundled. For example: ```config``` will pull the manifests from the local config folder.

#### carvel/package-resources.yml

This file sets the metadata about the package along with the packageinstall. This contains the naming of the package and the description.

#### kctrl package release

After the files and folders have been setup properly you can use the `kctrl package release` command to generate the imgpkg bundle.

```shell
kctrl package release --chdir ./carvel -v $(LATEST_TAG) --tag $(LATEST_TAG) --repo-output ./packagerepository -y
```

This will generate several files including the necessary files for the package repository.

### Creating the Package Repository

The next step is to release the Package Repository. You can generate the package repository by running the following kctrl command:

```shell
kctrl package repo release --chdir carvel/packagerepository -v $(LATEST_TAG) -y
```


#### pkgrepo-build.yml 

Stores some metadata generated using the user inputs during the first release. This can be comitted to a git repository, if users want to do releases in their CI pipelines.

This file can be edited for your own packaging needs.

#### package-repository.yml 

PackageRepository resource that can be applied to the cluster directly. This file is generated by the kctrl cli.
