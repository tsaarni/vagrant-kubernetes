#!/bin/bash -ex
#
# Install kubernetes and docker
#
# References
# * https://kubernetes.io/docs/setup/independent/install-kubeadm/
# * https://kubernetes.io/docs/setup/independent/create-cluster-kubeadm/
# * https://kubernetes.io/docs/setup/production-environment/container-runtimes/
#

# configure repos
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
echo deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable > /etc/apt/sources.list.d/docker.list

curl -fsSl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
echo "deb http://apt.kubernetes.io/ kubernetes-$(lsb_release -cs) main" > /etc/apt/sources.list.d/kubernetes.list

apt-get update

# install dependencies
apt-get install -y conntrack

# disable swap
swapoff -a
sed -i '/ swap / s/^/#/' /etc/fstab

# enable docker remote access outside the VM
mkdir -p /etc/systemd/system/docker.service.d
cat >/etc/systemd/system/docker.service.d/override.conf <<EOF
[Service]
ExecStart=
ExecStart=/usr/bin/dockerd -H fd:// -H tcp://0.0.0.0:2375
EOF

# install docker
apt-get update && apt-get install -y \
  containerd.io=1.2.13-1 \
  docker-ce=5:19.03.8~3-0~ubuntu-$(lsb_release -cs) \
  docker-ce-cli=5:19.03.8~3-0~ubuntu-$(lsb_release -cs)

cat > /etc/docker/daemon.json <<EOF
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2"
}
EOF

mkdir -p /etc/systemd/system/docker.service.d

# Restart docker.
systemctl daemon-reload
systemctl restart docker

# install kubernetes
kubernetes_version=1.18
kubernetes_deb_version=$(apt-cache madison kubelet | grep $kubernetes_version | head -1 | awk '{print $3}')
apt-get install -y kubeadm=$kubernetes_deb_version kubelet=$kubernetes_deb_version kubectl=$kubernetes_deb_version

# intialize kubernetes master
#   Note: use command "kubeadm config print-default" to print all config file parameters
kubeadm init --config /vagrant/configs/kubeadm-config.yaml

# install CNI networking plugin
kubectl --kubeconfig=/etc/kubernetes/admin.conf apply -f https://docs.projectcalico.org/manifests/calico.yaml

# since we only have one node, allow scheduling of pods on master node
kubectl --kubeconfig=/etc/kubernetes/admin.conf taint nodes --all node-role.kubernetes.io/master-

# make kubernetes admin.conf available for vagrant-user
mkdir ~vagrant/.kube
cp /etc/kubernetes/admin.conf ~vagrant/.kube/config
chown -R vagrant:vagrant ~vagrant/.kube

# add bash completions for vagrant user
echo "source <(kubectl completion bash)" >> ~vagrant/.bashrc

# add vagrant to docker group to allow running docker without sudo
usermod -a -G docker vagrant

# wait for the node to come up
set +x  # disable bash trace
while true; do
    status=$(kubectl --kubeconfig=/etc/kubernetes/admin.conf get nodes -o jsonpath='{.items[*].status.conditions[?($.status == "True")].status}')
    if [[ $status == "True" ]]; then
        break
    fi
    echo "Running 'kubectl get nodes' and waiting for the nodes to come up..."
    sleep 3
done
set -x
