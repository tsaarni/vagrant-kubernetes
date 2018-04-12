#!/bin/sh -ex

# configure repos
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
echo deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable > /etc/apt/sources.list.d/docker.list

curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
echo "deb http://apt.kubernetes.io/ kubernetes-$(lsb_release -cs) main" > /etc/apt/sources.list.d/kubernetes.list

apt update

# install docker
docker_version=$(apt-cache madison docker-ce | grep 17.03 | head -1 | awk '{print $3}')
apt install -y docker-ce=$docker_version

# install kubernetes
apt install -y kubeadm kubelet kubernetes-cni

# intialize kubernetes master
kubeadm init --apiserver-cert-extra-sans 127.0.0.1

# install CNI networking plugin
kubectl --kubeconfig=/etc/kubernetes/admin.conf apply -f https://docs.projectcalico.org/v3.0/getting-started/kubernetes/installation/hosted/kubeadm/1.7/calico.yaml

# allow scheduling of pods on master node
kubectl --kubeconfig=/etc/kubernetes/admin.conf taint nodes --all node-role.kubernetes.io/master-

# make kubernetes admin.conf available for host machine
cp /etc/kubernetes/admin.conf /vagrant

# replace internal kubernetes api server address with localhost, so it can be accessed via virtualbox port forward
sed -i 's!server: .*!server: https://127.0.0.1:6443!g' /vagrant/admin.conf
