#!/bin/bash -ex

export KUBECONFIG=/etc/kubernetes/admin.conf

# install storage provisioner
#  - https://github.com/rancher/local-path-provisioner
mkdir -p --mode=750 /opt/local-path-provisioner
kubectl apply -f https://raw.githubusercontent.com/rancher/local-path-provisioner/v0.0.17/deploy/local-path-storage.yaml
kubectl patch storageclass local-path -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'


# install helm
#  - https://github.com/helm/helm/releases
curl -L -s https://get.helm.sh/helm-v3.3.4-linux-amd64.tar.gz -o helm.tar.gz
tar zxf helm.tar.gz
cp -a linux-amd64/helm /usr/local/bin/helm

# add bash completions for vagrant users
echo "source <(helm completion bash)" >> ~vagrant/.bashrc
