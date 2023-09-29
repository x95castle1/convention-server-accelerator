# Getting Started

## Install the Accelerator

To install this accelerator you can run the following command on a TAP View Cluster. Change the git-repository to point to the location of where your accelerator is located. This will make it available in TAP Gui to use to generate a convention server.

```shell
tanzu acc create convention-server-template --git-repository <location of your accelerator> --interval 60s
```

You can use the Makefile to also run this command:

```shell
make applyacc
```

