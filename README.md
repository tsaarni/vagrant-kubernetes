
# Minimal installation of Kubernetes in Vagrant box

This repository contains minimal Vagrant script to install and run
single-node Kubernetes "cluster" locally e.g. on a Windows laptop on a
virtual machine.


## Prerequisites

Download [Vagrant](https://www.vagrantup.com/downloads.html),
[VirtualBox](https://www.virtualbox.org/wiki/Downloads).

Optionally you may download also
[kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/),
[docker](https://www.docker.com/community-edition#/download) and
[helm](https://github.com/kubernetes/helm/releases) for your
host OS. These tools are also installed to the VM.


## Starting Kubernetes Vagrant box

Run following to start the VM:

    vagrant up

The command will automatically download Ubuntu 16.04 image, launch it,
and then install Kubernetes.

You can either connect to the VM to use tools such as `kubectl`, `helm` and
`docker`:

    vagrant ssh


or alternatively you can use the tools from host OS by setting following environment
variables (Linux and MacOS):

    export KUBECONFIG=$PWD/admin.conf
    export DOCKER_HOST=tcp://localhost:2375


To test that you can launch a pod running:

    kubectl run --rm -it --image alpine myalpinepod ash


You should get ash shell prompt running in a container.

To remove the VM run following on host OS:

    vagrant destroy


## Additional features

Vagrantfile executes [install-additions.sh](install-additions.sh) which
installs following optional components:

* persistent volume support
* helm

[external-exposure.sh](provisioning/external-exposure.sh) provides support for:

* allocate external IP for Services of type LoadBalancer using MetalLB
* publish .local host name for external IPs with mDNS using [external-dns and Avahi](https://github.com/tsaarni/external-dns-hosts-provider-for-mdns)

Note that the VM is configured with minimal amount of RAM so you need
to increase the allocated memory in `Vagrantfile` if running anything
non-trivial.


## Alternative container runtimes

There are two alternative container runtimes that can be chosen by
editing [Vagrantfile](Vagrantfile).  The default is Docker.

* [install-kubernetes-and-docker.sh](provisioning/install-kubernetes-and-docker.sh)
* [install-kubernetes-and-containerd.sh](provisioning/install-kubernetes-and-containerd.sh)
