
# Minimal installation of Kubernetes in Vagrant box

This repository contains minimal Vagrant script to install and run
single-node Kubernetes "cluster" locally e.g. on a Windows laptop.


## Prerequisites

Download [Vagrant](https://www.vagrantup.com/downloads.html),
[VirtualBox](https://www.virtualbox.org/wiki/Downloads) and
[kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/).


## Running

Run following to start the Vagrant box:

    vagrant up

The command will automatically download Ubuntu 16.04 image, launch it,
and then install Kubernetes.

When the initial installation step is completed, poll the status of the
cluster until status field is "Ready":

    kubectl --kubeconfig=admin.conf get nodes


The installation can take couple of minutes to finalize.  While the
installation is still ongoing the master node status is "NotReady".

Finally, test that you can launch a pod by running:

    kubectl --kubeconfig=admin.conf run --rm -it --image alpine myalpinepod ash


You should get ash shell prompt running in a container.
